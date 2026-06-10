import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/assessment_test.dart';
import '../../theme/app_theme.dart';
import '../../widgets/assessment_button.dart';
import '../../widgets/assessment_scaffold.dart';

/// Shows what a movement test involves before the user starts it: name,
/// component, equipment, numbered steps, scoring threshold and a safety note.
class TestInstructionPage extends StatelessWidget {
  final String testId;
  const TestInstructionPage({super.key, required this.testId});

  @override
  Widget build(BuildContext context) {
    final test = assessmentTestById(testId);

    return AssessmentScaffold(
      title: test.thaiName,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        children: [
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(test.thaiComponent,
                    style: thaiSans(
                        size: 16,
                        weight: FontWeight.w700,
                        color: KColors.tealDark)),
                if (test.equipment != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.inventory_2_outlined,
                          color: KColors.navyText, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(test.equipment!,
                            style: thaiSans(size: 16, weight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'ขั้นตอนการทดสอบ',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < test.instructions.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: KColors.teal,
                            shape: BoxShape.circle,
                          ),
                          child: Text('${i + 1}',
                              style: thaiSans(
                                  size: 14,
                                  weight: FontWeight.w800,
                                  color: Colors.white)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(test.instructions[i],
                              style:
                                  thaiSans(size: 16, weight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: KColors.teal.withAlpha(28),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: KColors.teal, width: 1.5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.flag_outlined, color: KColors.tealDark),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    test.thresholdText,
                    style: thaiSans(
                        size: 15,
                        weight: FontWeight.w700,
                        color: KColors.tealDark),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
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
                    'หากเวียนศีรษะหรือเหนื่อยมาก ให้หยุดพักทันที',
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
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AssessmentButton(
            label: 'เริ่มทดสอบ',
            onTap: () => context.go(test.method == TestMethod.camera
                ? '/assessment/test/$testId/calibrate'
                : '/assessment/test/$testId/manual'),
          ),
          if (test.method == TestMethod.camera) ...[
            const SizedBox(height: 12),
            AssessmentButton(
              label: 'ป้อนผลด้วยตนเอง',
              primary: false,
              onTap: () => context.go('/assessment/test/$testId/manual'),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String? title;
  final Widget child;
  const _SectionCard({this.title, required this.child});

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
          if (title != null) ...[
            Text(title!,
                style: thaiSans(
                    size: 18, weight: FontWeight.w800, color: KColors.tealDark)),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}
