import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/world_repository.dart';
import '../../models/world_session_record.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive.dart';
import '../../widgets/world_scaffold.dart';

/// List of past Kinex World classes, newest first.
class WorldHistoryPage extends ConsumerWidget {
  const WorldHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(worldHistoryProvider);

    return WorldScaffold(
      title: 'ประวัติการเล่น',
      body: history.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (e, _) => Center(
          child: Text('โหลดประวัติไม่สำเร็จ',
              style: thaiSans(color: Colors.white, size: context.r(16))),
        ),
        data: (records) {
          if (records.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(context.r(32)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history_toggle_off_rounded,
                        color: Colors.white54, size: context.r(64)),
                    SizedBox(height: context.r(12)),
                    Text('ยังไม่มีประวัติการเล่น',
                        textAlign: TextAlign.center,
                        style: thaiSans(
                            size: context.r(16),
                            weight: FontWeight.w600,
                            color: Colors.white70)),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: EdgeInsets.fromLTRB(
                context.r(20), context.r(4), context.r(20), context.r(16)),
            itemCount: records.length,
            itemBuilder: (context, i) => _HistoryCard(record: records[i]),
          );
        },
      ),
    );
  }
}

class _HistoryCard extends ConsumerWidget {
  final WorldSessionRecord record;
  const _HistoryCard({required this.record});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final band = WorldBand.of(record.averagePercent);
    return Padding(
      padding: EdgeInsets.only(bottom: context.r(12)),
      child: Dismissible(
        key: ValueKey(record.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: EdgeInsets.only(right: context.r(20)),
          decoration: BoxDecoration(
            color: KColors.pinkDark,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.delete_rounded, color: Colors.white),
        ),
        onDismissed: (_) async {
          await ref.read(worldRepositoryProvider).delete(record.id);
          ref.invalidate(worldHistoryProvider);
        },
        child: GestureDetector(
          onTap: () => context.push('/world/history/${record.id}'),
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: EdgeInsets.all(context.r(16)),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Row(
              children: [
                Container(
                  width: context.r(58),
                  height: context.r(58),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: band.color,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text('${record.averagePercent.toStringAsFixed(0)}%',
                      style: montserrat(
                          size: context.r(18),
                          weight: FontWeight.w900,
                          color: Colors.white)),
                ),
                SizedBox(width: context.r(14)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(record.routineName,
                          style: thaiSans(
                              size: context.r(17),
                              weight: FontWeight.w800,
                              color: Colors.white)),
                      SizedBox(height: context.r(2)),
                      Text(
                          DateFormat('d MMM y · HH:mm')
                              .format(record.dateTime),
                          style: thaiSans(
                              size: context.r(13),
                              weight: FontWeight.w500,
                              color: Colors.white70)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: Colors.white54, size: context.r(26)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
