import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../state/home_intro_providers.dart';
import '../data/assessment_repository.dart';
import '../data/emg_repository.dart';
import '../models/fall_risk.dart';
import '../widgets/fall_risk_cards.dart';
import '../ble/ble_service.dart';
import '../theme/responsive.dart';
import 'package:permission_handler/permission_handler.dart';
import '../data/customize_catalog.dart';
import '../state/shop_providers.dart';
import 'info_page.dart';
import 'shop_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _tab = 0;
  int _homePage = 0;
  final PageController _homeCtrl = PageController();

  @override
  void dispose() {
    _homeCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Every app entry: show the EMG hardware-install guide, then spotlight the
    // assessment card on home. Flags are in-memory so they reset each launch.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      // Step 1: BLE connect-device landing (shown once per launch, skipped if
      // the device is already connected from a previous session or quick-connect).
      if (ref.read(deviceConnectPendingProvider) &&
          ref.read(bleControllerProvider).status != BleStatus.connected) {
        ref.read(deviceConnectPendingProvider.notifier).state = false;
        await context.push('/connect-device');
        if (!mounted) return;
      } else {
        ref.read(deviceConnectPendingProvider.notifier).state = false;
      }

      // Step 2: EMG hardware-install guide (existing flow).
      if (ref.read(homeGuidePendingProvider)) {
        ref.read(homeGuidePendingProvider.notifier).state = false;
        final result = await context.push('/hardware-guide');
        if (!mounted) return;
        // result == true only when the guide was fully finished; anything else
        // (skip / back-dismiss) means the EMG pads weren't installed this run.
        ref.read(emgInstallSkippedProvider.notifier).state = result != true;
        ref.read(assessmentSpotlightProvider.notifier).state = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _tab,
        children: [
          // Home tab: swipeable between original Home and Character dashboard.
          PageView(
            controller: _homeCtrl,
            onPageChanged: (i) => setState(() => _homePage = i),
            children: [
              const _HomeTab(),
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
          ),
        ],
      ),
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

  const _KinexNavBar({required this.selected, required this.onTap});

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
  const _HomeTab();

  @override
  ConsumerState<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<_HomeTab> {
  // Used to measure the on-screen rect of the ประเมิน card for the spotlight.
  final GlobalKey _assessmentKey = GlobalKey();

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
                      cardKey: _assessmentKey,
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
        // Spotlight: dim everything except the ประเมิน card until dismissed.
        if (ref.watch(assessmentSpotlightProvider))
          _SpotlightOverlay(
            targetKey: _assessmentKey,
            onDismiss: () =>
                ref.read(assessmentSpotlightProvider.notifier).state = false,
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
                                child: _StatRing(
                                  value: dStreak,
                                  label: 'วัน',
                                  color: KColors.orange,
                                  maxValue: 7,
                                ),
                              ),
                              Expanded(
                                child: _StatRing(
                                  value: dMins,
                                  label: 'นาที',
                                  color: KColors.teal,
                                  maxValue: 60,
                                ),
                              ),
                              Expanded(
                                child: _StatRing(
                                  value: dScore,
                                  label: 'คะแนน',
                                  color: KColors.blue,
                                  maxValue: 100,
                                  suffix: '%',
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
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: context.r(10), vertical: context.r(4)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8C00), Color(0xFFFF5722)],
        ),
        borderRadius: BorderRadius.circular(context.r(20)),
      ),
      child: Text(
        '🔥 $streak วัน',
        style: thaiSans(
            size: context.r(13), weight: FontWeight.w800, color: Colors.white),
      ),
    );
  }
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
          // Soft glow plinth under the feet.
          Positioned(
            bottom: context.r(6),
            child: Container(
              width: context.r(150),
              height: context.r(30),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(context.r(80)),
                boxShadow: [
                  BoxShadow(
                    color: (awake ? KColors.blue : Colors.grey).withAlpha(70),
                    blurRadius: context.r(34),
                    spreadRadius: context.r(6),
                  ),
                ],
              ),
            ),
          ),
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

