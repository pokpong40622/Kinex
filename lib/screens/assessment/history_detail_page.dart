import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/assessment_repository.dart';
import '../../models/assessment_record.dart';
import '../../models/assessment_test.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive.dart';
import '../../widgets/assessment_button.dart';
import '../../widgets/assessment_scaffold.dart';
import '../../widgets/bmi_band_badge.dart';
import '../../widgets/fall_risk_cards.dart';

/// Read-only breakdown of a single saved [AssessmentRecord], with a delete
/// action.
class HistoryDetailPage extends ConsumerWidget {
  final String recordId;
  const HistoryDetailPage({super.key, required this.recordId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(assessmentHistoryProvider);

    return AssessmentScaffold(
      title: 'รายละเอียดผลการประเมิน',
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            'เกิดข้อผิดพลาดในการโหลดประวัติ',
            style: thaiSans(size: context.r(16), weight: FontWeight.w700),
          ),
        ),
        data: (records) {
          AssessmentRecord? record;
          for (final r in records) {
            if (r.id == recordId) {
              record = r;
              break;
            }
          }

          if (record == null) {
            return Center(
              child: Text('ไม่พบรายการ', style: thaiSans(size: context.r(18), weight: FontWeight.w700)),
            );
          }

          return _DetailBody(record: record);
        },
      ),
      bottom: AssessmentButton(
        label: 'ลบรายการนี้',
        primary: false,
        onTap: () => _confirmDelete(context, ref),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ลบรายการนี้', style: thaiSans(size: context.r(18), weight: FontWeight.w800)),
        content: Text(
          'ต้องการลบผลการประเมินนี้หรือไม่? การลบไม่สามารถย้อนกลับได้',
          style: thaiSans(size: context.r(16)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('ไม่', style: thaiSans(size: context.r(16), weight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('ยืนยัน',
                style: thaiSans(size: context.r(16), weight: FontWeight.w800, color: KColors.tealDark)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ref.read(assessmentRepositoryProvider).delete(recordId);
    ref.invalidate(assessmentHistoryProvider);

    if (!context.mounted) return;
    context.go('/assessment/history');
  }
}

class _DetailBody extends StatelessWidget {
  final AssessmentRecord record;
  const _DetailBody({required this.record});

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('d MMM yyyy, HH:mm').format(record.dateTime);
    final person = record.person;
    final personLabel = [
      if (person.name != null && person.name!.isNotEmpty) person.name!,
      '${person.age} ปี',
      person.gender.thaiLabel,
    ].join(' · ');

    final gaitValue = record.gait.unable
        ? 'เดินไม่ได้'
        : '${record.gait.seconds.toStringAsFixed(1)} วิ';
    final chairValue = record.chairStand.preTestPassed
        ? '${record.chairStand.seconds.toStringAsFixed(1)} วิ'
        : 'ทำไม่ได้';
    final balanceHeld = [
      record.balance.sideBySideSec,
      record.balance.semiTandemSec,
      record.balance.tandemSec,
    ].where((s) => s >= 10.0).length;

    return ListView(
      padding: EdgeInsets.fromLTRB(context.r(20), context.r(8), context.r(20), context.r(8)),
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: context.r(16), horizontal: context.r(16)),
          decoration: cardDecoration(),
          child: Column(
            children: [
              Text(dateLabel, style: thaiSans(size: context.r(14), weight: FontWeight.w600)),
              SizedBox(height: context.r(4)),
              Text(personLabel, style: thaiSans(size: context.r(16), weight: FontWeight.w700)),
            ],
          ),
        ),
        SizedBox(height: context.r(16)),
        FallRiskHero(total: record.totalScore, risk: record.risk),
        SizedBox(height: context.r(16)),
        _ResultRow(
          label: assessmentTestById('balance').thaiName,
          value: 'ผ่าน $balanceHeld ท่า',
          badge: _PointsChip(record.balance.points),
        ),
        _ResultRow(
          label: assessmentTestById('gait_speed').thaiName,
          value: gaitValue,
          badge: _PointsChip(record.gait.points),
        ),
        _ResultRow(
          label: assessmentTestById('chair_stand').thaiName,
          value: chairValue,
          badge: _PointsChip(record.chairStand.points),
        ),
        SizedBox(height: context.r(8)),
        _ResultRow(label: 'น้ำหนัก', value: '${record.weight.value} กก.'),
        _ResultRow(label: 'ส่วนสูง', value: '${record.height.value} ซม.'),
        _ResultRow(
          label: 'BMI',
          value: record.bmi.value.toStringAsFixed(1),
          badge: BmiBandBadge(record.bmi.band),
        ),
      ],
    );
  }
}

/// Small "X/4" points chip used per SPPB domain.
class _PointsChip extends StatelessWidget {
  final int points;
  const _PointsChip(this.points);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: context.r(12), vertical: context.r(6)),
      decoration: BoxDecoration(
        color: KColors.teal.withAlpha(28),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: KColors.teal, width: 1.4),
      ),
      child: Text('$points/4',
          style: thaiSans(
              size: context.r(15),
              weight: FontWeight.w900,
              color: KColors.tealDark)),
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
      margin: EdgeInsets.only(bottom: context.r(10)),
      padding: EdgeInsets.symmetric(horizontal: context.r(16), vertical: context.r(14)),
      decoration: cardDecoration(radius: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: thaiSans(size: context.r(16), weight: FontWeight.w700)),
          ),
          if (value.isNotEmpty)
            Text(value, style: thaiSans(size: context.r(16), weight: FontWeight.w800)),
          if (value.isNotEmpty && badge != null) SizedBox(width: context.r(10)),
          ?badge,
        ],
      ),
    );
  }
}
