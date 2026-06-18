import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/world_routine.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive.dart';
import '../../widgets/world_scaffold.dart';
import '../../widgets/world_button.dart';

/// Class overview: the exercises in order + a safety / camera-setup card, then
/// "Start". The trainer leads on a fixed timeline and never waits.
class WorldOverviewPage extends StatelessWidget {
  final String routineId;
  const WorldOverviewPage({super.key, required this.routineId});

  @override
  Widget build(BuildContext context) {
    final routine = worldRoutineById(routineId);
    if (routine == null) {
      return WorldScaffold(
        title: 'ไม่พบคลาส',
        body: Center(
          child: Text('ไม่พบคลาสนี้',
              style: thaiSans(color: Colors.white, size: context.r(16))),
        ),
      );
    }

    final needsFullBody = routine.exercises.any((e) => e.legsRequired);

    return WorldScaffold(
      title: routine.thaiName,
      bottom: WorldButton(
        label: 'เริ่มคลาส',
        icon: Icons.play_arrow_rounded,
        onTap: () => context.push('/world/game/${routine.id}'),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            context.r(20), context.r(4), context.r(20), context.r(12)),
        children: [
          _SafetyCard(needsFullBody: needsFullBody),
          SizedBox(height: context.r(18)),
          Text('ท่าในคลาสนี้',
              style: thaiSans(
                  size: context.r(18),
                  weight: FontWeight.w800,
                  color: Colors.white)),
          SizedBox(height: context.r(10)),
          ...routine.exercises.asMap().entries.map(
              (e) => _ExerciseRow(index: e.key + 1, exercise: e.value)),
        ],
      ),
    );
  }
}

class _SafetyCard extends StatelessWidget {
  final bool needsFullBody;
  const _SafetyCard({required this.needsFullBody});

  @override
  Widget build(BuildContext context) {
    final tips = <(IconData, String)>[
      (Icons.event_seat_rounded, 'เตรียมเก้าอี้มั่นคงไว้ใกล้ตัว'),
      (Icons.crop_free_rounded, 'มีพื้นที่ว่างรอบตัวประมาณ 1.5 เมตร'),
      (Icons.wb_sunny_rounded, 'แสงสว่างเพียงพอ ไม่ย้อนแสง'),
      if (needsFullBody)
        (Icons.accessibility_new_rounded,
            'มีท่ายืน — วางแท็บเล็ตให้เห็นทั้งตัว (ถอยห่าง ~2 ม.)'),
    ];

    return Container(
      padding: EdgeInsets.all(context.r(18)),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.health_and_safety_rounded,
                  color: KColors.greenLight, size: context.r(22)),
              SizedBox(width: context.r(8)),
              Text('เตรียมพร้อมก่อนเริ่ม',
                  style: thaiSans(
                      size: context.r(16),
                      weight: FontWeight.w800,
                      color: Colors.white)),
            ],
          ),
          SizedBox(height: context.r(12)),
          ...tips.map((t) => Padding(
                padding: EdgeInsets.only(bottom: context.r(8)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(t.$1, color: Colors.white70, size: context.r(18)),
                    SizedBox(width: context.r(10)),
                    Expanded(
                      child: Text(t.$2,
                          style: thaiSans(
                              size: context.r(14),
                              weight: FontWeight.w500,
                              color: Colors.white)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  final int index;
  final WorldExerciseDef exercise;
  const _ExerciseRow({required this.index, required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.r(10)),
      child: Container(
        padding: EdgeInsets.all(context.r(14)),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: context.r(34),
              height: context.r(34),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: exercise.category.color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$index',
                  style: montserrat(
                      size: context.r(16),
                      weight: FontWeight.w900,
                      color: Colors.white)),
            ),
            SizedBox(width: context.r(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(exercise.thaiName,
                      style: thaiSans(
                          size: context.r(16),
                          weight: FontWeight.w700,
                          color: Colors.white)),
                  SizedBox(height: context.r(2)),
                  Row(
                    children: [
                      Text(exercise.category.thaiLabel,
                          style: thaiSans(
                              size: context.r(12),
                              weight: FontWeight.w700,
                              color: exercise.category.color)),
                      Text('  •  ${exercise.durationSeconds} วิ',
                          style: thaiSans(
                              size: context.r(12),
                              weight: FontWeight.w500,
                              color: Colors.white70)),
                      if (exercise.legsRequired) ...[
                        SizedBox(width: context.r(6)),
                        Icon(Icons.accessibility_new_rounded,
                            color: Colors.white54, size: context.r(14)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
