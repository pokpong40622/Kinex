import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/assessment_repository.dart';
import '../../models/assessment_record.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive.dart';
import '../../theme/kui.dart';
import '../../widgets/assessment_button.dart';
import '../../widgets/assessment_scaffold.dart';
import '../../widgets/fall_risk_cards.dart';

/// List of past assessments, newest first. Tapping a card opens its detail.
class HistoryListPage extends ConsumerWidget {
  const HistoryListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(assessmentHistoryProvider);

    return AssessmentScaffold(
      title: 'ประวัติการประเมิน',
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            'เกิดข้อผิดพลาดในการโหลดประวัติ',
            style: thaiSans(size: context.r(16), weight: FontWeight.w700),
          ),
        ),
        data: (records) {
          if (records.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(context.r(24)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'ยังไม่มีประวัติการประเมิน',
                      textAlign: TextAlign.center,
                      style: thaiSans(size: context.r(18), weight: FontWeight.w700),
                    ),
                    SizedBox(height: context.r(24)),
                    AssessmentButton(
                      label: 'เริ่มการประเมินใหม่',
                      onTap: () => context.push('/assessment/intro'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.fromLTRB(context.r(20), context.r(8), context.r(20), context.r(8)),
            itemCount: records.length,
            itemBuilder: (context, index) =>
                _HistoryCard(record: records[index]),
          );
        },
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final AssessmentRecord record;
  const _HistoryCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('d MMM yyyy, HH:mm').format(record.dateTime);
    final person = record.person;
    final personLabel = [
      if (person.name != null && person.name!.isNotEmpty) person.name!,
      '${person.age} ปี',
    ].join(' · ');

    return Padding(
      padding: EdgeInsets.only(bottom: context.r(12)),
      child: KCard(
        radius: 16,
        onTap: () => context.push('/assessment/history/${record.id}'),
        padding: EdgeInsets.symmetric(
            horizontal: context.r(16), vertical: context.r(16)),
        child: Row(
          children: [
            // Big score block leads — it is the number people scan for.
            SizedBox(
              width: context.r(58),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${record.totalScore}',
                      style: thaiSans(
                          size: context.r(30),
                          weight: FontWeight.w900,
                          color: KColors.tealDark)),
                  Text('/ 12',
                      style: thaiSans(
                          size: context.r(12),
                          weight: FontWeight.w700,
                          color: KColors.navyText.withAlpha(140))),
                ],
              ),
            ),
            SizedBox(width: context.r(14)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dateLabel,
                      style: thaiSans(
                          size: context.r(16), weight: FontWeight.w800)),
                  SizedBox(height: context.r(4)),
                  Text(
                    personLabel,
                    style: thaiSans(
                        size: context.r(14),
                        weight: FontWeight.w600,
                        color: KColors.navyText.withAlpha(160)),
                  ),
                  SizedBox(height: context.r(8)),
                  FallRiskBadge(record.risk, fontSize: context.r(13)),
                ],
              ),
            ),
            SizedBox(width: context.r(8)),
            Icon(Icons.chevron_right_rounded,
                color: KColors.navyText.withAlpha(90), size: context.r(26)),
          ],
        ),
      ),
    );
  }
}
