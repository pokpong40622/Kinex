import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/assessment_repository.dart';
import '../../data/assessment_session.dart';
import '../../models/assessment_record.dart';
import '../../models/assessment_test.dart';
import '../../models/fitness_level.dart';
import '../../services/fitness_scoring.dart';
import '../../theme/app_theme.dart';
import '../../widgets/assessment_button.dart';
import '../../widgets/assessment_scaffold.dart';
import '../../widgets/bmi_band_badge.dart';
import '../../widgets/fitness_level_badge.dart';

/// Final summary of a completed assessment, with a save action that persists
/// the [AssessmentRecord] and resets the in-progress session.
class FinalSummaryPage extends ConsumerWidget {
  const FinalSummaryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(assessmentSessionProvider);

    final weight = session.weight;
    final height = session.height;
    final bmi = session.bmi;
    final person = session.person;

    if (!session.allMovementTestsComplete ||
        weight == null ||
        height == null ||
        bmi == null ||
        person == null) {
      return AssessmentScaffold(
        title: 'สรุปผลการประเมิน',
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'การประเมินยังไม่ครบ',
                  textAlign: TextAlign.center,
                  style: thaiSans(size: 18, weight: FontWeight.w700),
                ),
                const SizedBox(height: 24),
                AssessmentButton(
                  label: 'ไปหน้าความคืบหน้า',
                  onTap: () => context.go('/assessment/progress'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final overall = FitnessScoring.computeOverall([
      session.backScratch!.level,
      session.sitAndReach!.level,
      session.armCurl!.level,
      session.chairStand!.level,
      session.stepTest!.level,
      session.tug!.level,
    ]);

    return AssessmentScaffold(
      title: 'สรุปผลการประเมิน',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        children: [
          _OverallHero(overall: overall),
          const SizedBox(height: 16),
          _ResultRow(
            label: 'น้ำหนัก',
            value: '${weight.value} กก.',
          ),
          _ResultRow(
            label: 'ส่วนสูง',
            value: '${height.value} ซม.',
          ),
          _ResultRow(
            label: 'BMI',
            value: bmi.value.toStringAsFixed(1),
            badge: BmiBandBadge(bmi.band),
          ),
          _ResultRow(
            label: assessmentTestById('back_scratch').thaiName,
            value: '',
            badge: FitnessLevelBadge(session.backScratch!.level),
          ),
          _ResultRow(
            label: assessmentTestById('sit_reach').thaiName,
            value: '',
            badge: FitnessLevelBadge(session.sitAndReach!.level),
          ),
          _ResultRow(
            label: assessmentTestById('arm_curl').thaiName,
            value: '${session.armCurl!.reps} ครั้ง',
            badge: FitnessLevelBadge(session.armCurl!.level),
          ),
          _ResultRow(
            label: assessmentTestById('chair_stand').thaiName,
            value: '${session.chairStand!.reps} ครั้ง',
            badge: FitnessLevelBadge(session.chairStand!.level),
          ),
          _ResultRow(
            label: assessmentTestById('step_test').thaiName,
            value: '${session.stepTest!.reps} ครั้ง',
            badge: FitnessLevelBadge(session.stepTest!.level),
          ),
          _ResultRow(
            label: assessmentTestById('tug').thaiName,
            value: '${session.tug!.seconds.toStringAsFixed(2)} วินาที',
            badge: FitnessLevelBadge(session.tug!.level),
          ),
        ],
      ),
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AssessmentButton(
            label: 'บันทึกผล',
            onTap: () => _save(context, ref, session, overall),
          ),
          const SizedBox(height: 12),
          AssessmentButton(
            label: 'ยกเลิก',
            primary: false,
            onTap: () => _confirmCancel(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _save(
    BuildContext context,
    WidgetRef ref,
    AssessmentSession session,
    FitnessLevel overall,
  ) async {
    final record = AssessmentRecord(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      dateTime: DateTime.now(),
      person: session.person!,
      weight: session.weight!,
      height: session.height!,
      bmi: session.bmi!,
      backScratch: session.backScratch!,
      sitAndReach: session.sitAndReach!,
      armCurl: session.armCurl!,
      chairStand: session.chairStand!,
      stepTest: session.stepTest!,
      tug: session.tug!,
      overall: overall,
    );

    await ref.read(assessmentRepositoryProvider).add(record);
    ref.read(assessmentSessionProvider.notifier).reset();
    ref.invalidate(assessmentHistoryProvider);

    if (!context.mounted) return;
    context.go('/assessment/history');
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ยกเลิกการประเมิน', style: thaiSans(size: 18, weight: FontWeight.w800)),
        content: Text(
          'ผลการประเมินที่ยังไม่บันทึกจะหายไปทั้งหมด ต้องการยกเลิกหรือไม่?',
          style: thaiSans(size: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('ไม่', style: thaiSans(size: 16, weight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('ยืนยัน',
                style: thaiSans(size: 16, weight: FontWeight.w800, color: KColors.tealDark)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    ref.read(assessmentSessionProvider.notifier).reset();

    if (!context.mounted) return;
    context.go('/home');
  }
}

/// Big hero card showing the overall verdict.
class _OverallHero extends StatelessWidget {
  final FitnessLevel overall;
  const _OverallHero({required this.overall});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: cardDecoration(),
      child: Column(
        children: [
          Text('ผลการประเมินโดยรวม',
              style: thaiSans(size: 18, weight: FontWeight.w800)),
          const SizedBox(height: 12),
          FitnessLevelBadge(overall, fontSize: 28),
          const SizedBox(height: 8),
          Text(
            'เกณฑ์รวมของ Kinex (ไม่ใช่จากคู่มือ)',
            textAlign: TextAlign.center,
            style: thaiSans(
                size: 13, weight: FontWeight.w600, color: KColors.navyText.withAlpha(160)),
          ),
        ],
      ),
    );
  }
}

/// One row of the results list: a label, a raw value, and an optional badge.
class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final Widget? badge;

  const _ResultRow({required this.label, required this.value, this.badge});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: cardDecoration(radius: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: thaiSans(size: 16, weight: FontWeight.w700)),
          ),
          if (value.isNotEmpty)
            Text(value, style: thaiSans(size: 16, weight: FontWeight.w800)),
          if (value.isNotEmpty && badge != null) const SizedBox(width: 10),
          ?badge,
        ],
      ),
    );
  }
}
