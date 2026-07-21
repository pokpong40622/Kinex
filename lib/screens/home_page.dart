import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../theme/kui.dart';
import '../state/home_intro_providers.dart';
import '../data/assessment_repository.dart';
import '../data/emg_repository.dart';
import '../models/fall_risk.dart';
import '../widgets/fall_risk_cards.dart';
import '../widgets/device_connect_panel.dart';
import '../ble/ble_service.dart';
import '../theme/responsive.dart';
import '../data/customize_catalog.dart';
import '../state/shop_providers.dart';
import 'info_page.dart';
import 'shop_page.dart';
import 'onboarding/onboarding_flow.dart';
import '../state/onboarding_prefs.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _tab = 0;
  int _homePage = 0;
  final PageController _homeCtrl = PageController();

  // Coach-mark tour targets (measured by _CoachMarkOverlay): the ฝึกซ้อม + ข้อมูล
  // nav tabs and the ประเมิน card. Runs once after onboarding on first entry.
  final GlobalKey _gamesNavKey = GlobalKey();
  final GlobalKey _infoNavKey = GlobalKey();
  final GlobalKey _assessCardKey = GlobalKey();
  bool _coachActive = false;

  @override
  void dispose() {
    _homeCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Every app entry: run the onboarding popup FLOW (software intro slides →
    // Bluetooth connect → EMG installation) as one themed dialog, then spotlight
    // the assessment card. Flags are in-memory so this runs once per launch.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      // First entry this launch? (either landing flag still pending). Clear both,
      // then run the flow once.
      final firstEntry = ref.read(deviceConnectPendingProvider) ||
          ref.read(homeGuidePendingProvider);
      ref.read(deviceConnectPendingProvider.notifier).state = false;
      ref.read(homeGuidePendingProvider.notifier).state = false;
      if (!firstEntry) return;

      // Intro slides are included only when the settings toggle is ON; the
      // Bluetooth + installation stages always show.
      final result = await showOnboardingFlow(
        context,
        introEnabled: ref.read(introEnabledProvider),
      );
      if (!mounted) return;

      if (result == OnboardingResult.installRequested) {
        // Open the real EMG install + MVC-capture guide.
        final guideResult = await context.push('/hardware-guide');
        if (!mounted) return;
        // result == true only when the guide was fully finished; anything else
        // (skip / back-dismiss) means the EMG pads weren't installed this run.
        ref.read(emgInstallSkippedProvider.notifier).state = guideResult != true;
      } else {
        // Skipped the flow / installation → EMG pads not installed this run.
        ref.read(emgInstallSkippedProvider.notifier).state = true;
      }
      // Guided tour of the real UI: dim + spotlight the games tab, the info tab,
      // then the assessment card (replaces the old single-card spotlight).
      if (mounted) setState(() => _coachActive = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _tab,
        children: [
          // Home tab: swipeable between original Home and Character dashboard.
          PageView(
            controller: _homeCtrl,
            onPageChanged: (i) => setState(() => _homePage = i),
            children: [
              _HomeTab(assessKey: _assessCardKey),
              CharacterHomeTab(onSeeMore: () => setState(() => _tab = 3)),
            ],
          ),
          const _QuestTab(),
          _PracticeTab(onStartGame: () => context.go('/mega-dance')),
          const _InfoTab(),
          const ShopTab(),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_tab == 0)
            _HomePageDots(
              index: _homePage,
              onTap: (i) => _homeCtrl.animateToPage(
                i,
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOut,
              ),
            ),
          _KinexNavBar(
            selected: _tab,
            onTap: (i) => setState(() => _tab = i),
            itemKeys: [null, null, _gamesNavKey, _infoNavKey, null],
          ),
        ],
      ),
    );

    return Stack(
      children: [
        scaffold,
        if (_coachActive)
          _CoachMarkOverlay(
            steps: [
              (_gamesNavKey, 'เล่นเกมฝึกได้ที่นี่', 'แตะแท็บ “ฝึกซ้อม” เพื่อเลือกเกมฝึกกล้ามเนื้อ'),
              (_infoNavKey, 'ดูความก้าวหน้าที่นี่', 'แท็บ “ข้อมูล” รวมสถิติ ประวัติ และพัฒนาการของคุณ'),
              (_assessCardKey, 'เริ่มด้วยการประเมิน', 'แตะการ์ดนี้เพื่อวัดความแข็งแรงและการทรงตัวก่อนเริ่มฝึก'),
            ],
            onFinish: () => setState(() => _coachActive = false),
          ),
      ],
    );
  }
}

// ── Home page indicator dots ─────────────────────────────────────────────────

