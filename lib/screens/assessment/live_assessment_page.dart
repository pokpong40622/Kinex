import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/assessment_session.dart';
import '../../models/assessment_test.dart';
import '../../models/test_results.dart';
import '../../rep_counters/pose_frame.dart';
import '../../rep_counters/rep_counter.dart';
import '../../rep_counters/rep_counter_factory.dart';
import '../../services/fitness_scoring.dart';
import '../../services/tts_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/assessment_button.dart';
import '../../widgets/assessment_scaffold.dart';
import '../../widgets/pose_camera_view.dart';

enum _Phase { calibrating, countdown, counting, done }

/// THE core camera test screen: calibrates (if needed), counts down, then
/// runs the timed rep-counting window and stores the result.
class LiveAssessmentPage extends ConsumerStatefulWidget {
  final String testId;
  const LiveAssessmentPage({super.key, required this.testId});

  @override
  ConsumerState<LiveAssessmentPage> createState() =>
      _LiveAssessmentPageState();
}

class _LiveAssessmentPageState extends ConsumerState<LiveAssessmentPage> {
  late final RepCounter _counter;
  late final AssessmentTest _test;

  _Phase _phase = _Phase.calibrating;
  int _countdown = 3;
  int _secondsLeft = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _test = assessmentTestById(widget.testId);
    _counter = createRepCounter(widget.testId);
    _secondsLeft = _test.durationSeconds;

    if (_counter.needsCalibration) {
      _phase = _Phase.calibrating;
    } else {
      _startCountdown();
    }
  }

  void _startCountdown() {
    _phase = _Phase.countdown;
    _countdown = 3;
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
      case _Phase.calibrating:
        _counter.calibrate(frame);
        if (_counter.isCalibrated) {
          setState(_startCountdown);
        } else {
          setState(() {});
        }
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
    context.go('/assessment/test/${widget.testId}/result');
  }

  Future<void> _confirmStop() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('หยุดการทดสอบ?', style: thaiSans(size: 18, weight: FontWeight.w800)),
        content: Text('ระบบจะบันทึกจำนวนครั้งปัจจุบันเป็นผลลัพธ์',
            style: thaiSans(size: 15, weight: FontWeight.w600)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('ยกเลิก', style: thaiSans(size: 15, weight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('หยุด',
                style: thaiSans(
                    size: 15, weight: FontWeight.w800, color: const Color(0xFFD32F2F))),
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
    ref.read(ttsServiceProvider).stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AssessmentScaffold(
      title: _test.thaiName,
      body: Stack(
        fit: StackFit.expand,
        children: [
          PoseCameraView(onFrame: _onFrame),
          _overlay(),
        ],
      ),
      bottom: _phase == _Phase.counting
          ? AssessmentButton(label: 'หยุด', primary: false, onTap: _confirmStop)
          : null,
    );
  }

  Widget _overlay() {
    final children = <Widget>[];

    switch (_phase) {
      case _Phase.calibrating:
        children.add(_panel(
          Text(_counter.calibrationPrompt,
              textAlign: TextAlign.center,
              style: thaiSans(size: 26, weight: FontWeight.w800, color: Colors.white)),
        ));
      case _Phase.countdown:
        children.add(_panel(
          Text('$_countdown',
              style: thaiSans(size: 96, weight: FontWeight.w900, color: Colors.white)),
        ));
      case _Phase.counting:
        children.add(Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: _panel(
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _stat('${_counter.reps}', 'ครั้ง'),
                _stat('$_secondsLeft', 'วินาที'),
              ],
            ),
          ),
        ));
        if (_counter.guidance != null) {
          children.add(Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _panel(
              Text(_counter.guidance!,
                  textAlign: TextAlign.center,
                  style: thaiSans(
                      size: 20, weight: FontWeight.w800, color: const Color(0xFFFF8A65))),
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

  Widget _stat(String value, String unit) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: thaiSans(size: 56, weight: FontWeight.w900, color: Colors.white)),
          Text(unit, style: thaiSans(size: 16, weight: FontWeight.w700, color: Colors.white)),
        ],
      );
}
