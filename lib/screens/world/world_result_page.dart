import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/world_session_record.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive.dart';
import '../../widgets/world_scaffold.dart';
import '../../widgets/world_button.dart';
import '../../widgets/world_result_view.dart';

/// Post-class results. The record is already persisted by WorldGameScreen and
/// passed here via GoRouter `extra`.
class WorldResultPage extends StatelessWidget {
  final WorldSessionRecord? record;
  const WorldResultPage({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final r = record;
    if (r == null) {
      return WorldScaffold(
        title: 'ผลการเล่น',
        onBack: () => context.go('/home'),
        body: Center(
          child: Text('ไม่มีข้อมูลผลการเล่น',
              style: thaiSans(color: Colors.white, size: context.r(16))),
        ),
      );
    }

    return WorldScaffold(
      title: 'จบคลาสแล้ว!',
      onBack: () => context.go('/home'),
      bottom: Row(
        children: [
          Expanded(
            child: WorldButton(
              label: 'ดูประวัติ',
              primary: false,
              onTap: () => context.go('/world/history'),
            ),
          ),
          SizedBox(width: context.r(12)),
          Expanded(
            child: WorldButton(
              label: 'เสร็จสิ้น',
              onTap: () => context.go('/home'),
            ),
          ),
        ],
      ),
      body: WorldResultView(record: r),
    );
  }
}
