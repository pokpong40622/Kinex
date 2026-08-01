import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/assessment_session.dart';
import '../../models/fitness_level.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive.dart';
import '../../theme/kui.dart';
import '../../widgets/assessment_button.dart';
import '../../widgets/assessment_scaffold.dart';
import '../../widgets/bmi_band_badge.dart';
import '../../widgets/stage_image.dart';

/// Shows the computed BMI value, its band badge and a short Thai note.
class BmiResultPage extends ConsumerWidget {
  const BmiResultPage({super.key});

  static const _notes = {
    BmiBand.phom: 'น้ำหนักของคุณค่อนข้างต่ำกว่าเกณฑ์ ควรรับประทานอาหารให้เพียงพอ',
    BmiBand.pokati: 'น้ำหนักของคุณอยู่ในเกณฑ์ปกติ ดีมาก',
    BmiBand.namnakKoen: 'น้ำหนักของคุณเริ่มเกินเกณฑ์ ควรดูแลอาหารและออกกำลังกายสม่ำเสมอ',
    BmiBand.rokOuan: 'น้ำหนักของคุณอยู่ในเกณฑ์โรคอ้วน ควรปรึกษาแพทย์เพื่อดูแลสุขภาพ',
    BmiBand.rokOuanAntaray:
        'น้ำหนักของคุณอยู่ในเกณฑ์อันตราย ควรปรึกษาแพทย์โดยเร็ว',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bmi = ref.watch(assessmentSessionProvider).bmi;

    if (bmi == null) {
      return AssessmentScaffold(
        title: 'ดัชนีมวลกาย (BMI)',
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(context.r(24)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'กรุณากรอกน้ำหนักและส่วนสูงก่อน',
                  textAlign: TextAlign.center,
                  style: thaiSans(size: context.r(18), weight: FontWeight.w700),
                ),
                SizedBox(height: context.r(24)),
                AssessmentButton(
                  label: 'ไปกรอกส่วนสูง',
                  onTap: () => context.push('/assessment/height'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return AssessmentScaffold(
      title: 'ดัชนีมวลกาย (BMI)',
      stepIndex: 3,
      stepCount: 4,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              context.r(20), context.r(8), context.r(20), context.r(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StageImage(name: 'bmi', height: context.r(112)),
              SizedBox(height: context.r(16)),
              // The number + its band are one result unit — grouped in a card
              // so the reading is unmistakably "the answer", note read below.
              KCard(
                padding: EdgeInsets.symmetric(
                    vertical: context.r(24), horizontal: context.r(20)),
                child: Column(
                  children: [
                    Text('ค่าดัชนีมวลกายของคุณ',
                        style: thaiSans(
                            size: context.r(14),
                            weight: FontWeight.w700,
                            color: KColors.navyText.withAlpha(150))),
                    SizedBox(height: context.r(6)),
                    Text(
                      bmi.value.toStringAsFixed(1),
                      style: thaiSans(size: context.r(64), weight: FontWeight.w800),
                    ),
                    SizedBox(height: context.r(12)),
                    BmiBandBadge(bmi.band, fontSize: context.r(20)),
                  ],
                ),
              ),
              SizedBox(height: context.r(16)),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(context.r(16)),
                decoration: BoxDecoration(
                  color: KColors.teal.withAlpha(18),
                  borderRadius: BorderRadius.circular(context.r(16)),
                  border: Border.all(color: KColors.teal.withAlpha(90), width: 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline_rounded,
                        color: KColors.tealDark, size: context.r(22)),
                    SizedBox(width: context.r(10)),
                    Expanded(
                      child: Text(
                        _notes[bmi.band] ?? '',
                        style: thaiSans(
                            size: context.r(16),
                            weight: FontWeight.w600,
                            color: KColors.navyText.withAlpha(210)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottom: AssessmentButton(
        label: 'ถัดไป',
        onTap: () => context.push('/assessment/progress'),
      ),
    );
  }
}