// ── Stat ring ─────────────────────────────────────────────────────────────────

class _StatRing extends StatelessWidget {
  final int? value;
  final String label;
  final Color color;
  final int maxValue;
  final String suffix;

  const _StatRing({
    required this.value,
    required this.label,
    required this.color,
    required this.maxValue,
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    final size = context.r(104);
    final progress = (value == null || maxValue == 0)
        ? 0.0
        : (value! / maxValue).clamp(0.0, 1.0);
    final displayText = value == null ? '—' : '${value!}$suffix';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: progress,
                strokeWidth: context.r(14),
                backgroundColor: const Color(0xFFEDEDF3),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
              Text(
                displayText,
                style: montserrat(
                  size: context.r(value == null ? 20 : 22),
                  weight: FontWeight.w900,
                  color: KColors.navyText,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: context.r(8)),
        Text(
          label,
          style: thaiSans(
            size: context.r(13),
            weight: FontWeight.w600,
            color: KColors.navyText.withAlpha(140),
          ),
        ),
      ],
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

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: context.r(16), vertical: context.r(12)),
      decoration: BoxDecoration(
        color: accent.withAlpha(22),
        borderRadius: BorderRadius.circular(context.r(16)),
      ),
      child: Row(
        children: [
          Icon(icon, color: accent, size: context.r(22)),
          SizedBox(width: context.r(10)),
          Text(
            text,
            style: thaiSans(
                size: context.r(14), weight: FontWeight.w700, color: accent),
          ),
        ],
      ),
    );
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
class _AssessmentCard extends StatefulWidget {
  final VoidCallback onTap;
  final GlobalKey? cardKey;
  const _AssessmentCard({required this.onTap, this.cardKey});

  @override
  State<_AssessmentCard> createState() => _AssessmentCardState();
}

class _AssessmentCardState extends State<_AssessmentCard>
    with SingleTickerProviderStateMixin {
  // Gentle "real game" highlight: a slow teal glow that breathes in and out.
  late final AnimationController _glow = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1900))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final h = size.height;
    final cardH = h * 0.145; // ~25% smaller than the old 0.195 (0.127 clipped the content)
    return AnimatedBuilder(
      key: widget.cardKey,
      animation: _glow,
      builder: (context, child) {
        final t = _glow.value; // 0..1
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: KColors.teal.withAlpha((45 + 90 * t).round()),
                blurRadius: 16 + 16 * t,
                spreadRadius: 1 + 2 * t,
              ),
            ],
          ),
          child: child,
        );
      },
      child: GestureDetector(
      onTap: widget.onTap,
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
                gradient: KColors.tealGradient,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white.withAlpha(112), width: 3),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 20,
                      offset: Offset(5, 5))
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
                                    color: KColors.tealDark)),
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
      ),
    );
  }
}

/// Home-tab entry point for the "เรียนรู้ท่าฝึก" pose library. A compact
/// purple banner shown right below the assessment card.
/// Home-tab entry point for the "เรียนรู้ท่าฝึก" pose library. 
/// Now identically sized and structured to match _AssessmentCard.
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
                // 3 shades (purple → deep purple → teal) instead of a flat single-hue
                // fill — ties together the Learn feature's own two categories
                // (strength=purple, balance=teal) so the card reads as more than
                // one colour at a glance.
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [KColors.purple, KColors.deepPurple, KColors.teal],
                  stops: [0.0, 0.55, 1.0],
                ),
                borderRadius: BorderRadius.circular(25), // Matched radius (25)
                border: Border.all(color: Colors.white.withAlpha(112), width: 3),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 20, // Matched shadow radius
                      offset: Offset(5, 5))
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
                                    color: KColors.deepPurple)), // Deep purple text for button
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

/// Full-screen dim with a "hole" cut around the ประเมิน card. Taps in the dark
/// dismiss the spotlight; taps on the card open the assessment.
class _SpotlightOverlay extends StatefulWidget {
  final GlobalKey targetKey;
  final VoidCallback onDismiss;
  const _SpotlightOverlay({required this.targetKey, required this.onDismiss});

