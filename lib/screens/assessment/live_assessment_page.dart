import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/assessment_session.dart';
import '../../data/recording_pref.dart';
import '../../models/assessment_stage.dart';
import '../../models/assessment_test.dart';
import '../../models/test_results.dart';
import '../../rep_counters/pose_frame.dart';
import '../../rep_counters/rep_counter.dart';
import '../../rep_counters/rep_counter_factory.dart';
import '../../services/fitness_scoring.dart';
import '../../services/recording_service.dart';
import '../../services/tts_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/assessment_button.dart';
import '../../widgets/assessment_progress_rail.dart';
import '../../widgets/assessment_scaffold.dart';
import '../../widgets/pose_camera_view.dart';
import 'tug_live_page.dart';

enum _Phase { ready, countdown, counting, done }

/// THE core camera test screen. Opens the camera ONCE for the whole test:
/// a "ready" phase (position + capture baseline) → countdown → timed counting.
/// Entered directly from the instruction screen so only one camera is ever open.
class LiveAssessmentPage extends ConsumerStatefulWidget {
  final String testId;
  const LiveAssessmentPage({super.key, required this.testId});

  @override
  ConsumerState<LiveAssessmentPage> createState() => _LiveAssessmentPageState();
}

class _LiveAssessmentPageState extends ConsumerState<LiveAssessmentPage> {
  late final RepCounter _counter;
  late final AssessmentTest _test;

  _Phase _phase = _Phase.ready;
  int _countdown = 3;
  int _secondsLeft = 0;
  Timer? _timer;
  bool _recordingStarted = false;

  bool _bodyOk = false;

  @override
  void initState() {
    super.initState();
    if (widget.testId == 'tug') return; // delegated to TugLivePage in build()
    _test = assessmentTestById(widget.testId);
    _counter = createRepCounter(widget.testId);
    _secondsLeft = _test.durationSeconds;
  }

  /// Key landmarks that must be visible for the camera angle to be "OK".
  List<int> get _requiredLandmarks {
    switch (widget.testId) {
      case 'step_test':
        return const [Lm.leftHip, Lm.rightHip, Lm.rightKnee];
      case 'arm_curl':
        return const [
          Lm.leftShoulder,
          Lm.rightShoulder,
          Lm.leftElbow,
          Lm.rightElbow
        ];
      default: // chair_stand + fallback
        return const [Lm.leftShoulder, Lm.rightShoulder, Lm.leftHip, Lm.rightHip];
    }
  }

  bool get _readyToStart =>
      _bodyOk && (!_counter.needsCalibration || _counter.isCalibrated);