class _HomePageDots extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const _HomePageDots({required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(2, (i) {
          final active = i == index;
          return GestureDetector(
            onTap: () => onTap(i),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: active ? 22 : 8,
                height: 8,
                decoration: BoxDecoration(
                  gradient: active ? KColors.blueGradient : null,
                  color: active ? null : Colors.black26,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Bottom Navigation ───────────────────────────────────────────────────────

class _KinexNavBar extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onTap;
  // Optional per-item keys so the coach-mark tour can locate specific tabs.
  final List<GlobalKey?>? itemKeys;

  const _KinexNavBar(
      {required this.selected, required this.onTap, this.itemKeys});

  static const _labels = ['หน้าหลัก', 'ภารกิจ', 'ฝึกซ้อม', 'ข้อมูล', 'ร้านค้า'];
  static const _icons = [
    'assets/images/nav_home.png',
    'assets/images/nav_quest.png',
    'assets/images/nav_practice.png',
    'assets/images/nav_info.png',
    'assets/images/nav_shop.png',
  ];

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Container(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(w * 0.030, 10, w * 0.030, 16),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF9F9F9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0x73A7A7A7), width: 1.5),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x40000000), blurRadius: 12, offset: Offset(0, 4))
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(5, (i) {
                  final active = i == selected;
                  return GestureDetector(
                    key: itemKeys != null ? itemKeys![i] : null,
                    onTap: () => onTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Soft glow behind the active tab's icon (premium feel).
                        Container(
                          decoration: active
                              ? BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                        color: KColors.indigo.withAlpha(110),
                                        blurRadius: 16,
                                        spreadRadius: 1),
                                  ],
                                )
                              : null,
                          child: Opacity(
                            opacity: active ? 1.0 : 0.4,
                            child:
                                Image.asset(_icons[i], width: 42, height: 42),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _labels[i],
                          style: montserrat(
                            size: 12,
                            weight: FontWeight.w900,
                            color: active
                                ? KColors.navyText
                                : KColors.navyText.withAlpha(100),
                          ),
                        ),
                        const SizedBox(height: 3),
                        // Active underline pill.
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 3,
                          width: active ? 22 : 0,
                          decoration: BoxDecoration(
                            gradient: KColors.blueGradient,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── EMG REMINDER BANNER ─────────────────────────────────────────────────────

/// Thin full-width banner shown only when EMG pads are not yet calibrated.
/// Reads [mvcCalibrationProvider]; auto-hides once calibration is complete.
/// Tapping reopens the hardware-guide.
class _EmgReminderBanner extends ConsumerWidget {
  const _EmgReminderBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skipped = ref.watch(emgInstallSkippedProvider);
    final cal = ref.watch(mvcCalibrationProvider).value;
    final calibrated = cal != null && cal.isComplete;
    // Show whenever the user skipped this run, or there's no complete calibration.
    if (!skipped && calibrated) return const SizedBox.shrink();

    final w = MediaQuery.sizeOf(context).width;
    return GestureDetector(
      onTap: () async {
        final result = await context.push('/hardware-guide');
        if (result == true) {
          ref.read(emgInstallSkippedProvider.notifier).state = false;
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: w * 0.04),
        padding: EdgeInsets.symmetric(horizontal: w * 0.035, vertical: w * 0.022),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3CD),
          border: Border.all(color: const Color(0xFFFFB300), width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Color(0xFFE65100), size: 18),
            SizedBox(width: w * 0.02),
            Expanded(
              child: Text(
                'ยังไม่ได้ติดตั้งแผ่น EMG — แตะเพื่อติดตั้ง',
                style: thaiSans(
                    size: 13,
                    weight: FontWeight.w700,
                    color: const Color(0xFFE65100)),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Color(0xFFE65100), size: 13),
          ],
        ),
      ),
    );
  }
}

// ── HOME TAB ────────────────────────────────────────────────────────────────

class _HomeTab extends ConsumerStatefulWidget {
  // The parent (HomePage) owns this key so its coach-mark tour can spotlight the
  // ประเมิน card that lives inside this tab.
  final GlobalKey assessKey;
  const _HomeTab({required this.assessKey});

  @override
  ConsumerState<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<_HomeTab> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    final h = size.height;
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/images/bg_room.png', fit: BoxFit.cover),
        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(w * 0.04, h * 0.035, w * 0.04, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: const _ProfileCard()),
                    SizedBox(width: w * 0.025),
                    const _BleTopBarButton(),
                    SizedBox(width: w * 0.025),
                    const _TopBarIconButton(
                      asset: 'assets/images/icon_notif.png',
                      gradientBorder: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        stops: [0.26, 0.67],
                        colors: [Color(0xFFFFC107), Color(0xFFF44336)],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: h * 0.015),
              const _EmgReminderBanner(),
              SizedBox(height: h * 0.01),
              Padding(
                padding: EdgeInsets.fromLTRB(w * 0.04, 0, w * 0.04, h * 0.02),
                // 35% smaller: 65% width (left-aligned) keeps the card's aspect ratio so the
                // width-driven content scales down with the reduced height (see card heights).
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: 0.65,
                    child: _AssessmentCard(
                      cardKey: widget.assessKey,
                      onTap: () => context.push('/assessment'),
                    ),
                  ),
                ),
              ),
              SizedBox(height: h * 0.015),
              Padding(
                padding: EdgeInsets.fromLTRB(w * 0.04, 0, w * 0.04, h * 0.02),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: 0.65,
                    child: _LearnHomeCard(onTap: () => context.push('/learn')),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── CHARACTER HOME (second home page) ────────────────────────────────────────
// Reuses the SAME room background + top bar (profile / BLE / notif / EMG banner)
// as [_HomeTab]; the World and ประเมิน cards are replaced by ONE white rounded
// card holding the character with progress data below it. All stats derive from
// worldHistoryProvider (see state/progress_providers.dart) — no new storage.

class CharacterHomeTab extends ConsumerWidget {
  final VoidCallback? onSeeMore;
  const CharacterHomeTab({super.key, this.onSeeMore});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    final h = size.height;

    // DEMO: hardcoded placeholder stats for presentation. Swap these back to the
    // ref.watch(...Provider) values in state/progress_providers.dart to drive the
    // dashboard from real Kinex World session history.
    const dStreak = 5;
    const dMins = 48;
    const dScore = 82;
    const dImprove = 9;
    const happy = true;

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/images/bg_room.png', fit: BoxFit.cover),
        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Identical top bar to _HomeTab.
              Padding(
                padding: EdgeInsets.fromLTRB(w * 0.04, h * 0.035, w * 0.04, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: const _ProfileCard()),
                    SizedBox(width: w * 0.025),
                    const _BleTopBarButton(),
                    SizedBox(width: w * 0.025),
                    const _TopBarIconButton(
                      asset: 'assets/images/icon_notif.png',
                      gradientBorder: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        stops: [0.26, 0.67],
                        colors: [Color(0xFFFFC107), Color(0xFFF44336)],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: h * 0.015),
              const _EmgReminderBanner(),
              SizedBox(height: h * 0.01),
              // White progress card fills the remaining space (replaces the two cards).
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(w * 0.04, 0, w * 0.04, h * 0.02),
                  child: Container(
                    width: double.infinity,
                    decoration: cardDecoration(radius: 28, color: Colors.white),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                          horizontal: context.r(18), vertical: context.r(18)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Text(
                                'ความก้าวหน้าของฉัน',
                                style: thaiSans(
                                  size: context.r(18),
                                  weight: FontWeight.w800,
                                  color: KColors.navyText,
                                ),
                              ),
                              const Spacer(),
                              if (dStreak > 0) _StreakChip(streak: dStreak),
                            ],
                          ),
                          SizedBox(height: context.r(8)),
                          _CharacterHero(
                            exercisedToday: happy,
                            asset: characterById(
                                    ref.watch(activeCharacterProvider))
                                .asset,
                          ),
                          SizedBox(height: context.r(14)),
                          Row(
                            children: [
                              Expanded(
                                child: KStatTile(
                                  value: '$dStreak',
                                  label: 'วัน',
                                  valueColor: KColors.orangeDark,
                                ),
                              ),
                              SizedBox(width: context.r(8)),
                              Expanded(
                                child: KStatTile(
                                  value: '$dMins',
                                  label: 'นาที',
                                  valueColor: KColors.tealDark,
                                ),
                              ),
                              SizedBox(width: context.r(8)),
                              Expanded(
                                child: KStatTile(
                                  value: '$dScore%',
                                  label: 'คะแนน',
                                  valueColor: KColors.blue,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: context.r(16)),
                          _ImprovementBanner(improvement: dImprove),
                          SizedBox(height: context.r(14)),
                          _SeeMoreButton(onTap: onSeeMore),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Streak chip ───────────────────────────────────────────────────────────────

class _StreakChip extends StatelessWidget {
  final int streak;
  const _StreakChip({required this.streak});

  @override
  Widget build(BuildContext context) =>
      KPill('🔥 $streak วัน', color: KColors.orangeDark);
}

// ── Character hero (single image + streak-driven mood overlay) ────────────────

class _CharacterHero extends StatefulWidget {
  final bool exercisedToday;
  final String asset;
  const _CharacterHero({required this.exercisedToday, required this.asset});

  @override
  State<_CharacterHero> createState() => _CharacterHeroState();
}

class _CharacterHeroState extends State<_CharacterHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bob;
  late final Animation<double> _bobAnim;

  @override
  void initState() {
    super.initState();
    _bob = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _bobAnim = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _bob, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imgH = context.r(180);
    final awake = widget.exercisedToday;
    return SizedBox(
      height: imgH + context.r(20),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _bobAnim,
            builder: (ctx, child) => Transform.translate(
              offset: awake ? Offset(0, _bobAnim.value) : Offset.zero,
              child: child,
            ),
            // Character stays in full colour in both moods; the badge conveys
            // happy vs. resting (only the gentle bob differs).
            child: Image.asset(
              widget.asset,
              height: imgH,
              fit: BoxFit.contain,
            ),
          ),
          // Mood status badge — top-right, close to the character's head.
          Align(
            alignment: const Alignment(0.52, -0.82),
            child: Container(
              padding: EdgeInsets.all(context.r(6)),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: awake ? KColors.teal : Colors.grey.shade400,
                  width: context.r(2.5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(28),
                    blurRadius: context.r(8),
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                awake ? '😊' : '😴',
                style: TextStyle(fontSize: context.r(24)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Improvement banner ────────────────────────────────────────────────────────

class _ImprovementBanner extends StatelessWidget {
  final int? improvement;
  const _ImprovementBanner({this.improvement});

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final Color accent;
    final String text;

    if (improvement == null || improvement == 0) {
      icon = Icons.trending_flat_rounded;
      accent = Colors.grey.shade600;
      text = improvement == 0
          ? 'ทรงตัว สัปดาห์นี้'
          : 'ฝึกต่อเนื่องเพื่อดูพัฒนาการ';
    } else if (improvement! > 0) {
      icon = Icons.trending_up_rounded;
      accent = KColors.tealDark;
      text = 'ดีขึ้น $improvement% สัปดาห์นี้';
    } else {
      icon = Icons.trending_down_rounded;
      accent = KColors.orangeDark;
      text = 'ลดลง ${improvement!.abs()}% สัปดาห์นี้';
    }

    return KPill(text, color: accent, icon: icon);
  }
}

// ── CTA card ──────────────────────────────────────────────────────────────────

// "See more" button on the character dashboard → jumps to the Info tab.
class _SeeMoreButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _SeeMoreButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: context.r(14)),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: KColors.blue.withAlpha(18),
          borderRadius: BorderRadius.circular(context.r(16)),
          border: Border.all(color: KColors.blue.withAlpha(70), width: 1.4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ดูเพิ่มเติม',
              style: thaiSans(
                  size: context.r(16),
                  weight: FontWeight.w800,
                  color: KColors.blue),
            ),
            SizedBox(width: context.r(6)),
            Icon(Icons.arrow_forward_rounded,
                color: KColors.blue, size: context.r(20)),
          ],
        ),
      ),
    );
  }
}

/// Home-tab entry point for the elderly fitness-assessment module.
/// Uses the healthcare (teal→blue) palette.
class _AssessmentCard extends StatelessWidget {
  final VoidCallback onTap;
  final GlobalKey? cardKey;
  const _AssessmentCard({required this.onTap, this.cardKey});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final h = size.height;
    final cardH = h * 0.145; // ~25% smaller than the old 0.195 (0.127 clipped the content)
    return GestureDetector(
      key: cardKey,
      onTap: onTap,
      child: SizedBox(
        height: cardH,
        child: LayoutBuilder(
          builder: (context, cs) {
            final cw = cs.maxWidth;
            // Use card height for vertical spacing so the column never exceeds
            // the card's fixed height, regardless of device aspect ratio.
            final vPad = cardH * 0.12;
            final gap1 = cardH * 0.04;
            final gap2 = cardH * 0.06;
            final btnVPad = cw * 0.025;
            return Container(
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                gradient: KColors.assessmentCardGradient,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: KColors.hairline, width: 1),
                boxShadow: [
                  BoxShadow(
                      color: KColors.assessmentInk.withValues(alpha: 0.30),
                      blurRadius: 14,
                      offset: const Offset(0, 6)),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                          cw * 0.06, vPad, cw * 0.03, vPad),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('ประเมินสมรรถภาพ',
                              style: thaiSans(
                                  size: cw * 0.060,
                                  weight: FontWeight.w800,
                                  color: Colors.white)),
                          SizedBox(height: gap1),
                          Text('ทดสอบสมรรถภาพทางกายสำหรับผู้สูงอายุ',
                              style: thaiSans(
                                  size: cw * 0.030,
                                  weight: FontWeight.w600,
                                  color: Colors.white)),
                          SizedBox(height: gap2),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: cw * 0.05, vertical: btnVPad),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('เริ่มประเมิน',
                                style: thaiSans(
                                    size: cw * 0.036,
                                    weight: FontWeight.w800,
                                    color: KColors.assessmentInk)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(right: cw * 0.05),
                    child: Icon(Icons.monitor_heart_rounded,
                        size: cw * 0.22, color: Colors.white.withAlpha(230)),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Home-tab entry point for the "เรียนรู้ท่าฝึก" pose library. Sized and
/// structured to match _AssessmentCard; warm amber gradient so the two cards
/// read as a pair without looking like the same button twice.
class _LearnHomeCard extends StatelessWidget {
  final VoidCallback onTap;
  const _LearnHomeCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final h = size.height;
    final cardH = h * 0.145; // Exactly matches _AssessmentCard height

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: cardH,
        child: LayoutBuilder(
          builder: (context, cs) {
            final cw = cs.maxWidth;
            // Identical spacing logic to _AssessmentCard
            final vPad = cardH * 0.12;
            final gap1 = cardH * 0.04;
            final gap2 = cardH * 0.06;
            final btnVPad = cw * 0.025;

            return Container(
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                gradient: KColors.learnCardGradient,
                borderRadius: BorderRadius.circular(25), // Matched radius (25)
                border: Border.all(color: KColors.hairline, width: 1),
                boxShadow: [
                  BoxShadow(
                      color: KColors.learnCardInk.withValues(alpha: 0.30),
                      blurRadius: 14,
                      offset: const Offset(0, 6)),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                          cw * 0.06, vPad, cw * 0.03, vPad),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('เรียนรู้ท่าฝึก',
                              style: thaiSans(
                                  size: cw * 0.060, // Matched title size
                                  weight: FontWeight.w800,
                                  color: Colors.white)),
                          SizedBox(height: gap1),
                          Text('ท่าบริหารสำหรับผู้สูงอายุ 9 ท่า',
                              style: thaiSans(
                                  size: cw * 0.030, // Matched subtitle size
                                  weight: FontWeight.w600,
                                  color: Colors.white)),
                          SizedBox(height: gap2),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: cw * 0.05, vertical: btnVPad),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('ดูท่าฝึก',
                                style: thaiSans(
                                    size: cw * 0.036, // Matched button text size
                                    weight: FontWeight.w800,
                                    color: KColors.learnCardInk)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(right: cw * 0.05),
                    child: Icon(Icons.menu_book_rounded,
                        size: cw * 0.22, // Matched large right-aligned icon size
                        color: Colors.white.withAlpha(230)),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Multi-step guided tour: dims the whole screen and cuts a "hole" around each
/// target in turn (a nav tab, then the ประเมิน card), with a caption card and a
/// ถัดไป button. Tapping the dark area or the button advances; the last step
/// calls [onFinish]. Reuses [_SpotlightPainter] for the dim + hole.
typedef _CoachStep = (GlobalKey key, String title, String body);

class _CoachMarkOverlay extends StatefulWidget {
  final List<_CoachStep> steps;
  final VoidCallback onFinish;
  const _CoachMarkOverlay({required this.steps, required this.onFinish});

  @override
  State<_CoachMarkOverlay> createState() => _CoachMarkOverlayState();
}

class _CoachMarkOverlayState extends State<_CoachMarkOverlay> {
  int _step = 0;
  Offset? _lastTopLeft;

  @override
  void initState() {
    super.initState();
    _scheduleMeasure();
  }

  void _advance() {
    if (_step >= widget.steps.length - 1) {
      widget.onFinish();
      return;
    }
    setState(() {
      _step++;
      _lastTopLeft = null; // re-measure the new target
    });
    _scheduleMeasure();
  }

  // Re-measure across frames until the target's global position settles (the
  // card relayouts over a few frames on first home entry).
  void _scheduleMeasure() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = widget.steps[_step].$1.currentContext?.findRenderObject()
          as RenderBox?;
      if (box == null || !box.hasSize) {
        _scheduleMeasure();
        return;
      }
      final topLeft = box.localToGlobal(Offset.zero);
      if (_lastTopLeft != topLeft) {
        _lastTopLeft = topLeft;
        setState(() {});
        _scheduleMeasure();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final (key, title, body) = widget.steps[_step];
    final isLast = _step == widget.steps.length - 1;
    final rbox = key.currentContext?.findRenderObject() as RenderBox?;

    if (rbox == null || !rbox.hasSize) {
      // Not measured yet — plain dim (still tappable to advance).
      return Positioned.fill(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _advance,
          child: Container(color: Colors.black54),
        ),
      );
    }

    final rect = (rbox.localToGlobal(Offset.zero) & rbox.size).inflate(8);
    final screen = MediaQuery.sizeOf(context);
    // Put the caption on the roomier side of the hole (above for bottom targets).
    final below = rect.center.dy < screen.height * 0.5;

    final caption = Container(
      constraints: const BoxConstraints(maxWidth: 360),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: cardDecoration(radius: 18, color: Colors.white),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title,
              textAlign: TextAlign.center,
              style: thaiSans(
                  size: 18, weight: FontWeight.w800, color: KColors.navyText)),
          const SizedBox(height: 6),
          Text(body,
              textAlign: TextAlign.center,
              style: thaiSans(
                  size: 14,
                  weight: FontWeight.w500,
                  color: KColors.navyText.withAlpha(170))),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < widget.steps.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _step ? 20 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: i == _step ? KColors.purple : Colors.grey.withAlpha(90),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _advance,
            behavior: HitTestBehavior.opaque,
            child: Container(
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: KColors.purple,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(isLast ? 'เข้าใจแล้ว' : 'ถัดไป',
                  style: thaiSans(
                      size: 16, weight: FontWeight.w800, color: Colors.white)),
            ),
          ),
        ],
      ),
    );

    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(painter: _SpotlightPainter(rect: rect, radius: 20)),
        ),
        // Dark area advances the tour.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _advance,
          ),
        ),
        // Caption card on the roomier side of the hole.
        Positioned(
          left: 16,
          right: 16,
          top: below ? rect.bottom + 14 : null,
          bottom: below ? null : screen.height - rect.top + 14,
          child: Align(alignment: Alignment.center, child: caption),
        ),
      ],
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  final Rect rect;
  final double radius;
  const _SpotlightPainter({required this.rect, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, Paint()..color = Colors.black.withValues(alpha: 0.6));
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) => old.rect != rect;
}

class _TopBarIconButton extends StatelessWidget {
  final String asset;
  final Color? solidBorderColor;
  final LinearGradient? gradientBorder;
  final VoidCallback? onTap;

  const _TopBarIconButton({
    required this.asset,
    this.solidBorderColor,
    this.gradientBorder,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final size = w * 0.135;
    final radius = size * 0.28;

    final inner = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: KColors.cardBg,
        borderRadius: BorderRadius.circular(radius),
        border: solidBorderColor != null
            ? Border.all(color: solidBorderColor!, width: 3)
            : null,
        boxShadow: const [
          BoxShadow(color: Color(0x30000000), blurRadius: 6, offset: Offset(0, 3))
        ],
      ),
      padding: EdgeInsets.all(size * 0.16),
      child: Image.asset(asset, fit: BoxFit.contain),
    );

    final Widget content;
    if (gradientBorder != null) {
      content = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: gradientBorder,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: const [
            BoxShadow(color: Color(0x30000000), blurRadius: 6, offset: Offset(0, 3))
          ],
        ),
        padding: const EdgeInsets.all(3),
        child: Container(
          decoration: BoxDecoration(
            color: KColors.cardBg,
            borderRadius: BorderRadius.circular(radius - 3),
          ),
          padding: EdgeInsets.all(size * 0.14),
          child: Image.asset(asset, fit: BoxFit.contain),
        ),
      );
    } else {
      content = inner;
    }

    if (onTap == null) return content;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: content,
    );
  }
}

