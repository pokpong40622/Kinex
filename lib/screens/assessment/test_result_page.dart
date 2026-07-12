import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/assessment_session.dart';
import '../../models/assessment_stage.dart';
import '../../models/assessment_test.dart';
import '../../models/test_results.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive.dart';
import '../../widgets/assessment_button.dart';
import '../../widgets/assessment_progress_rail.dart';
import '../../widgets/assessment_scaffold.dart';

/// Shows the result of a single SPPB test: the raw measurement plus the domain
/// points earned (0–4), with options to continue or repeat.
class TestResultPage extends ConsumerWidget {
  final String testId;
  const TestResultPage({super.key, required this.testId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final test = assessmentTestById(testId);
    final session = ref.watch(assessmentSessionProvider);
    final result = session.resultFor(testId);

    if (result == null) {
      return AssessmentScaffold(
        title: test.thaiName,
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(context.r(24)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('ยังไม่มีผลการทดสอบนี้',
                    textAlign: TextAlign.center,
                    style: thaiSans(size: context.r(18), weight: FontWeight.w700)),
                SizedBox(height: context.r(24)),
                AssessmentButton(
                  label: 'กลับไปทำแบบทดสอบ',
                  onTap: () =>
                      context.go('/assessment/test/$testId/instructions'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final (points, valueText) = _describe(result);

    return AssessmentScaffold(
      title: test.thaiName,
      progress: AssessmentProgressRail(
        session: session,
        currentStage: stageIndexForTest(testId),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(context.r(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(valueText,
                  textAlign: TextAlign.center,
                  style: thaiSans(size: context.r(30), weight: FontWeight.w800)),
              SizedBox(height: context.r(20)),
              _PointsBadge(points: points),
            ],
          ),
        ),
      ),
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AssessmentButton(
            label: 'ไปต่อ',
            onTap: () => context.go('/assessment/progress'),
          ),
          SizedBox(height: context.r(12)),
          AssessmentButton(
            label: 'ทำซ้ำ',
            primary: false,
            onTap: () => context.go('/assessment/test/$testId/instructions'),
          ),
        ],
      ),
    );
  }

  /// (points, human-readable measurement) for the given SPPB result.
  (int, String) _describe(Object result) {
    switch (result) {
      case BalanceResult r:
        final held = [r.sideBySideSec, r.semiTandemSec, r.tandemSec]
            .where((s) => s >= 10.0)
            .length;
        return (r.points, 'ยืนทรงตัวผ่าน $held ท่า');
      case GaitResult r:
        return (
          r.points,
          r.unable ? 'เดินไม่ได้' : '${r.seconds.toStringAsFixed(1)} วินาที'
        );
      case ChairStandResult r:
        return (
          r.points,
          !r.preTestPassed
              ? 'ลุกยืนไม่ได้'
              : '${r.seconds.toStringAsFixed(1)} วินาที (5 ครั้ง)'
        );
      default:
        return (0, '');
    }
  }
}

class _PointsBadge extends StatelessWidget {
  final int points;
  const _PointsBadge({required this.points});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: context.r(24), vertical: context.r(12)),
      decoration: BoxDecoration(
        color: KColors.teal.withAlpha(28),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: KColors.teal, width: 2),
      ),
      child: Text('$points / 4 คะแนน',
          style: thaiSans(
              size: context.r(26),
              weight: FontWeight.w900,
              color: KColors.tealDark)),
    );
  }
}
