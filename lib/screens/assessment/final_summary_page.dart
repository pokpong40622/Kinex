import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/assessment_repository.dart';
import '../../data/assessment_session.dart';
import '../../models/assessment_record.dart';
import '../../models/assessment_test.dart';
import '../../models/fall_risk.dart';
import '../../models/fitness_level.dart';
import '../../services/sppb_scoring.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive.dart';
import '../../theme/kui.dart';
import '../../widgets/assessment_button.dart';
import '../../widgets/assessment_scaffold.dart';
import '../../widgets/bmi_band_badge.dart';
import '../../widgets/fall_risk_cards.dart';

/// Final summary of a completed SPPB assessment: the 0–12 total + fall-risk
/// verdict, the three interpretation cards, per-domain point rows and BMI, with
/// a save action that persists the record and resets the session.
class FinalSummaryPage extends ConsumerWidget {
  const FinalSummaryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(assessmentSessionProvider);

    final weight = session.weight;
    final height = session.height;
    final bmi = session.bmi;
    final person = session.person;
    final balance = session.balance;
    final gait = session.gait;
    final chairStand = session.chairStand;

    if (!session.allMovementTestsComplete ||
        weight == null ||
        height == null ||
        bmi == null ||
        person == null ||
        balance == null ||
        gait == null ||
        chairStand == null) {
      return AssessmentScaffold(
        title: 'สรุปผลการประเมิน',
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(context.r(24)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'การประเมินยังไม่ครบ',
                  textAlign: TextAlign.center,
                  style: thaiSans(size: context.r(18), weight: FontWeight.w700),
                ),
                SizedBox(height: context.r(24)),
                AssessmentButton(
                  label: 'ไปหน้าความคืบหน้า',
                  onTap: () => context.push('/assessment/progress'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final total = SppbScoring.total(
      balance: balance.points,
      gait: gait.points,
      chairStand: chairStand.points,
    );
    final risk = SppbScoring.riskBand(total);

    return AssessmentScaffold(
      title: 'สรุปผลการประเมิน',
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            context.r(20), context.r(8), context.r(20), context.r(8)),
        children: [
          FallRiskHero(total: total, risk: risk),
          SizedBox(height: context.r(18)),
          // The three domain scores + BMI read as one breakdown table inside a
          // single card, rather than four separate floating rows.
          KCard(
            padding: EdgeInsets.symmetric(
                horizontal: context.r(16), vertical: context.r(6)),
            child: Column(
              children: [
                _DomainRow(
                  label: assessmentTestById('balance').thaiName,
                  value:
                      'ผ่าน ${[balance.sideBySideSec, balance.semiTandemSec, balance.tandemSec].where((s) => s >= 10.0).length} ท่า',
                  points: balance.points,
                ),
                const _RowDivider(),
                _DomainRow(
                  label: assessmentTestById('gait_speed').thaiName,
                  value: gait.unable
                      ? 'เดินไม่ได้'
                      : '${gait.seconds.toStringAsFixed(1)} วิ',
                  points: gait.points,
                ),
                const _RowDivider(),
                _DomainRow(
                  label: assessmentTestById('chair_stand').thaiName,
                  value: chairStand.preTestPassed
                      ? '${chairStand.seconds.toStringAsFixed(1)} วิ'
                      : 'ทำไม่ได้',
                  points: chairStand.points,
                ),
                const _RowDivider(),
                _BmiRow(bmiValue: bmi.value, band: bmi.band),
              ],
            ),
          ),
          SizedBox(height: context.r(20)),
          Text('การแปลผลคะแนนและความเสี่ยงในการหกล้ม',
              style: thaiSans(size: context.r(16), weight: FontWeight.w800)),
          SizedBox(height: context.r(12)),
          FallRiskCards(active: risk),
        ],
      ),
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AssessmentButton(
            label: 'บันทึกผล',
            onTap: () => _save(context, ref, session, total, risk),
          ),
          SizedBox(height: context.r(12)),
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
    int total,
    FallRisk risk,
  ) async {
    final record = AssessmentRecord(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      dateTime: DateTime.now(),
      person: session.person!,
      weight: session.weight!,
      height: session.height!,
      bmi: session.bmi!,
      balance: session.balance!,
      gait: session.gait!,
      chairStand: session.chairStand!,
      totalScore: total,
      risk: risk,
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
        title: Text('ยกเลิกการประเมิน',
            style: thaiSans(size: context.r(18), weight: FontWeight.w800)),
        content: Text(
          'ผลการประเมินที่ยังไม่บันทึกจะหายไปทั้งหมด ต้องการยกเลิกหรือไม่?',
          style: thaiSans(size: context.r(16)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('ไม่',
                style: thaiSans(size: context.r(16), weight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('ยืนยัน',
                style: thaiSans(
                    size: context.r(16),
                    weight: FontWeight.w800,
                    color: KColors.tealDark)),
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

/// Hairline separator between the grouped breakdown rows.
class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, thickness: 1, color: KColors.hairline);
}

/// One SPPB domain row: label, optional raw value, and a "X/4" points chip.
class _DomainRow extends StatelessWidget {
  final String label;
  final String value;
  final int points;

  const _DomainRow(
      {required this.label, required this.value, required this.points});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.r(14)),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: thaiSans(size: context.r(16), weight: FontWeight.w700)),
          ),
          if (value.isNotEmpty) ...[
            Text(value,
                style: thaiSans(size: context.r(15), weight: FontWeight.w700)),
            SizedBox(width: context.r(10)),
          ],
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: context.r(13), vertical: context.r(7)),
            decoration: BoxDecoration(
              color: KColors.teal,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text('$points/4',
                style: thaiSans(
                    size: context.r(15),
                    weight: FontWeight.w900,
                    color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _BmiRow extends StatelessWidget {
  final double bmiValue;
  final BmiBand band;
  const _BmiRow({required this.bmiValue, required this.band});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.r(14)),
      child: Row(
        children: [
          Expanded(
            child: Text('BMI (รายงานแยก ไม่รวมในคะแนน)',
                style: thaiSans(size: context.r(15), weight: FontWeight.w700)),
          ),
          Text(bmiValue.toStringAsFixed(1),
              style: thaiSans(size: context.r(16), weight: FontWeight.w800)),
          SizedBox(width: context.r(10)),
          BmiBandBadge(band),
        ],
      ),
    );
  }
}
