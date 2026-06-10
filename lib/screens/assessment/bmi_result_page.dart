import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/assessment_session.dart';
import '../../models/fitness_level.dart';
import '../../theme/app_theme.dart';
import '../../widgets/assessment_button.dart';
import '../../widgets/assessment_scaffold.dart';
import '../../widgets/bmi_band_badge.dart';

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
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'กรุณากรอกน้ำหนักและส่วนสูงก่อน',
                  textAlign: TextAlign.center,
                  style: thaiSans(size: 18, weight: FontWeight.w700),
                ),
                const SizedBox(height: 24),
                AssessmentButton(
                  label: 'ไปกรอกส่วนสูง',
                  onTap: () => context.go('/assessment/height'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return AssessmentScaffold(
      title: 'ดัชนีมวลกาย (BMI)',
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                bmi.value.toStringAsFixed(1),
                style: thaiSans(size: 64, weight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              BmiBandBadge(bmi.band, fontSize: 20),
              const SizedBox(height: 24),
              Text(
                _notes[bmi.band] ?? '',
                textAlign: TextAlign.center,
                style: thaiSans(
                    size: 16,
                    weight: FontWeight.w600,
                    color: KColors.navyText.withAlpha(200)),
              ),
            ],
          ),
        ),
      ),
      bottom: AssessmentButton(
        label: 'ถัดไป',
        onTap: () => context.go('/assessment/progress'),
      ),
    );
  }
}