  @override
  State<_SpotlightOverlay> createState() => _SpotlightOverlayState();
}

class _SpotlightOverlayState extends State<_SpotlightOverlay> {
  @override
  void initState() {
    super.initState();
    _scheduleMeasure();
  }

  Offset? _lastTopLeft;

  // Re-measure across frames until the card's global position stops changing.
  // On first home entry the card (inside Align → FractionallySizedBox) and the
  // reminder banner above it relayout over a few frames, so a single measurement
  // reads a stale (too-far-left) X. We keep checking until two consecutive frames
  // agree, then stop — matching the value seen after re-navigation.
  void _scheduleMeasure() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box =
          widget.targetKey.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) {
        _scheduleMeasure();
        return;
      }
      final topLeft = box.localToGlobal(Offset.zero);
      if (_lastTopLeft != topLeft) {
        _lastTopLeft = topLeft;
        setState(() {});
        _scheduleMeasure(); // position still moving — keep watching
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final box =
        widget.targetKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      // Fallback: plain dim that just dismisses on tap (no hole yet).
      return Positioned.fill(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onDismiss,
          child: Container(color: Colors.black54),
        ),
      );
    }

    final topLeft = box.localToGlobal(Offset.zero);
    final rect = (topLeft & box.size).inflate(8);
    final screen = MediaQuery.sizeOf(context);

    // Caption just below the hole, clamped within the screen.
    final captionTop = (rect.bottom + 12).clamp(0.0, screen.height - 40.0);

    return Stack(
      children: [
        // Dim everything except the rounded hole around the card.
        Positioned.fill(
          child: CustomPaint(
            painter: _SpotlightPainter(rect: rect, radius: 24),
          ),
        ),
        // Tapping the dark area dismisses the spotlight.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onDismiss,
          ),
        ),
        // Hint caption.
        Positioned(
          left: 16,
          right: 16,
          top: captionTop,
          child: Text(
            'แตะที่การ์ดเพื่อเริ่มประเมิน',
            textAlign: TextAlign.center,
            style: thaiSans(
                size: 16, weight: FontWeight.w700, color: Colors.white),
          ),
        ),
        // Tapping the card opens the assessment (on top of the dismiss layer).
        Positioned(
          left: rect.left,
          top: rect.top,
          width: rect.width,
          height: rect.height,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              widget.onDismiss();
              context.push('/assessment');
            },
            child: const SizedBox.expand(),
          ),
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

/// Top-bar Bluetooth button: one-tap connect / disconnect with the ESP32, and a
/// live icon — the normal Bluetooth glyph when connected, the "disconnected"
/// glyph otherwise. The full scan/send console lives in the BLE Debug window
/// (reachable from the profile menu).
class _BleTopBarButton extends ConsumerWidget {
  const _BleTopBarButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(bleControllerProvider.select((s) => s.status));
    final connected = status == BleStatus.connected;

    return _TopBarIconButton(
      asset: connected
          ? 'assets/images/icon_bluetooth.png'
          : 'assets/images/icon_bt_disconnected.png',
      solidBorderColor:
          connected ? const Color(0xFF60A343) : const Color(0xFFB0B0B0),
      // Always open the sheet — it explains the button and drives the whole
      // connect / searching / connected / disconnect flow with clear feedback.
      onTap: () => showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => const _BleConnectSheet(),
      ),
    );
  }
}

/// Bottom sheet behind the top-bar Bluetooth button. One adaptive surface that
/// covers every state — intro, searching, connected, not-found, and the
/// permission-blocked case — so the user always knows what the button is doing.
class _BleConnectSheet extends ConsumerStatefulWidget {
  const _BleConnectSheet();

  @override
  ConsumerState<_BleConnectSheet> createState() => _BleConnectSheetState();
}

class _BleConnectSheetState extends ConsumerState<_BleConnectSheet> {
  // True once the user has pressed "search" this sheet session, so we can tell
  // the first-open intro apart from a finished-but-failed scan.
  bool _attempted = false;

