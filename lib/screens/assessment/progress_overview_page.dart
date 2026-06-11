import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/assessment_session.dart';
import '../../models/assessment_stage.dart';
import '../../widgets/assessment_roadmap.dart';
import '../../widgets/assessment_scaffold.dart';
import '../../widgets/assessment_button.dart';

/// Live journey map: shows which stages are done and routes to the next one.
class ProgressOverviewPage extends ConsumerWidget {
  const ProgressOverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(assessmentSessionProvider);
    final current = currentStageIndex(session);
    final bodyDone = session.bmi != null;
    final allDone = session.allMovementTestsComplete && bodyDone;

    void goNext() {
      if (!bodyDone) {
        context.push('/assessment/height');
      } else if (!session.allMovementTestsComplete) {
        context.push(
            '/assessment/test/${session.nextIncompleteTestId}/instructions');
      } else {
        context.push('/assessment/summary');
      }
    }

    return AssessmentScaffold(
      title: 'ความคืบหน้า',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
        children: [
          AssessmentRoadmap(
            session: session,
            onTapCurrent: current < kStages.length ? goNext : null,
          ),
        ],
      ),
      bottom: AssessmentButton(
        label: allDone ? 'ดูสรุปผล' : 'ทำขั้นตอนต่อไป',
        icon: allDone ? Icons.flag_rounded : Icons.arrow_forward_rounded,
        onTap: goNext,
      ),
    );
  }
}
