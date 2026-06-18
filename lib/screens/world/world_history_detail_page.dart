import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/world_repository.dart';
import '../../models/world_session_record.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive.dart';
import '../../widgets/world_scaffold.dart';
import '../../widgets/world_result_view.dart';

/// A past class, loaded by id and rendered with the shared result view.
class WorldHistoryDetailPage extends ConsumerWidget {
  final String recordId;
  const WorldHistoryDetailPage({super.key, required this.recordId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return WorldScaffold(
      title: 'ผลการเล่น',
      body: FutureBuilder<WorldSessionRecord?>(
        future: ref.read(worldRepositoryProvider).byId(recordId),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.white));
          }
          final record = snap.data;
          if (record == null) {
            return Center(
              child: Text('ไม่พบข้อมูลนี้',
                  style: thaiSans(color: Colors.white, size: context.r(16))),
            );
          }
          return WorldResultView(record: record);
        },
      ),
    );
  }
}
