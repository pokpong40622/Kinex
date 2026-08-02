// The "you did it" screen shown after the live camera coach reports the pose
// finished (Unity's `coach_done`). It is a full-screen view rather than a route
// so the Unity surface underneath is never torn down and rebuilt just to show a
// result — the user can tap ฝึกอีกครั้ง and go straight back into the same
// session.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/pose_library.dart';
import '../../state/learn_progress.dart';
import '../../theme/app_theme.dart';
import '../../theme/kui.dart';
import '../../theme/responsive.dart';

/// Congratulation screen for one finished pose.
///
/// Shows what was just achieved (pose name + how much was done) and, more
/// importantly, where it sits in the collection: "ฝึกสำเร็จแล้ว X / 9 ท่า".
/// The count comes from [posePracticedProvider], which the coach screen has
/// already updated by the time this is built.
class PoseSuccessView extends ConsumerWidget {
  final LearnPose pose;

  /// Reps banked. In `hold` mode this is the number of completed holds.
  final int reps;

  /// 'reps' or 'hold' — only changes the wording of the summary chip.
  final String mode;

  final VoidCallback onExit;
  final VoidCallback onRetry;

  const PoseSuccessView({
    super.key,
    required this.pose,
    required this.reps,
    required this.mode,
    required this.onExit,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = pose.category.color;
    final practiced = ref.watch(posePracticedProvider);
    final total = poseLibrary.length;
    final done = poseLibrary.where((p) => practiced.contains(p.id)).length;
    final allDone = done >= total;

    return Material(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withAlpha(38), KColors.appBg],
            stops: const [0, 0.55],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: context.r(24)),
                  child: Column(
                    children: [
                      SizedBox(height: context.r(24)),
                      _Medal(color: color),
                      SizedBox(height: context.r(22)),
                      Text(
                        allDone ? 'ครบทุกท่าแล้ว!' : 'ยอดเยี่ยม!',
                        style: thaiSans(
                          size: context.r(32),
                          weight: FontWeight.w900,
                          color: color,
                        ),
                      ),
                      SizedBox(height: context.r(8)),
                      Text(
                        'ฝึกท่านี้สำเร็จแล้ว',
                        style: thaiSans(
                          size: context.r(15),
                          weight: FontWeight.w600,
                          color: KColors.navyText.withAlpha(160),
                        ),
                      ),
                      SizedBox(height: context.r(18)),
                      _PoseNameCard(pose: pose, reps: reps, mode: mode),
                      SizedBox(height: context.r(16)),
                      _CollectionProgress(
                        done: done,
                        total: total,
                        color: color,
                      ),
                      SizedBox(height: context.r(24)),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  context.r(24),
                  0,
                  context.r(24),
                  context.r(20),
                ),
                child: Column(
                  children: [
                    _PrimaryButton(
                      label: 'เสร็จสิ้น',
                      icon: Icons.check_rounded,
                      color: color,
                      onTap: onExit,
                    ),
                    SizedBox(height: context.r(10)),
                    _SecondaryButton(
                      label: 'ฝึกอีกครั้ง',
                      icon: Icons.refresh_rounded,
                      color: color,
                      onTap: onRetry,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Check badge that springs in once. Two soft rings behind it so the badge
/// reads as an award rather than as a plain status icon.
class _Medal extends StatelessWidget {
  final Color color;
  const _Medal({required this.color});

  @override
  Widget build(BuildContext context) {
    final size = context.r(132);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 650),
      curve: Curves.elasticOut,
      builder: (context, t, child) =>
          Transform.scale(scale: 0.4 + 0.6 * t, child: child),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            _ring(size, color.withAlpha(20)),
            _ring(size * 0.78, color.withAlpha(38)),
            Container(
              width: size * 0.56,
              height: size * 0.56,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(
                Icons.emoji_events_rounded,
                color: Colors.white,
                size: size * 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ring(double d, Color c) => Container(
        width: d,
        height: d,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      );
}

/// What was just completed — name, category, and the amount done.
class _PoseNameCard extends StatelessWidget {
  final LearnPose pose;
  final int reps;
  final String mode;
  const _PoseNameCard({
    required this.pose,
    required this.reps,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    final color = pose.category.color;
    return KCard(
      radius: context.r(20),
      padding: EdgeInsets.all(context.r(18)),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: context.r(48),
                height: context.r(48),
                decoration: BoxDecoration(
                  color: color.withAlpha(24),
                  borderRadius: BorderRadius.circular(context.r(14)),
                  border: Border.all(color: color.withAlpha(70)),
                ),
                child: Icon(pose.icon, color: color, size: context.r(25)),
              ),
              SizedBox(width: context.r(13)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pose.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: thaiSans(
                        size: context.r(17),
                        weight: FontWeight.w800,
                        color: KColors.navyText,
                      ),
                    ),
                    SizedBox(height: context.r(3)),
                    Text(
                      pose.category.thaiShort,
                      style: thaiSans(
                        size: context.r(12.5),
                        weight: FontWeight.w600,
                        color: KColors.navyText.withAlpha(150),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (reps > 0) ...[
            SizedBox(height: context.r(14)),
            Row(
              children: [
                Icon(
                  mode == 'hold'
                      ? Icons.timer_rounded
                      : Icons.repeat_rounded,
                  size: context.r(17),
                  color: color,
                ),
                SizedBox(width: context.r(7)),
                Text(
                  mode == 'hold' ? 'ค้างครบ $reps รอบ' : 'ทำได้ $reps ครั้ง',
                  style: thaiSans(
                    size: context.r(14),
                    weight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// "ฝึกสำเร็จแล้ว X / N ท่า" — the collection view of progress, so finishing one
/// pose visibly moves a bar the user wants to fill.
class _CollectionProgress extends StatelessWidget {
  final int done;
  final int total;
  final Color color;
  const _CollectionProgress({
    required this.done,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : done / total;
    final left = total - done;
    return KCard(
      radius: context.r(20),
      padding: EdgeInsets.all(context.r(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ฝึกสำเร็จแล้ว',
                      style: thaiSans(
                        size: context.r(15),
                        weight: FontWeight.w800,
                        color: KColors.navyText,
                      ),
                    ),
                    SizedBox(height: context.r(2)),
                    Text(
                      left <= 0 ? 'ครบทุกท่าแล้ว เก่งมาก' : 'เหลืออีก $left ท่า',
                      style: thaiSans(
                        size: context.r(12.5),
                        weight: FontWeight.w500,
                        color: KColors.navyText.withAlpha(150),
                      ),
                    ),
                  ],
                ),
              ),
              // The "1 / 9" read-out the whole screen is built around.
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$done',
                    style: thaiSans(
                      size: context.r(30),
                      weight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                  Text(
                    ' / $total ท่า',
                    style: thaiSans(
                      size: context.r(14),
                      weight: FontWeight.w700,
                      color: KColors.navyText.withAlpha(150),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: context.r(13)),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: pct),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: context.r(10),
                backgroundColor: color.withAlpha(28),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Filled full-width action. Shared by this screen and the wizard's "try it"
/// call to action so both read as the same kind of primary control.
class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        height: context.r(58),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(context.r(29)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.28),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: context.r(24)),
            SizedBox(width: context.r(8)),
            Text(
              label,
              style: thaiSans(
                size: context.r(19),
                weight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _SecondaryButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        height: context.r(52),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(context.r(26)),
          border: Border.all(color: color.withAlpha(90), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: context.r(21)),
            SizedBox(width: context.r(8)),
            Text(
              label,
              style: thaiSans(
                size: context.r(16),
                weight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
