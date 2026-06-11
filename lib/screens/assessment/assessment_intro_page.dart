import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/assessment_session.dart';
import '../../data/recording_pref.dart';
import '../../theme/app_theme.dart';
import '../../widgets/assessment_roadmap.dart';
import '../../widgets/assessment_scaffold.dart';
import '../../widgets/assessment_button.dart';

/// The assessment "plan" — a visual journey map of the 5 stages plus a short
/// prep checklist, shown before the user begins.
class AssessmentIntroPage extends ConsumerWidget {
  const AssessmentIntroPage({super.key});

  static const _prep = [
    (Icons.event_seat_rounded, 'เก้าอี้มั่นคง'),
    (Icons.straighten_rounded, 'พื้นที่ ~3 เมตร'),
    (Icons.fitness_center_rounded, 'ดัมเบล/ขวดน้ำ'),
    (Icons.wb_sunny_rounded, 'แสงสว่างพอ'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(assessmentSessionProvider);
    return AssessmentScaffold(
      title: 'แผนการประเมิน',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
        children: [
          Text('5 ขั้นตอน ใช้เวลาประมาณ 20–30 นาที',
              style: thaiSans(
                  size: 15,
                  weight: FontWeight.w600,
                  color: KColors.navyText.withAlpha(160))),
          const SizedBox(height: 16),
          AssessmentRoadmap(session: session),
          const SizedBox(height: 20),
          _RecordingToggleCard(ref: ref),
          const SizedBox(height: 16),
          Text('สิ่งที่ต้องเตรียม',
              style: thaiSans(size: 16, weight: FontWeight.w800)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [for (final p in _prep) _PrepChip(icon: p.$1, label: p.$2)],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.health_and_safety_rounded,
                    color: Color(0xFFEF6C00)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'หากเวียนศีรษะหรือเหนื่อยมาก ให้หยุดพักทันที',
                    style: thaiSans(
                        size: 13.5,
                        weight: FontWeight.w600,
                        color: const Color(0xFFB23C00)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottom: AssessmentButton(
        label: 'เริ่มเลย',
        icon: Icons.arrow_forward_rounded,
        onTap: () => context.push('/assessment/person'),
      ),
    );
  }
}

class _RecordingToggleCard extends StatelessWidget {
  final WidgetRef ref;
  const _RecordingToggleCard({required this.ref});

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(recordingEnabledProvider);
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        secondary: Icon(
          Icons.videocam_rounded,
          color: enabled ? KColors.tealDark : KColors.navyText.withAlpha(120),
        ),
        title: Text('บันทึกวิดีโอการทดสอบ',
            style: thaiSans(size: 15, weight: FontWeight.w700)),
        subtitle: Text(
          'บันทึกวิดีโอขณะทำท่าที่ใช้กล้อง แล้วเก็บไว้ในแกลเลอรี',
          style: thaiSans(
              size: 12.5,
              weight: FontWeight.w500,
              color: KColors.navyText.withAlpha(160)),
        ),
        value: enabled,
        activeThumbColor: KColors.tealDark,
        onChanged: (_) => ref.read(recordingEnabledProvider.notifier).toggle(),
      ),
    );
  }
}

class _PrepChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _PrepChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
              color: Color(0x12000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: KColors.tealDark),
          const SizedBox(width: 8),
          Text(label, style: thaiSans(size: 14, weight: FontWeight.w700)),
        ],
      ),
    );
  }
}
