import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/assessment_session.dart';
import '../../models/test_results.dart';
import '../../services/fitness_scoring.dart';
import '../../widgets/assessment_button.dart';
import '../../widgets/assessment_scaffold.dart';
import '../../widgets/big_number_pad.dart';
import '../../widgets/stage_image.dart';

/// Collects the person's weight (kg) via [BigNumberPad], then computes BMI
/// from the previously-entered height.
class WeightInputPage extends ConsumerStatefulWidget {
  const WeightInputPage({super.key});

  @override
  ConsumerState<WeightInputPage> createState() => _WeightInputPageState();
}

class _WeightInputPageState extends ConsumerState<WeightInputPage> {
  double? _value;

  @override
  Widget build(BuildContext context) {
    final initial = ref.read(assessmentSessionProvider).weight?.value;

    return AssessmentScaffold(
      title: 'น้ำหนัก',
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const StageImage(name: 'body', height: 120),
          const SizedBox(height: 8),
          BigNumberPad(
            unit: 'กก.',
            min: 20,
            max: 200,
            allowDecimal: true,
            initial: initial,
            onChanged: (v) => setState(() => _value = v),
          ),
        ],
      ),
      bottom: AssessmentButton(
        label: 'ถัดไป',
        onTap: _value == null ? null : _submit,
      ),
    );
  }

  void _submit() {
    final value = _value;
    if (value == null) return;

    final notifier = ref.read(assessmentSessionProvider.notifier);
    final height = ref.read(assessmentSessionProvider).height;
    if (height == null) {
      context.push('/assessment/height');
      return;
    }

    final bmi = FitnessScoring.computeBmi(
      weightKg: value,
      heightMeters: height.value / 100,
    );
    notifier.setWeight(MeasurementResult(value, 'kg'));
    notifier.setBmi(BmiResult(bmi, FitnessScoring.bmiBand(bmi)));
    context.push('/assessment/bmi');
  }
}
