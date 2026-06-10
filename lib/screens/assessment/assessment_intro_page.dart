import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/assessment_scaffold.dart';
import '../../widgets/assessment_button.dart';

/// Overview of the 9 tests and what the user needs to prepare, shown before
/// the assessment begins.
class AssessmentIntroPage extends StatelessWidget {
  const AssessmentIntroPage({super.key});

  static const _tests = [
    '1. ชั่งน้ำหนัก',
    '2. วัดส่วนสูง',
    '3. คำนวณดัชนีมวลกาย (BMI)',
    '4. แตะมือด้านหลัง (ความยืดหยุ่นไหล่)',
    '5. นั่งเก้าอี้แตะปลายเท้า (ความยืดหยุ่นหลัง-ขา)',
    '6. งอแขนยกน้ำหนัก 30 วินาที',
    '7. ลุกยืน-นั่งบนเก้าอี้ 30 วินาที',
    '8. ยืนยกเข่าขึ้นลง 2 นาที',
    '9. ลุก-เดิน-นั่ง ไปกลับ (TUG)',
  ];

  static const _needs = [
    ('🪑', 'เก้าอี้ที่มั่นคง (สูงประมาณ 43 ซม.)'),
    ('📏', 'พื้นที่ว่างประมาณ 3 เมตร'),
    ('🏋️', 'ดัมเบลหรือขวดน้ำ (หญิง 2.3 กก. / ชาย 3.6 กก.)'),
    ('🧑‍🤝‍🧑', 'ผู้ช่วยอยู่ใกล้ ๆ เพื่อความปลอดภัย'),
  ];

  @override
  Widget build(BuildContext context) {
    return AssessmentScaffold(
      title: 'ก่อนเริ่มการประเมิน',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        children: [
          _SectionCard(
            title: 'รายการทดสอบ 9 รายการ',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _tests
                  .map((t) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(t,
                            style: thaiSans(
                                size: 16, weight: FontWeight.w600)),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'สิ่งที่ต้องเตรียม',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _needs
                  .map((n) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(n.$1, style: const TextStyle(fontSize: 22)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(n.$2,
                                  style: thaiSans(
                                      size: 16, weight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFB74D), width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Color(0xFFEF6C00)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'หากรู้สึกเวียนศีรษะหรือเหนื่อยมาก ให้หยุดพักทันที '
                    'และจับพนักเก้าอี้เพื่อป้องกันการหกล้ม',
                    style: thaiSans(
                        size: 14,
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
        onTap: () => context.go('/assessment/person'),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
              color: Color(0x18000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: thaiSans(
                  size: 18, weight: FontWeight.w800, color: KColors.tealDark)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
