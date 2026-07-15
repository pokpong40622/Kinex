import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive.dart';
import '../../widgets/assessment_scaffold.dart';
import '../../widgets/assessment_button.dart';

/// Entry screen for the fitness-assessment module: start a new assessment or
/// review past results. (History is wired in a later phase.)
class AssessmentLandingPage extends StatelessWidget {
  const AssessmentLandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AssessmentScaffold(
      title: 'ประเมินสมรรถภาพทางกาย',
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: context.r(20)),
        child: Column(
          children: [
            SizedBox(height: context.r(24)),
            Container(
              width: context.r(120),
              height: context.r(120),
              decoration: const BoxDecoration(
                color: Color(0xFFD7EFE9),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.monitor_heart_rounded,
                  size: context.r(64), color: KColors.tealDark),
            ),
            SizedBox(height: context.r(24)),
            Text(
              'การประเมินสมรรถภาพทางกายในผู้สูงอายุ',
              textAlign: TextAlign.center,
              style: thaiSans(size: context.r(20), weight: FontWeight.w800),
            ),
            SizedBox(height: context.r(10)),
            // Instrument reference badge — professional credibility line.
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: context.r(14), vertical: context.r(8)),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF8F5),
                borderRadius: BorderRadius.circular(context.r(14)),
                border: Border.all(
                    color: KColors.tealDark.withAlpha(90),
                    width: context.r(1.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_rounded,
                      size: context.r(18), color: KColors.tealDark),
                  SizedBox(width: context.r(8)),
                  Flexible(
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
            SizedBox(height: context.r(12)),
            Text(
              'การทดสอบ SPPB 3 รายการ (การทรงตัว · ความเร็วการเดิน · '
              'ลุก-นั่งเก้าอี้) พร้อมวัดค่า BMI ใช้เวลาประมาณ 10 นาที',
              textAlign: TextAlign.center,
              style: thaiSans(
                  size: context.r(15),
                  weight: FontWeight.w500,
                  color: KColors.navyText.withAlpha(180)),
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
            onTap: () => context.push('/assessment/intro'),
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