  void _startCountdown() {
    setState(() {
      _phase = _Phase.countdown;
      _countdown = 3;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (_countdown > 1) {
          _countdown--;
        } else {
          _timer?.cancel();
          _startCounting();
        }
      });
    });
  }

  void _startCounting() {
    _phase = _Phase.counting;
    if (ref.read(recordingEnabledProvider)) {
      _recordingStarted = true;
      ref.read(recordingServiceProvider).start(widget.testId);
    }
    ref.read(ttsServiceProvider).speak('เริ่ม');
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (_secondsLeft > 1) {
          _secondsLeft--;
          if (_secondsLeft == 10) {
            ref.read(ttsServiceProvider).speak('เหลือสิบวินาที');
          }
        } else {
          _secondsLeft = 0;
          _timer?.cancel();
          ref.read(ttsServiceProvider).speak('หมดเวลา');
          _finish();
        }
      });
    });
  }

  void _onFrame(PoseFrame frame) {
    switch (_phase) {
      case _Phase.ready:
        _bodyOk = frame.allVisible(_requiredLandmarks);
        if (_counter.needsCalibration) _counter.calibrate(frame);
        setState(() {});
      case _Phase.counting:
        final before = _counter.reps;
        _counter.add(frame);
        if (_counter.reps > before) {
          ref.read(ttsServiceProvider).speak('${_counter.reps}');
        }
        setState(() {});
      case _Phase.countdown:
      case _Phase.done:
        break;
    }
  }

  void _finish() {
    if (_phase == _Phase.done) return;
    _phase = _Phase.done;
    if (_recordingStarted) {
      _recordingStarted = false;
      ref.read(recordingServiceProvider).stopAndSave();
    }
    final reps = _counter.reps;
    final level = switch (widget.testId) {
      'arm_curl' => FitnessScoring.armCurlLevel(reps),
      'chair_stand' => FitnessScoring.chairStandLevel(reps),
      'step_test' => FitnessScoring.stepLevel(reps),
      _ => FitnessScoring.armCurlLevel(reps),
    };
    ref
        .read(assessmentSessionProvider.notifier)
        .setMovementResult(widget.testId, RepCountResult(reps, level));
    context.pushReplacement('/assessment/test/${widget.testId}/result');
  }

  Future<void> _confirmStop() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('หยุดการทดสอบ?',
            style: thaiSans(size: 18, weight: FontWeight.w800)),
        content: Text('ระบบจะบันทึกจำนวนครั้งปัจจุบันเป็นผลลัพธ์',
            style: thaiSans(size: 15, weight: FontWeight.w600)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('ยกเลิก',
                style: thaiSans(size: 15, weight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('หยุด',
                style: thaiSans(
                    size: 15,
                    weight: FontWeight.w800,
                    color: const Color(0xFFD32F2F))),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _timer?.cancel();
      _finish();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_recordingStarted) {
      _recordingStarted = false;
      ref.read(recordingServiceProvider).stopAndSave();
    }
    ref.read(ttsServiceProvider).stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.testId == 'tug') return const TugLivePage();

    final session = ref.watch(assessmentSessionProvider);
    final showRail = _phase == _Phase.ready || _phase == _Phase.countdown;

    return AssessmentScaffold(
      title: _test.thaiName,
      progress: showRail
          ? AssessmentProgressRail(
              session: session,
              currentStage: stageIndexForTest(widget.testId),
            )
          : null,
      body: Stack(
        fit: StackFit.expand,
        children: [
          PoseCameraView(onFrame: _onFrame),
          _overlay(context),
        ],
      ),
      bottom: _bottom(),
    );
  }

  Widget? _bottom() {
    switch (_phase) {
      case _Phase.ready:
        return AssessmentButton(
          label: 'เริ่มจับเวลา',
          icon: Icons.timer_outlined,
          onTap: _readyToStart ? _startCountdown : null,
        );
      case _Phase.counting:
        return AssessmentButton(
            label: 'หยุด', primary: false, onTap: _confirmStop);
      case _Phase.countdown:
      case _Phase.done:
        return null;
    }
  }

  Widget _overlay(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final children = <Widget>[];

    switch (_phase) {
      case _Phase.ready:
        final String prompt;
        if (!_bodyOk) {
          prompt = 'ขยับตำแหน่ง ให้กล้องเห็นทั้งตัว';
        } else if (_counter.needsCalibration && !_counter.isCalibrated) {
          prompt = _counter.calibrationPrompt;
        } else {
          prompt = 'พร้อม! กดปุ่ม "เริ่มจับเวลา"';
        }
        children.add(Positioned(
          left: w * 0.04,
          right: w * 0.04,
          bottom: w * 0.04,
          child: _panel(
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _bodyOk
                      ? Icons.check_circle_rounded
                      : Icons.center_focus_strong_rounded,
                  color:
                      _bodyOk ? KColors.greenLight : const Color(0xFFFFB74D),
                  size: w * 0.13,
                ),
                SizedBox(height: w * 0.02),
                Text(prompt,
                    textAlign: TextAlign.center,
                    style: thaiSans(
                        size: w * 0.055,
                        weight: FontWeight.w800,
                        color: Colors.white)),
              ],
            ),
          ),
        ));
      case _Phase.countdown:
        children.add(Center(
          child: _panel(
            Text('$_countdown',
                style: thaiSans(
                    size: w * 0.28,
                    weight: FontWeight.w900,
                    color: Colors.white)),
          ),
        ));
      case _Phase.counting:
        children.add(Positioned(
          top: w * 0.04,
          left: w * 0.04,
          right: w * 0.04,
          child: _panel(
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _stat('${_counter.reps}', 'ครั้ง', w),
                _stat('$_secondsLeft', 'วินาที', w),
              ],
            ),
          ),
        ));
        if (_counter.guidance != null) {
          children.add(Positioned(
            left: w * 0.04,
            right: w * 0.04,
            bottom: w * 0.04,
            child: _panel(
              Text(_counter.guidance!,
                  textAlign: TextAlign.center,
                  style: thaiSans(
                      size: w * 0.05,
                      weight: FontWeight.w800,
                      color: const Color(0xFFFF8A65))),
            ),
          ));
        }
      case _Phase.done:
        break;
    }

    return Stack(children: children);
  }

  Widget _panel(Widget child) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(160),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Center(child: child),
      );

  Widget _stat(String value, String unit, double w) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: thaiSans(
                  size: w * 0.15,
                  weight: FontWeight.w900,
                  color: Colors.white)),
          Text(unit,
              style: thaiSans(
                  size: w * 0.042,
                  weight: FontWeight.w700,
                  color: Colors.white)),
        ],
      );
}
