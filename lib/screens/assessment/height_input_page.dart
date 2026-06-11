import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/assessment_session.dart';
import '../../models/test_results.dart';
import '../../widgets/assessment_button.dart';
import '../../widgets/assessment_scaffold.dart';
import '../../widgets/big_number_pad.dart';
import '../../widgets/stage_image.dart';

/// Collects the person's height (cm) via [BigNumberPad].
class HeightInputPage extends ConsumerStatefulWidget {
  const HeightInputPage({super.key});

  @override
  ConsumerState<HeightInputPage> createState() => _HeightInputPageState();
}

class _HeightInputPageState extends ConsumerState<HeightInputPage> {
  double? _value;

  @override
  Widget build(BuildContext context) {
    final initial = ref.read(assessmentSessionProvider).height?.value;

    return AssessmentScaffold(
      title: 'ส่วนสูง',
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const StageImage(name: 'body', height: 120),
          const SizedBox(height: 8),
          BigNumberPad(
          unit: 'ซม.',
          min: 80,
          max: 220,
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
    ref
        .read(assessmentSessionProvider.notifier)
        .setHeight(MeasurementResult(value, 'cm'));
    context.push('/assessment/weight');
  }
}
