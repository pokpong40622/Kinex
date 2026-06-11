import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/assessment_session.dart';
import '../../models/assessment_stage.dart';
import '../../models/assessment_test.dart';
import '../../models/fitness_level.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive.dart';
import '../../widgets/assessment_button.dart';
import '../../widgets/assessment_progress_rail.dart';
import '../../widgets/assessment_scaffold.dart';
import '../../widgets/fitness_level_badge.dart';

/// Shows the result of a single movement test: the raw measurement (if any)
/// plus its [FitnessLevel] badge, with options to continue or repeat.
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
                  onTap: () => context.go('/assessment/test/$testId/instructions'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final level = (result as dynamic).level as FitnessLevel;
    final valueText = switch (test.method) {
      TestMethod.camera => '${(result as dynamic).reps} ครั้ง',
      TestMethod.manualStopwatch =>
        '${((result as dynamic).seconds as double).toStringAsFixed(2)} วินาที',
      TestMethod.manualChoice => null,
    };

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
              if (valueText != null) ...[
                Text(valueText, style: thaiSans(size: context.r(64), weight: FontWeight.w900)),
                SizedBox(height: context.r(16)),
              ],
              FitnessLevelBadge(level, fontSize: context.r(28)),
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
}