  void _scan() {
    setState(() => _attempted = true);
    ref.read(bleControllerProvider.notifier).quickConnect();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bleControllerProvider);
    final r = context.r;

    // Auto-dismiss shortly after a successful connection so the success state
    // is visible for a beat, then gets out of the way.
    ref.listen(bleControllerProvider.select((s) => s.status), (prev, next) {
      if (next == BleStatus.connected && mounted) {
        final navigator = Navigator.of(context);
        Future.delayed(const Duration(milliseconds: 950), () {
          if (mounted && navigator.canPop()) navigator.pop();
        });
      }
    });

    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(r(24), r(12), r(24), r(24) + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: r(40),
            height: r(4),
            margin: EdgeInsets.only(bottom: r(20)),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(r(2)),
            ),
          ),
          _buildBody(state, r),
        ],
      ),
    );
  }

  Widget _buildBody(BleState state, double Function(double) r) {
    switch (state.status) {
      case BleStatus.connected:
        return _connectedView(state, r);
      case BleStatus.scanning:
      case BleStatus.connecting:
        return _searchingView(r);
      case BleStatus.idle:
        if (state.needsSettings) return _permissionView(state, r);
        if (_attempted) return _notFoundView(state, r);
        return _introView(r);
    }
  }

  // ── Visual building blocks ────────────────────────────────────────────────

  Widget _haloIcon(IconData icon, Color color, double Function(double) r,
      {Widget? overlay}) {
    return Container(
      width: r(76),
      height: r(76),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withAlpha(26),
      ),
      child: overlay ?? Icon(icon, color: color, size: r(38)),
    );
  }

  Widget _title(String text, double Function(double) r) => Text(
        text,
        textAlign: TextAlign.center,
        style: thaiSans(
            size: r(19), weight: FontWeight.w700, color: KColors.navyText),
      );

  Widget _subtitle(String text, double Function(double) r) => Text(
        text,
        textAlign: TextAlign.center,
        style: thaiSans(size: r(14), color: Colors.grey.shade600),
      );

  Widget _primaryButton(
          String label, Color color, VoidCallback onTap, double Function(double) r,
          {IconData? icon}) =>
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: r(15)),
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(r(16))),
          ),
          icon: icon == null
              ? const SizedBox.shrink()
              : Icon(icon, size: r(20)),
          label: Text(label,
              style: thaiSans(
                  size: r(16), weight: FontWeight.w700, color: Colors.white)),
          onPressed: onTap,
        ),
      );

  Widget _textButton(
          String label, VoidCallback onTap, double Function(double) r) =>
      TextButton(
        onPressed: onTap,
        child: Text(label,
            style: thaiSans(
                size: r(14), weight: FontWeight.w600, color: KColors.teal)),
      );

  void _openDebug() {
    Navigator.pop(context);
    context.push('/ble-debug');
  }

  // ── States ────────────────────────────────────────────────────────────────

  Widget _introView(double Function(double) r) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _haloIcon(Icons.bluetooth_rounded, KColors.blue, r),
          SizedBox(height: r(16)),
          _title('เชื่อมต่ออุปกรณ์ Kinex', r),
          SizedBox(height: r(8)),
          _subtitle('ปุ่มนี้ใช้เชื่อมต่อกับกล่องเซนเซอร์ (ESP32) ผ่าน Bluetooth\n'
              'เปิดเครื่องอุปกรณ์ให้พร้อม แล้วกดค้นหา', r),
          SizedBox(height: r(22)),
          _primaryButton('ค้นหาและเชื่อมต่อ', KColors.blue, _scan, r,
              icon: Icons.bluetooth_searching_rounded),
          SizedBox(height: r(4)),
          _textButton('เปิดหน้า BLE Debug', _openDebug, r),
        ],
      );

  Widget _searchingView(double Function(double) r) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _haloIcon(
            Icons.bluetooth_searching_rounded,
            KColors.blue,
            r,
            overlay: Center(
              child: SizedBox(
                width: r(34),
                height: r(34),
                child: CircularProgressIndicator(
                    strokeWidth: 3, color: KColors.blue),
              ),
            ),
          ),
          SizedBox(height: r(16)),
          _title('กำลังค้นหาอุปกรณ์…', r),
          SizedBox(height: r(8)),
          _subtitle('ตรวจสอบว่าเปิดเครื่อง ESP32 และอยู่ใกล้แท็บเล็ต', r),
          SizedBox(height: r(20)),
        ],
      );

  Widget _connectedView(BleState state, double Function(double) r) {
    final name = state.connectedName ?? state.connectedId ?? 'อุปกรณ์ Kinex';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _haloIcon(Icons.bluetooth_connected_rounded, KColors.teal, r),
        SizedBox(height: r(16)),
        _title('เชื่อมต่อแล้ว', r),
        SizedBox(height: r(8)),
        _subtitle(name, r),
        SizedBox(height: r(22)),
        _primaryButton('ตัดการเชื่อมต่อ', const Color(0xFFE53935),
            () => ref.read(bleControllerProvider.notifier).disconnect(), r,
            icon: Icons.link_off_rounded),
        SizedBox(height: r(4)),
        _textButton('เปิดหน้า BLE Debug', _openDebug, r),
      ],
    );
  }

  Widget _notFoundView(BleState state, double Function(double) r) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _haloIcon(Icons.bluetooth_disabled_rounded, KColors.orangeDark, r),
          SizedBox(height: r(16)),
          _title('ไม่พบอุปกรณ์ Kinex', r),
          SizedBox(height: r(8)),
          _subtitle('ตรวจสอบว่าเปิดเครื่อง ESP32 แล้ว และเปิด Bluetooth '
              'ของแท็บเล็ตไว้ จากนั้นลองอีกครั้ง', r),
          SizedBox(height: r(22)),
          _primaryButton('ลองอีกครั้ง', KColors.blue, _scan, r,
              icon: Icons.refresh_rounded),
          SizedBox(height: r(4)),
          _textButton('เลือกอุปกรณ์เองใน BLE Debug', _openDebug, r),
        ],
      );

  Widget _permissionView(BleState state, double Function(double) r) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _haloIcon(Icons.lock_outline_rounded, KColors.orangeDark, r),
          SizedBox(height: r(16)),
          _title('ต้องอนุญาต Bluetooth', r),
          SizedBox(height: r(8)),
          _subtitle('แอปต้องการสิทธิ์ Bluetooth เพื่อค้นหาและเชื่อมต่ออุปกรณ์\n'
              'เปิดสิทธิ์ในการตั้งค่าแอป แล้วกลับมาลองใหม่', r),
          SizedBox(height: r(22)),
          _primaryButton('เปิดการตั้งค่า', KColors.blue, () => openAppSettings(),
              r,
              icon: Icons.settings_rounded),
          SizedBox(height: r(4)),
          _textButton('ลองอีกครั้ง', _scan, r),
        ],
      );
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
          boxShadow: const [
            BoxShadow(
                color: Color(0x40000000),
                blurRadius: 8,
                offset: Offset(0, 4))
          ],
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
                                  _ResultPill(risk: rec?.risk, w: w),
                              orElse: () => _ResultPill(risk: null, w: w),
                            ),
                        Text('@ray_lorkasemsan',
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
  final double w;
  const _ResultPill({required this.risk, required this.w});

  @override
  Widget build(BuildContext context) {
    final assessed = risk != null;
    final c = assessed ? fallRiskColor(risk!) : const Color(0xFF9AA3B8);
    final dark = Color.lerp(c, Colors.black, 0.18)!;
    return GestureDetector(
      onTap: () => context.push('/assessment'),
      behavior: HitTestBehavior.opaque,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: Container(
        padding: EdgeInsets.symmetric(horizontal: w * 0.028, vertical: w * 0.014),
        decoration: BoxDecoration(
          gradient: assessed
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [c, dark])
              : null,
          color: assessed ? null : const Color(0xFFEDEFF5),
          borderRadius: BorderRadius.circular(999),
          boxShadow: assessed
              ? [BoxShadow(color: c.withAlpha(140), blurRadius: 12, offset: const Offset(0, 3))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              assessed ? Icons.monitor_heart_rounded : Icons.assignment_outlined,
              color: assessed ? Colors.white : const Color(0xFF7A839B),
              size: w * 0.045,
            ),
            SizedBox(width: w * 0.015),
            Text(
              assessed ? 'ผลประเมิน: ${risk!.thaiShort}' : 'ยังไม่ได้ประเมิน',
              style: thaiSans(
                  size: w * 0.034,
                  weight: FontWeight.w800,
                  color: assessed ? Colors.white : const Color(0xFF5B6B86)),
            ),
          ],
        ),
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
                    _SectionHeader(
                      icon: Icons.healing_rounded,
                      label: 'ฟื้นฟูร่างกาย · REHAB',
                      color: KColors.teal,
                    ),
                    _PracticeCard(
                      imagePath: 'assets/images/practice_card1.png',
                      aspectRatio: 1780 / 536,
                      onTap: null,
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
                    _SectionHeader(
                      icon: Icons.fitness_center_rounded,
                      label: 'ออกกำลังกาย · EXERCISE',
                      color: KColors.purple,
                    ),
                    _PracticeCard(
                      imagePath: 'assets/images/practice_card3.png',
                      aspectRatio: 1762 / 650,
                      onTap: () => context.go('/world'),
                    ),
                    SizedBox(height: h * 0.025),
                    // Hang Glider (Unity scene id "hangglider") — tilt-controlled
                    // quiz game, plays in landscape. No designed card art yet, so
                    // this is a self-contained gradient card.
                    _GliderCard(onTap: () => context.push('/hang-glider')),
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

/// Self-contained gradient card for the Hang Glider game (no image asset yet).
class _GliderCard extends StatelessWidget {
  final VoidCallback onTap;
  const _GliderCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF5EC6F2), Color(0xFF2E8BD6), Color(0xFF1FB6A6)],
            stops: [0.0, 0.55, 1.0],
          ),
          boxShadow: const [
            BoxShadow(
                color: Color(0x332E8BD6), blurRadius: 16, offset: Offset(0, 8)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.paragliding_rounded,
                  color: Colors.white, size: 34),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('เกมเครื่องร่อน',
                      style: thaiSans(
                          size: 18,
                          weight: FontWeight.w800,
                          color: Colors.white)),
                  const SizedBox(height: 3),
                  Text('เอียงแท็บเล็ตเพื่อบังคับ · ตอบคำถาม',
                      maxLines: 2,
                      style: thaiSans(
                          size: 12.5,
                          weight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.92))),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('เล่น',
                      style: thaiSans(
                          size: 13,
                          weight: FontWeight.w800,
                          color: const Color(0xFF2E8BD6))),
                  const SizedBox(width: 4),
                  const Icon(Icons.play_arrow_rounded,
                      color: Color(0xFF2E8BD6), size: 18),
                ],
              ),
            ),
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

// ── SECTION HEADER ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _SectionHeader(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: context.r(4), bottom: context.r(14)),
      child: Row(
        children: [
          // White rounded pill so the label reads clearly over the room bg.
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: context.r(12), vertical: context.r(8)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(context.r(16)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(22),
                  blurRadius: context.r(8),
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(context.r(7)),
                  decoration: BoxDecoration(
                    color: color.withAlpha(38),
                    borderRadius: BorderRadius.circular(context.r(10)),
                  ),
                  child: Icon(icon, color: Colors.black, size: context.r(22)),
                ),
                SizedBox(width: context.r(10)),
                Text(
                  label,
                  style: thaiSans(
                      size: context.r(19),
                      weight: FontWeight.w800,
                      color: Colors.black),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── INFO TAB ────────────────────────────────────────────────────────────────

class _InfoTab extends StatelessWidget {
  const _InfoTab();

  @override
  Widget build(BuildContext context) => const InfoPage();
}
