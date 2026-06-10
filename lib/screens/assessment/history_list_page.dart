import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/assessment_repository.dart';
import '../../models/assessment_record.dart';
import '../../theme/app_theme.dart';
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
      onBack: () => context.go('/assessment'),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            'เกิดข้อผิดพลาดในการโหลดประวัติ',
            style: thaiSans(size: 16, weight: FontWeight.w700),
          ),
        ),
        data: (records) {
          if (records.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'ยังไม่มีประวัติการประเมิน',
                      textAlign: TextAlign.center,
                      style: thaiSans(size: 18, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 24),
                    AssessmentButton(
                      label: 'เริ่มการประเมินใหม่',
                      onTap: () => context.go('/assessment/intro'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
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
      onTap: () => context.go('/assessment/history/${record.id}'),
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: cardDecoration(radius: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dateLabel, style: thaiSans(size: 16, weight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(
                    personLabel,
                    style: thaiSans(
                        size: 14, weight: FontWeight.w600, color: KColors.navyText.withAlpha(160)),
                  ),
                ],
              ),
            ),
            FitnessLevelBadge(record.overall),
          ],
        ),
      ),
    );
  }
}
