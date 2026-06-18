import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/world_routine.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive.dart';
import '../../widgets/game_start_screen.dart';

/// Single hero entry page for Kinex World, replacing the two-screen
/// (WorldLandingPage → WorldOverviewPage) flow.
///
/// Shows the daily_class routine data — move count + duration — and
/// launches directly into /world/game/daily_class.
class WorldHeroPage extends StatelessWidget {
  const WorldHeroPage({super.key});

  static const _routineId = 'daily_class';

  @override
  Widget build(BuildContext context) {
    final routine = worldRoutineById(_routineId);
    final minutes =
        routine != null ? (routine.totalSeconds / 60).ceil() : 3;
    final moveCount = routine?.exerciseCount ?? 5;
    final thaiName = routine?.thaiName ?? 'คลาสประจำวัน';

    final tagline = '$thaiName  ·  $moveCount ท่า · ~$minutes นาที';

    return GameStartScreen(
      title: 'Kinex\nWorld',
      tagline: tagline,
      accentGradient: KColors.purpleRadial,
      art: Icon(
        Icons.self_improvement_rounded,
        size: context.r(80),
        color: Colors.white.withAlpha(180),
      ),
      tipText: 'ยืนห่างจอ ~1.5 ม. ให้กล้องเห็นทั้งตัว  •  แสงสว่างเพียงพอ',
      startLabel: 'เริ่ม / START',
      onStart: () => context.go('/world/game/$_routineId'),
      onBack: () => context.go('/home'),
      secondaryLabel: 'ดูประวัติการเล่น',
      onSecondary: () => context.go('/world/history'),
    );
  }
}
