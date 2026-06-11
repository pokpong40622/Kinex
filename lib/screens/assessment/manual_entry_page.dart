import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/assessment_session.dart';
import '../../models/assessment_stage.dart';
import '../../models/assessment_test.dart';
import '../../models/fitness_level.dart';
import '../../models/test_results.dart';
import '../../services/fitness_scoring.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive.dart';
import '../../widgets/assessment_button.dart';
import '../../widgets/assessment_progress_rail.dart';
import '../../widgets/assessment_scaffold.dart';
import '../../widgets/big_number_pad.dart';

/// Manual result entry, branching on the test's [TestMethod]:
///  - manualStopwatch (TUG): in-app stopwatch.
///  - manualChoice (back_scratch/sit_reach): three illustrated outcome buttons.
///  - camera (fallback): a number pad for the rep count.
class ManualEntryPage extends ConsumerStatefulWidget {
  final String testId;
  const ManualEntryPage({super.key, required this.testId});

  @override
  ConsumerState<ManualEntryPage> createState() => _ManualEntryPageState();
}

class _ManualEntryPageState extends ConsumerState<ManualEntryPage> {
  // Stopwatch state (manualStopwatch)
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _ticker;
  Duration _elapsed = Duration.zero;

  // Choice state (manualChoice)
  FitnessLevel? _selectedLevel;

  // Number pad state (camera fallback)
  double? _reps;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final test = assessmentTestById(widget.testId);

    final session = ref.watch(assessmentSessionProvider);

