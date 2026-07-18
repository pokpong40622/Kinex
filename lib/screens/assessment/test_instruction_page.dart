import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/assessment_session.dart';
import '../../models/assessment_stage.dart';
import '../../models/assessment_test.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive.dart';
import '../../theme/kui.dart';
import '../../widgets/assessment_button.dart';
import '../../widgets/assessment_progress_rail.dart';
import '../../widgets/assessment_scaffold.dart';
import '../../widgets/stage_image.dart';

/// Shows what a movement test involves before the user starts it: name,
/// component, equipment, numbered steps, scoring threshold and a safety note.
class TestInstructionPage extends ConsumerWidget {
  final String testId;
  const TestInstructionPage({super.key, required this.testId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final test = assessmentTestById(testId);
    final session = ref.watch(assessmentSessionProvider);

    return AssessmentScaffold(
      title: test.thaiName,
      progress: AssessmentProgressRail(
        session: session,
        currentStage: stageIndexForTest(testId),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(context.r(20), context.r(4), context.r(20), context.r(8)),
        children: [
          // Hero reference photo with the component name as its caption — the
          // "what am I doing" answer sits right under the picture.
          KCard(
            padding: EdgeInsets.all(context.r(16)),
            child: Column(
              children: [
                StageImage(name: testId, height: context.r(200)),
                SizedBox(height: context.r(12)),
                Text(test.thaiComponent,
                    textAlign: TextAlign.center,
                    style: thaiSans(
                        size: context.r(16),
                        weight: FontWeight.w700,
                        color: KColors.tealDark)),
                if (test.equipment != null) ...[
                  SizedBox(height: context.r(12)),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: context.r(12), vertical: context.r(10)),
                    decoration: BoxDecoration(
                      color: KColors.appBg,
                      borderRadius: BorderRadius.circular(context.r(12)),
                      border: Border.all(color: KColors.hairline, width: 1),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            color: KColors.navyText, size: context.r(20)),
                        SizedBox(width: context.r(10)),
                        Expanded(
                          child: Text(test.equipment!,
                              style: thaiSans(
                                  size: context.r(15), weight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: context.r(18)),
          KSectionHeader('ขั้นตอนการทดสอบ',
              icon: Icons.list_alt_rounded, color: KColors.tealDark),
          SizedBox(height: context.r(4)),
          KCard(
            padding: EdgeInsets.symmetric(
                horizontal: context.r(16), vertical: context.r(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < test.instructions.length; i++)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: context.r(8)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: context.r(30),
                          height: context.r(30),
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: KColors.teal,
                            shape: BoxShape.circle,
                          ),
                          child: Text('${i + 1}',
                              style: thaiSans(
                                  size: context.r(14),
                                  weight: FontWeight.w800,
                                  color: Colors.white)),
                        ),
                        SizedBox(width: context.r(12)),
                        Expanded(
                          child: Text(test.instructions[i],
                              style:
                                  thaiSans(size: context.r(16), weight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: context.r(16)),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(context.r(16)),
            decoration: BoxDecoration(
              color: KColors.teal.withAlpha(18),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: KColors.teal.withAlpha(120), width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: context.r(38),
                  height: context.r(38),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: KColors.teal,
                    borderRadius: BorderRadius.circular(context.r(11)),
                  ),
                  child: Icon(Icons.flag_rounded,
                      color: Colors.white, size: context.r(22)),
                ),
                SizedBox(width: context.r(12)),
                Expanded(
                  child: Text(
                    test.thresholdText,
                    style: thaiSans(
                        size: context.r(15),
                        weight: FontWeight.w700,
                        color: KColors.tealDark),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: context.r(12)),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(context.r(16)),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFB74D).withAlpha(150), width: 1),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Color(0xFFEF6C00), size: context.r(24)),
                SizedBox(width: context.r(12)),
                Expanded(
                  child: Text(
                    'หากเวียนศีรษะหรือเหนื่อยมาก ให้หยุดพักทันที',
                    style: thaiSans(
                        size: context.r(14),
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
        label: 'เริ่มทดสอบ',
        onTap: () => context.push('/assessment/test/$testId/run'),
      ),
    );
  }
}
