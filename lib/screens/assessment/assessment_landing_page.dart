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
            SizedBox(height: context.r(12)),
            Text(
              'แบบทดสอบ 9 รายการ ใช้เวลาประมาณ 20–30 นาที '
              'วัดความแข็งแรง ความยืดหยุ่น การทรงตัว และความอดทนของหัวใจ',
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