    return AssessmentScaffold(
      title: test.thaiName,
      progress: AssessmentProgressRail(
        session: session,
        currentStage: stageIndexForTest(widget.testId),
      ),
      body: _bodyFor(test),
      bottom: _bottomFor(test),
    );
  }

  // ---------------------------------------------------------------------
  // Layout routing
  // ---------------------------------------------------------------------

  /// TUG always uses the stopwatch regardless of its TestMethod.
  /// arm_curl / chair_stand / step_test (camera) use the number pad.
  Widget _bodyFor(AssessmentTest test) {
    if (widget.testId == 'tug') return _stopwatchBody();
    return switch (test.method) {
      TestMethod.manualStopwatch => _stopwatchBody(),
      TestMethod.manualChoice => _choiceBody(),
      TestMethod.camera => _numberPadBody(),
    };
  }

  Widget? _bottomFor(AssessmentTest test) {
    if (widget.testId == 'tug') {
      return AssessmentButton(
        label: 'บันทึกผล',
        onTap: !_stopwatch.isRunning && _elapsed > Duration.zero
            ? _submitStopwatch
            : null,
      );
    }
    return switch (test.method) {
      TestMethod.manualStopwatch => AssessmentButton(
          label: 'บันทึกผล',
          onTap: !_stopwatch.isRunning && _elapsed > Duration.zero
              ? _submitStopwatch
              : null,
        ),
      TestMethod.manualChoice => AssessmentButton(
          label: 'บันทึกผล',
          onTap: _selectedLevel == null ? null : _submitChoice,
        ),
      TestMethod.camera => AssessmentButton(
          label: 'บันทึกผล',
          onTap: _reps == null ? null : _submitReps,
        ),
    };
  }

  // ---------------------------------------------------------------------
  // Stopwatch (TUG)
  // ---------------------------------------------------------------------

  void _toggleStopwatch() {
    setState(() {
      if (_stopwatch.isRunning) {
        _stopwatch.stop();
        _ticker?.cancel();
        _elapsed = _stopwatch.elapsed;
      } else {
        _stopwatch.start();
        _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
          setState(() => _elapsed = _stopwatch.elapsed);
        });
      }
    });
  }

  void _resetStopwatch() {
    setState(() {
      _ticker?.cancel();
      _stopwatch.reset();
      _elapsed = Duration.zero;
    });
  }

  void _submitStopwatch() {
    final seconds = _elapsed.inMilliseconds / 1000.0;
    final level = FitnessScoring.tugLevel(seconds);
    ref
        .read(assessmentSessionProvider.notifier)
        .setMovementResult(widget.testId, TimedResult(seconds, level));
    context.pushReplacement('/assessment/test/${widget.testId}/result');
  }

  Widget _stopwatchBody() {
    final minutes = _elapsed.inMinutes.remainder(60);
    final seconds = _elapsed.inSeconds.remainder(60);
    final tenths = (_elapsed.inMilliseconds ~/ 100).remainder(10);
    final display =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.$tenths';

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(display,
              style: thaiSans(size: context.r(72), weight: FontWeight.w900)),
          SizedBox(height: context.r(32)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: AssessmentButton(
                  label: _stopwatch.isRunning ? 'หยุด' : 'เริ่ม',
                  onTap: _toggleStopwatch,
                ),
              ),
              SizedBox(width: context.r(16)),
              Expanded(
                child: AssessmentButton(
                  label: 'รีเซ็ต',
                  primary: false,
                  onTap: _stopwatch.isRunning ? null : _resetStopwatch,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Choice (back_scratch / sit_reach)
  // ---------------------------------------------------------------------

  void _submitChoice() {
    final level = _selectedLevel;
    if (level == null) return;
    ref
        .read(assessmentSessionProvider.notifier)
        .setMovementResult(widget.testId, BestOfTwoResult(level));
    context.pushReplacement('/assessment/test/${widget.testId}/result');
  }

  Widget _choiceBody() {
    final options = widget.testId == 'back_scratch'
        ? const [
            (FitnessLevel.dimak, 'ปลายนิ้วทับซ้อนกัน', Icons.join_inner),
            (FitnessLevel.di, 'แตะกันพอดี', Icons.join_full),
            (FitnessLevel.siang, 'แตะไม่ถึง', Icons.join_left),
          ]
        : const [
            (FitnessLevel.dimak, 'เลยปลายเท้า', Icons.arrow_circle_down),
            (FitnessLevel.di, 'แตะถึงปลายเท้า', Icons.check_circle_outline),
            (FitnessLevel.siang, 'แตะไม่ถึง', Icons.remove_circle_outline),
          ];

    return ListView(
      padding: EdgeInsets.fromLTRB(context.r(20), context.r(8), context.r(20), context.r(8)),
      children: [
        Text('ลองทำท่าด้วยตัวเอง แล้วเลือกผลที่ตรงกับคุณ',
            textAlign: TextAlign.center,
            style: thaiSans(
                size: context.r(15),
                weight: FontWeight.w600,
                color: KColors.tealDark)),
        SizedBox(height: context.r(8)),
        Text('เลือกผลลัพธ์ที่ตรงกับคุณ',
            textAlign: TextAlign.center,
            style: thaiSans(size: context.r(16), weight: FontWeight.w700)),
        SizedBox(height: context.r(16)),
        for (final option in options)
          Padding(
            padding: EdgeInsets.symmetric(vertical: context.r(8)),
            child: _ChoiceCard(
              icon: option.$3,
              label: option.$2,
              selected: _selectedLevel == option.$1,
              onTap: () => setState(() => _selectedLevel = option.$1),
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Number pad fallback (arm_curl / chair_stand / step_test)
  // ---------------------------------------------------------------------

  void _submitReps() {
    final reps = _reps;
    if (reps == null) return;
    final repsInt = reps.toInt();
    final level = switch (widget.testId) {
      'arm_curl' => FitnessScoring.armCurlLevel(repsInt),
      'chair_stand' => FitnessScoring.chairStandLevel(repsInt),
      'step_test' => FitnessScoring.stepLevel(repsInt),
      _ => FitnessScoring.armCurlLevel(repsInt),
    };
    ref
        .read(assessmentSessionProvider.notifier)
        .setMovementResult(widget.testId, RepCountResult(repsInt, level));
    context.pushReplacement('/assessment/test/${widget.testId}/result');
  }

  Widget _numberPadBody() {
    return Center(
      child: BigNumberPad(
        unit: 'ครั้ง',
        min: 0,
        max: 200,
        onChanged: (v) => setState(() => _reps = v),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.all(context.r(18)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? KColors.teal : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: const [
            BoxShadow(
                color: Color(0x18000000), blurRadius: 10, offset: Offset(0, 3)),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: context.r(40), color: KColors.tealDark),
            SizedBox(width: context.r(16)),
            Expanded(
              child: Text(label, style: thaiSans(size: context.r(18), weight: FontWeight.w800)),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              size: context.r(24),
              color: selected ? KColors.teal : KColors.navyText.withAlpha(100),
            ),
          ],
        ),
      ),
    );
  }
}
