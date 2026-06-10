import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/assessment_session.dart';
import '../../models/assessment_test.dart';
import '../../models/fitness_level.dart';
import '../../theme/app_theme.dart';
import '../../widgets/assessment_button.dart';
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
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('ยังไม่มีผลการทดสอบนี้',
                    textAlign: TextAlign.center,
                    style: thaiSans(size: 18, weight: FontWeight.w700)),
                const SizedBox(height: 24),
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (valueText != null) ...[
                Text(valueText, style: thaiSans(size: 64, weight: FontWeight.w900)),
                const SizedBox(height: 16),
              ],
              FitnessLevelBadge(level, fontSize: 28),
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
          const SizedBox(height: 12),
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