/// Top-bar Bluetooth button. A Kinex set is TWO boards, so the border reports
/// how many of them are live: grey = none, amber = only one (the state users
/// used to mistake for "done"), green = both. Tapping opens the sheet that
/// connects them one at a time.
class _BleTopBarButton extends ConsumerWidget {
  const _BleTopBarButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final legOk = ref.watch(
        bleControllerProvider.select((s) => s.status == BleStatus.connected));
    final handOk = ref
        .watch(handBleProvider.select((s) => s.status == BleStatus.connected));
    final done = (legOk ? 1 : 0) + (handOk ? 1 : 0);

    return _TopBarIconButton(
      asset: done > 0
          ? 'assets/images/icon_bluetooth.png'
          : 'assets/images/icon_bt_disconnected.png',
      solidBorderColor: switch (done) {
        2 => const Color(0xFF60A343), // both boards live
        1 => KColors.orangeDark, // half-connected — still needs the other one
        _ => const Color(0xFFB0B0B0),
      },
      // Always open the sheet — it explains that there are two boards and drives
      // the whole connect / searching / connected / disconnect flow.
      onTap: () => showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => const _BleConnectSheet(),
      ),
    );
  }
}

/// Bottom sheet behind the top-bar Bluetooth button. Shows BOTH Kinex boards —
/// leg and hand — at once, because users were connecting one and assuming the
/// set was ready. All the connect logic lives in [DeviceConnectPanel], shared
/// with the cold-launch connect page.
class _BleConnectSheet extends ConsumerWidget {
  const _BleConnectSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.r;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(r(20), r(12), r(20), r(20) + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: r(40),
              height: r(4),
              margin: EdgeInsets.only(bottom: r(18)),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(r(2)),
              ),
            ),
            DeviceConnectPanel(
              onOpenDebug: () {
                Navigator.pop(context);
                context.push('/ble-debug');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends ConsumerWidget {
  const _ProfileCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    final h = size.height;
    final cardH = h * 0.10;
    final avatarR = cardH * 0.48;

    return SizedBox(
      height: cardH,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(cardH / 2),
          border: Border.all(color: KColors.hairline, width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(cardH / 2),
          child: Stack(
            children: [
              Positioned.fill(child: Container(color: const Color(0xFFF4F4F4))),
              Positioned(
                left: avatarR * 0.4,
                top: cardH * 0.55,
                bottom: 0,
                right: 0,
                child: Container(color: KColors.blue),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(width: avatarR * 0.15),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'settings') context.push('/settings');
                      if (value == 'devices') context.push('/devices');
                      if (value == 'debug') context.push('/ble-debug');
                      if (value == 'games') context.push('/game-debug');
                    },
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    color: Colors.white,
                    padding: EdgeInsets.zero,
                    itemBuilder: (_) => [
                      PopupMenuItem<String>(
                        value: 'settings',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.settings_rounded,
                                color: KColors.navyText, size: 20),
                            const SizedBox(width: 10),
                            Text('ตั้งค่า',
                                style: thaiSans(
                                    size: 16,
                                    weight: FontWeight.w600,
                                    color: KColors.navyText)),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'devices',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.devices_other_rounded,
                                color: KColors.navyText, size: 20),
                            const SizedBox(width: 10),
                            Text('อุปกรณ์ Kinex',
                                style: thaiSans(
                                    size: 16,
                                    weight: FontWeight.w600,
                                    color: KColors.navyText)),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'debug',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bluetooth_searching_rounded,
                                color: KColors.navyText, size: 20),
                            const SizedBox(width: 10),
                            Text('BLE Debug',
                                style: thaiSans(
                                    size: 16,
                                    weight: FontWeight.w600,
                                    color: KColors.navyText)),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'games',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.sports_esports_rounded,
                                color: KColors.navyText, size: 20),
                            const SizedBox(width: 10),
                            Text('Game Debug',
                                style: thaiSans(
                                    size: 16,
                                    weight: FontWeight.w600,
                                    color: KColors.navyText)),
                          ],
                        ),
                      ),
                    ],
                    child: Container(
                      width: avatarR * 2,
                      height: avatarR * 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border:
                            Border.all(color: const Color(0xFFBEBEBE), width: 3),
                        boxShadow: const [
                          BoxShadow(
                              color: Color(0x25000000),
                              blurRadius: 6,
                              offset: Offset(0, 2))
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset('assets/images/app_logo.png',
                            fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  SizedBox(width: w * 0.025),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ref.watch(latestAssessmentProvider).maybeWhen(
                              data: (rec) =>
                                  _ResultPill(risk: rec?.risk),
                              orElse: () => _ResultPill(risk: null),
                            ),
                        Text(ref.watch(userNameProvider),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: montserrat(
                                size: w * 0.030,
                                weight: FontWeight.w900,
                                color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Profile-card badge showing the latest ประเมินสมรรถภาพ result on a coloured
/// background, or a soft "not assessed yet" hint. Taps through to the assessment.
class _ResultPill extends StatelessWidget {
  final FallRisk? risk;
  const _ResultPill({required this.risk});

  @override
  Widget build(BuildContext context) {
    final assessed = risk != null;
    final c = assessed ? fallRiskColor(risk!) : const Color(0xFF9AA3B8);
    return GestureDetector(
      onTap: () => context.push('/assessment'),
      behavior: HitTestBehavior.opaque,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: KPill(
          assessed ? 'ผลประเมิน: ${risk!.thaiShort}' : 'ยังไม่ได้ประเมิน',
          color: c,
          icon: assessed
              ? Icons.monitor_heart_rounded
              : Icons.assignment_outlined,
        ),
      ),
    );
  }
}

// ── QUEST TAB ───────────────────────────────────────────────────────────────

class _QuestTab extends StatelessWidget {
  const _QuestTab();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    final h = size.height;
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/images/bg_room.png', fit: BoxFit.cover),
        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                    w * 0.06, h * 0.025, w * 0.06, h * 0.025),
                child: Text(
                  'Complete\nYour Quest',
                  textAlign: TextAlign.left,
                  style: nunito(size: w * 0.085, weight: FontWeight.w900),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(
                      horizontal: w * 0.04, vertical: h * 0.01),
                  children: [
                    _QuestCard(
                      imagePath: 'assets/images/quest_card1.png',
                      aspectRatio: 1768 / 654,
                      progress: 0.75,
                      progressLabel: '15/20',
                      progressFillColors: const [
                        Color(0xFF8B5CF6),
                        Color(0xFFA3E635),
                      ],
                      receiveButtonPath: 'assets/images/red_receive_button.png',
                    ),
                    SizedBox(height: h * 0.022),
                    _QuestCard(
                      imagePath: 'assets/images/quest_card2.png',
                      aspectRatio: 1762 / 654,
                      progress: 0.3,
                      progressLabel: '3/10',
                      progressFillColors: const [Color(0xFF4ADE80)],
                      receiveButtonPath: 'assets/images/red_receive_button.png',
                    ),
                    SizedBox(height: h * 0.022),
                    _QuestCard(
                      imagePath: 'assets/images/quest_card3.png',
                      aspectRatio: 1796 / 606,
                      progress: 1.0,
                      progressLabel: '100%',
                      progressFillColors: const [Color(0xFFA3E635)],
                      receiveButtonPath: 'assets/images/green_receive_button.png',
                    ),
                    SizedBox(height: h * 0.02),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuestCard extends StatelessWidget {
  final String imagePath;
  final double aspectRatio;
  final double progress;
  final String progressLabel;
  final List<Color> progressFillColors;
  final String receiveButtonPath;
  final VoidCallback? onTap;

  const _QuestCard({
    required this.imagePath,
    required this.aspectRatio,
    required this.progress,
    required this.progressLabel,
    required this.progressFillColors,
    required this.receiveButtonPath,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    final h = size.height;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: Image.asset(imagePath, fit: BoxFit.fill),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(right: w * 0.03),
              child: Align(
                alignment: Alignment.centerRight,
                child: Image.asset(receiveButtonPath, width: w * 0.28),
              ),
            ),
          ),
          Positioned(
            bottom: h * 0.014,
            left: w * 0.04,
            right: w * 0.32,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _QuestProgressBar(
                    progress: progress, fillColors: progressFillColors),
                SizedBox(height: h * 0.004),
                Text(progressLabel,
                    style: montserrat(
                        size: w * 0.028,
                        weight: FontWeight.w700,
                        color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestProgressBar extends StatelessWidget {
  final double progress;
  final List<Color> fillColors;

  const _QuestProgressBar(
      {required this.progress, required this.fillColors});

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: h * 0.014,
        color: const Color(0xFF2D2D2D),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              decoration: fillColors.length > 1
                  ? BoxDecoration(
                      gradient: LinearGradient(colors: fillColors),
                    )
                  : BoxDecoration(color: fillColors.first),
            ),
          ),
        ),
      ),
    );
  }
}

// ── PRACTICE TAB ────────────────────────────────────────────────────────────

class _PracticeTab extends StatelessWidget {
  final VoidCallback onStartGame;
  const _PracticeTab({required this.onStartGame});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    final h = size.height;
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/images/bg_room.png', fit: BoxFit.cover),
        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                    w * 0.06, h * 0.025, w * 0.06, h * 0.02),
                child: Text('ฝึกซ้อม',
                    style: montserrat(
                        size: w * 0.09,
                        weight: FontWeight.w900,
                        color: Colors.white)),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(
                      horizontal: w * 0.04, vertical: h * 0.01),
                  children: [
                    // ── REHAB section: Handglider + MEGA DANCE ───────────────
                    // Hang Glider (Unity scene id "hangglider") — tilt-controlled
                    // quiz game, plays in landscape. This is its designed card.
                    _PracticeCard(
                      imagePath: 'assets/images/practice_card1.png',
                      aspectRatio: 1780 / 536,
                      onTap: () => context.push('/hang-glider'),
                    ),
                    SizedBox(height: h * 0.025),
                    _PracticeCard(
                      imagePath: 'assets/images/practice_card2.png',
                      aspectRatio: 1772 / 638,
                      onTap: onStartGame,
                    ),
                    SizedBox(height: h * 0.025),
                    // The Dasher (Unity scene id "thedasher") — the card opens the
                    // mission/start page; the tutorial pop-ups now appear as an
                    // overlay ON the game after เริ่มภารกิจ (normal game flow).
                    _PracticeCard(
                      imagePath: 'assets/images/the_dasher/card.png',
                      aspectRatio: 855 / 367,
                      onTap: () => context.push('/the-dasher-start'),
                    ),
                    SizedBox(height: h * 0.035),
                    // ── EXERCISE section: Kinex World ────────────────────────
                    _PracticeCard(
                      imagePath: 'assets/images/practice_card3.png',
                      aspectRatio: 1762 / 650,
                      onTap: () => context.go('/world'),
                    ),
                    SizedBox(height: h * 0.02),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Always-visible shortcut to the fitness assessment, locked bottom-right
        // above the nav bar so it never scrolls away with the game list.
        Positioned(
          right: w * 0.05,
          bottom: h * 0.11,
          child: _AssessFab(onTap: () => context.push('/assessment')),
        ),
      ],
    );
  }
}

/// Confident primary shortcut to the ประเมิน (assessment) flow from the
/// practice page. Solid teal fill, bigger footprint than a plain FAB so it
/// reads as the page's main call-to-action rather than a decorative pill.
class _AssessFab extends StatelessWidget {
  final VoidCallback onTap;
  const _AssessFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: context.r(22), vertical: context.r(16)),
        decoration: BoxDecoration(
          gradient: KColors.assessmentCardGradient,
          borderRadius: BorderRadius.circular(context.r(28)),
          border: Border.all(color: KColors.hairline, width: 1),
          boxShadow: [
            BoxShadow(
              color: KColors.assessmentInk.withValues(alpha: 0.35),
              blurRadius: context.r(16),
              offset: Offset(0, context.r(6)),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(context.r(6)),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.monitor_heart_rounded,
                  color: Colors.white, size: context.r(24)),
            ),
            SizedBox(width: context.r(10)),
            Text('ประเมินอีกครั้ง',
                style: thaiSans(
                    size: context.r(17),
                    weight: FontWeight.w800,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

class _PracticeCard extends StatelessWidget {
  final String imagePath;
  final double aspectRatio;
  final VoidCallback? onTap;

  const _PracticeCard({
    required this.imagePath,
    required this.aspectRatio,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: Image.asset(imagePath, fit: BoxFit.fill),
          ),
        ),
        Positioned(
          left: w * 0.05,
          child: GestureDetector(
            onTap: onTap,
            child: Image.asset(
              'assets/images/clicktostartbutton.png',
              width: w * 0.30,
            ),
          ),
        ),
      ],
    );
  }
}

// ── INFO TAB ────────────────────────────────────────────────────────────────

class _InfoTab extends StatelessWidget {
  const _InfoTab();

  @override
  Widget build(BuildContext context) => const InfoPage();
}
