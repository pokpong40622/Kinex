import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/assessment_session.dart';
import '../../state/assessment_profile.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive.dart';
import '../../theme/kui.dart';
import '../../widgets/assessment_scaffold.dart';
import '../../widgets/assessment_button.dart';

/// Entry screen for the fitness-assessment module: start a new assessment or
/// review past results. (History is wired in a later phase.)
class AssessmentLandingPage extends ConsumerWidget {
  const AssessmentLandingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AssessmentScaffold(
      title: 'ประเมินสมรรถภาพทางกาย',
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            context.r(20), context.r(28), context.r(20), context.r(8)),
        child: Column(
          children: [
            // Hero badge floats above the card, like a friendly avatar.
            Container(
              width: context.r(88),
              height: context.r(88),
              decoration: const BoxDecoration(
                color: KColors.teal,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.monitor_heart_rounded,
                  size: context.r(46), color: Colors.white),
            ),
            SizedBox(height: context.r(20)),
            // Everything the user needs to decide "should I start" lives in
            // one calm card, instead of loose floating text blocks.
            KCard(
              padding: EdgeInsets.all(context.r(22)),
              child: Column(
                children: [
                  Text(
                    'การประเมินสมรรถภาพทางกายในผู้สูงอายุ',
                    textAlign: TextAlign.center,
                    style: thaiSans(size: context.r(21), weight: FontWeight.w800),
                  ),
                  SizedBox(height: context.r(18)),
                  Text(
                    'การทดสอบ SPPB 3 รายการ (การทรงตัว · ความเร็วการเดิน · '
                    'ลุก-นั่งเก้าอี้) พร้อมวัดค่า BMI ใช้เวลาประมาณ 10 นาที',
                    textAlign: TextAlign.center,
                    style: thaiSans(
                        size: context.r(16),
                        weight: FontWeight.w500,
                        color: KColors.navyText.withAlpha(190)),
                  ),
                  SizedBox(height: context.r(18)),
                  // Instrument reference badge — professional credibility line.
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                        horizontal: context.r(14), vertical: context.r(10)),
                    decoration: BoxDecoration(
                      color: KColors.teal.withAlpha(20),
                      borderRadius: BorderRadius.circular(context.r(14)),
                      border: Border.all(
                          color: KColors.tealDark.withAlpha(70), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_rounded,
                            size: context.r(18), color: KColors.tealDark),
                        SizedBox(width: context.r(8)),
                        Expanded(
                          child: Text(
                            'อ้างอิงแบบประเมินมาตรฐานสากล\n'
                            'Short Physical Performance Battery (SPPB)',
                            textAlign: TextAlign.center,
                            style: thaiSans(
                                size: context.r(12.5),
                                weight: FontWeight.w700,
                                color: KColors.tealDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AssessmentButton(
            label: 'เริ่มการประเมินใหม่',
            icon: Icons.play_arrow_rounded,
            onTap: () {
              // Prefill this assessment from the last saved profile (name/age/
              // gender/height/weight) so returning users don't retype them.
              ref
                  .read(assessmentSessionProvider.notifier)
                  .seedFrom(ref.read(savedProfileProvider));
              context.push('/assessment/intro');
            },
          ),
          SizedBox(height: context.r(12)),
          AssessmentButton(
            label: 'ดูประวัติการประเมิน',
            primary: false,
            icon: Icons.history_rounded,
            onTap: () => context.push('/assessment/history'),
          ),
        ],
      ),
    );
  }
}
