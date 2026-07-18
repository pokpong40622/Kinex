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
    (Icons.event_seat_rounded, 'เก้าอี้มั่นคง ไม่มีที่วางแขน'),
    (Icons.straighten_rounded, 'ทางเดิน 4 เมตร'),
    (Icons.people_alt_rounded, 'มีผู้ดูแลคอยประคอง'),
    (Icons.wb_sunny_rounded, 'แสงสว่างพอ'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(assessmentSessionProvider);
    return AssessmentScaffold(
      title: 'แผนการประเมิน',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        children: [
          Text('แบบประเมินการหกล้ม (SPPB) · 4 ขั้นตอน ใช้เวลาประมาณ 10 นาที',
              style: thaiSans(
                  size: 15,
                  weight: FontWeight.w600,
                  color: KColors.navyText.withAlpha(160))),
          const SizedBox(height: 18),
          AssessmentRoadmap(session: session),
          const SizedBox(height: 24),
          _RecordingToggleCard(ref: ref),
          const SizedBox(height: 24),
          Text('สิ่งที่ต้องเตรียม',
              style: thaiSans(size: 16, weight: FontWeight.w800)),
          const SizedBox(height: 12),
          // Fixed 2-column grid instead of a variable-width wrap — the even
          // rhythm is calmer and easier to scan than staggered chip widths.
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.6,
            children: [for (final p in _prep) _PrepChip(icon: p.$1, label: p.$2)],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFB74D).withAlpha(150), width: 1),
            ),
            child: Row(
              children: [
                const Icon(Icons.health_and_safety_rounded,
                    color: Color(0xFFEF6C00)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'ควรมีผู้ดูแลอยู่ข้าง ๆ คอยประคองตลอดการทดสอบ · หากเวียนศีรษะหรือเสียการทรงตัว ให้หยุดพักทันที',
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KColors.hairline, width: 1),
      ),
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
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KColors.hairline, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: KColors.teal,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 19, color: Colors.white),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(label,
                style: thaiSans(size: 13, weight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
