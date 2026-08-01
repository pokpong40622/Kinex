import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../card_game/services/daily_progress_store.dart';
import '../../data/pose_library.dart';
import '../../state/learn_progress.dart';
import '../../theme/app_theme.dart';
import '../../theme/kui.dart';
import '../../theme/responsive.dart';

/// "เรียนรู้" — the learning hub, and the second tab in the bottom nav.
///
/// It fronts the app's two study features: the pose library (เรียนรู้ท่าฝึก)
/// and the balance/fall-prevention card game (การ์ดเรียนรู้). Both used to be
/// cards buried on the Home tab, where they competed with the assessment CTA
/// and were easy to miss.
///
/// The page leads with progress rather than with the two buttons, because the
/// reason to open this tab a second time is "I am 5 of 9 poses through" — not
/// "here are two things". Both numbers are real: pose count comes from
/// [learnProgressProvider], the daily points from [DailyProgressStore], which
/// resets itself at midnight.
///
/// Typography and hit targets are deliberately large: the audience is elderly
/// rehab patients, several with vision or dexterity limitations.
class LearningCenterPage extends ConsumerStatefulWidget {
  const LearningCenterPage({super.key});

  @override
  ConsumerState<LearningCenterPage> createState() => _LearningCenterPageState();
}

class _LearningCenterPageState extends ConsumerState<LearningCenterPage> {
  DailyProgress? _daily;

  @override
  void initState() {
    super.initState();
    _loadDaily();
  }

  Future<void> _loadDaily() async {
    final d = await DailyProgressStore.today();
    if (mounted) setState(() => _daily = d);
  }

  /// The card game writes points on its way out, so the header is stale the
  /// moment we come back from it. Reload on return rather than polling.
  Future<void> _openCardGame() async {
    await context.push('/card-game');
    await _loadDaily();
  }

  @override
  Widget build(BuildContext context) {
    final viewed = ref.watch(learnProgressProvider);
    final total = posesIn(PoseCategory.strength).length +
        posesIn(PoseCategory.balance).length;
    final learned = viewed.length.clamp(0, total);
    final daily = _daily;

    return Container(
      color: KColors.appBg,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
              context.r(18), context.r(14), context.r(18), context.r(120)),
          children: [
            Text('เรียนรู้',
                style: thaiSans(
                    size: context.r(30),
                    weight: FontWeight.w900,
                    color: KColors.navyText)),
            SizedBox(height: context.r(4)),
            Text('ท่าฝึกและเกมการ์ด เพื่อทรงตัวดี ไม่หกล้ม',
                style: thaiSans(
                    size: context.r(14),
                    weight: FontWeight.w600,
                    color: KColors.navyText.withAlpha(150))),
            SizedBox(height: context.r(16)),

            _TodayStrip(
              learned: learned,
              total: total,
              daily: daily,
            ),
            SizedBox(height: context.r(20)),

            KSectionHeader('เลือกสิ่งที่อยากเรียน',
                icon: Icons.school_rounded, color: KColors.learnCardInk),
            SizedBox(height: context.r(10)),

            _FeatureCard(
              title: 'เรียนรู้ท่าฝึก',
              subtitle: 'ท่าบริหารสำหรับผู้สูงอายุ พร้อมภาพและคำอธิบาย',
              icon: Icons.menu_book_rounded,
              gradient: KColors.learnCardGradient,
              ink: KColors.learnCardInk,
              cta: learned == 0 ? 'เริ่มเรียน' : 'เรียนต่อ',
              progress: total == 0 ? 0 : learned / total,
              progressLabel: 'รู้จักแล้ว $learned จาก $total ท่า',
              onTap: () => context.push('/learn'),
            ),
            SizedBox(height: context.r(14)),

            _FeatureCard(
              title: 'การ์ดเรียนรู้',
              subtitle: 'เกมการ์ดสั้น ๆ ทบทวนความรู้เรื่องการทรงตัว',
              icon: Icons.style_rounded,
              gradient: KColors.cardGameGradient,
              ink: KColors.cardGameInk,
              cta: 'เริ่มเล่น',
              progress: daily?.ratio ?? 0,
              progressLabel: daily == null
                  ? 'กำลังโหลด…'
                  : daily.isComplete
                      ? 'ครบเป้าหมายวันนี้แล้ว 🎉'
                      : 'แต้มวันนี้ ${daily.points} จาก ${daily.goal}',
              onTap: _openCardGame,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Today summary ────────────────────────────────────────────────────────────

/// Two flat stat tiles. Kept deliberately plain so the gradient feature cards
/// below stay the loudest thing on the screen.
class _TodayStrip extends StatelessWidget {
  final int learned;
  final int total;
  final DailyProgress? daily;
  const _TodayStrip(
      {required this.learned, required this.total, required this.daily});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: KStatTile(
            value: '$learned/$total',
            label: 'ท่าที่รู้จักแล้ว',
            valueColor: KColors.learnCardInk,
          ),
        ),
        SizedBox(width: context.r(12)),
        Expanded(
          child: KStatTile(
            value: daily == null ? '—' : '${daily!.points}',
            label: 'แต้มการ์ดวันนี้',
            valueColor: KColors.cardGameInk,
          ),
        ),
      ],
    );
  }
}

// ── Feature card ─────────────────────────────────────────────────────────────

/// A large gradient entry card with its own progress line.
///
/// Two instances only, but they must stay pixel-identical apart from colour and
/// copy — that is exactly the case where one widget beats two hand-tuned copies
/// that drift apart on the next edit.
class _FeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final Color ink;
  final String cta;
  final double progress;
  final String progressLabel;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.ink,
    required this.cta,
    required this.progress,
    required this.progressLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        clipBehavior: Clip.hardEdge,
        padding: EdgeInsets.all(context.r(16)),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
                color: ink.withValues(alpha: 0.28),
                blurRadius: 16,
                offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: thaiSans(
                              size: context.r(22),
                              weight: FontWeight.w900,
                              color: Colors.white)),
                      SizedBox(height: context.r(4)),
                      Text(subtitle,
                          style: thaiSans(
                              size: context.r(13),
                              weight: FontWeight.w600,
                              color: Colors.white.withAlpha(225))),
                    ],
                  ),
                ),
                SizedBox(width: context.r(10)),
                // Icon sits in a translucent well rather than plain on the
                // gradient, so it reads at the light end of the ramp too.
                Container(
                  padding: EdgeInsets.all(context.r(10)),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(46),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon,
                      size: context.r(30), color: Colors.white),
                ),
              ],
            ),
            SizedBox(height: context.r(16)),

            // Progress line.
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: context.r(8),
                backgroundColor: Colors.white.withAlpha(64),
                valueColor: const AlwaysStoppedAnimation(Colors.white),
              ),
            ),
            SizedBox(height: context.r(8)),

            Row(
              children: [
                Expanded(
                  child: Text(progressLabel,
                      style: thaiSans(
                          size: context.r(12.5),
                          weight: FontWeight.w700,
                          color: Colors.white.withAlpha(235))),
                ),
                SizedBox(width: context.r(8)),
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: context.r(16), vertical: context.r(8)),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(cta,
                          style: thaiSans(
                              size: context.r(14),
                              weight: FontWeight.w800,
                              color: ink)),
                      SizedBox(width: context.r(4)),
                      Icon(Icons.arrow_forward_rounded,
                          size: context.r(16), color: ink),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
