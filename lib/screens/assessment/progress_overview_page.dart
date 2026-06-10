import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/assessment_session.dart';
import '../../models/assessment_test.dart';
import '../../models/fitness_level.dart';
import '../../widgets/assessment_button.dart';
import '../../widgets/assessment_scaffold.dart';
import '../../widgets/fitness_level_badge.dart';
import '../../widgets/step_progress_tracker.dart';

/// Shows the full 9-step progress (intake + 6 movement tests) and routes to
/// whatever comes next.
class ProgressOverviewPage extends ConsumerWidget {
  const ProgressOverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(assessmentSessionProvider);
    final intakeComplete =
        session.weight != null && session.height != null && session.bmi != null;

    final items = <StepItem>[
      StepItem(
        label: 'ชั่งน้ำหนัก',
        status: session.weight != null
            ? StepStatus.done
            : StepStatus.current,
      ),
      StepItem(
        label: 'วัดส่วนสูง',
        status: session.height != null
            ? StepStatus.done
            : (session.weight != null ? StepStatus.current : StepStatus.pending),
      ),
      StepItem(
        label: 'BMI',
        status: session.bmi != null
            ? StepStatus.done
            : (session.weight != null && session.height != null
                ? StepStatus.current
                : StepStatus.pending),
      ),
      for (final t in kMovementTests)
        StepItem(
          label: t.thaiName,
          status: _statusFor(session, t.id, intakeComplete),
          trailing: _trailingFor(session, t.id),
        ),
    ];

    return AssessmentScaffold(
      title: 'ความคืบหน้าการประเมิน',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        children: [
          StepProgressTracker(items: items),
        ],
      ),
      bottom: _bottomButton(context, session, intakeComplete),
    );
  }

  StepStatus _statusFor(AssessmentSession session, String testId, bool intakeComplete) {
    if (session.resultFor(testId) != null) return StepStatus.done;
    if (intakeComplete && session.nextIncompleteTestId == testId) {
      return StepStatus.current;
    }
    return StepStatus.pending;
  }

  Widget? _trailingFor(AssessmentSession session, String testId) {
    final result = session.resultFor(testId);
    if (result == null) return null;
    final level = (result as dynamic).level as FitnessLevel;
    return FitnessLevelBadge(level);
  }

  Widget _bottomButton(BuildContext context, AssessmentSession session, bool intakeComplete) {
    if (!intakeComplete) {
      return AssessmentButton(
        label: 'ทำแบบทดสอบต่อไป',
        onTap: () => context.go('/assessment/height'),
      );
    }
    if (!session.allMovementTestsComplete) {
      return AssessmentButton(
        label: 'ทำแบบทดสอบต่อไป',
        onTap: () => context
            .go('/assessment/test/${session.nextIncompleteTestId}/instructions'),
      );
    }
    return AssessmentButton(
      label: 'ดูสรุปผล',
      onTap: () => context.go('/assessment/summary'),
    );
  }
}
