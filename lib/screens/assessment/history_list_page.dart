import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/assessment_repository.dart';
import '../../models/assessment_record.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive.dart';
import '../../widgets/assessment_button.dart';
import '../../widgets/assessment_scaffold.dart';
import '../../widgets/fitness_level_badge.dart';

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

    return GestureDetector(
      onTap: () => context.push('/assessment/history/${record.id}'),
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: EdgeInsets.only(bottom: context.r(12)),
        padding: EdgeInsets.symmetric(horizontal: context.r(16), vertical: context.r(14)),
        decoration: cardDecoration(radius: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dateLabel, style: thaiSans(size: context.r(16), weight: FontWeight.w800)),
                  SizedBox(height: context.r(4)),
                  Text(
                    personLabel,
                    style: thaiSans(
                        size: context.r(14), weight: FontWeight.w600, color: KColors.navyText.withAlpha(160)),
                  ),
                ],
              ),
            ),
            FitnessLevelBadge(record.overall, fontSize: context.r(16)),
          ],
        ),
      ),
    );
  }
}
