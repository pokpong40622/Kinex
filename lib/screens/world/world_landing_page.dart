import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/world_routine.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive.dart';
import '../../widgets/world_scaffold.dart';
import '../../widgets/world_button.dart';

/// Kinex World entry — pick a class. Vertical slice ships one routine; the list
/// scales as more routines are added to [worldRoutines].
class WorldLandingPage extends StatelessWidget {
  const WorldLandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return WorldScaffold(
      title: 'Kinex World',
      bottom: WorldButton(
        label: 'ประวัติการเล่น',
        icon: Icons.history_rounded,
        primary: false,
        onTap: () => context.push('/world/history'),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            context.r(20), context.r(4), context.r(20), context.r(12)),
        children: [
          Text('ออกกำลังกายไปกับผู้ฝึก',
              style: thaiSans(
                  size: context.r(20),
                  weight: FontWeight.w800,
                  color: Colors.white)),
          SizedBox(height: context.r(4)),
          Text('เลือกคลาสที่อยากเล่น แล้วทำตามผู้ฝึกไปพร้อมกัน',
              style: thaiSans(
                  size: context.r(14),
                  weight: FontWeight.w500,
                  color: Colors.white70)),
          SizedBox(height: context.r(16)),
          ...worldRoutines.map((r) => _RoutineCard(routine: r)),
        ],
      ),
    );
  }
}

class _RoutineCard extends StatelessWidget {
  final WorldRoutineDef routine;
  const _RoutineCard({required this.routine});

  @override
  Widget build(BuildContext context) {
    final minutes = (routine.totalSeconds / 60).ceil();
    return Padding(
      padding: EdgeInsets.only(bottom: context.r(14)),
      child: GestureDetector(
        onTap: () => context.push('/world/overview/${routine.id}'),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: EdgeInsets.all(context.r(18)),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: context.r(54),
                    height: context.r(54),
                    decoration: BoxDecoration(
                      gradient: KColors.purpleRadial,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.self_improvement_rounded,
                        color: Colors.white, size: context.r(30)),
                  ),
                  SizedBox(width: context.r(14)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(routine.thaiName,
                            style: thaiSans(
                                size: context.r(20),
                                weight: FontWeight.w800,
                                color: Colors.white)),
                        Text(routine.englishName,
                            style: montserrat(
                                size: context.r(13),
                                weight: FontWeight.w600,
                                color: Colors.white70)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: Colors.white70, size: context.r(28)),
                ],
              ),
              SizedBox(height: context.r(12)),
              Text(routine.description,
                  style: thaiSans(
                      size: context.r(13),
                      weight: FontWeight.w500,
                      color: Colors.white70)),
              SizedBox(height: context.r(12)),
              Row(
                children: [
                  _Chip(icon: Icons.timer_outlined, label: '~$minutes นาที'),
                  SizedBox(width: context.r(10)),
                  _Chip(
                      icon: Icons.fitness_center_rounded,
                      label: '${routine.exerciseCount} ท่า'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: context.r(12), vertical: context.r(6)),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: context.r(16)),
          SizedBox(width: context.r(6)),
          Text(label,
              style: thaiSans(
                  size: context.r(13),
                  weight: FontWeight.w700,
                  color: Colors.white)),
        ],
      ),
    );
  }
}
