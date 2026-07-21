import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/assessment_session.dart';
import '../../models/assessment_stage.dart';
import '../../models/test_results.dart';
import '../../rep_counters/chair_stand_counter.dart';
import '../../rep_counters/pose_frame.dart';
import '../../services/sppb_scoring.dart';
import '../../services/tts_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/assessment_button.dart';
import '../../widgets/assessment_progress_rail.dart';
import '../../widgets/assessment_scaffold.dart';
import '../../widgets/pose_camera_view.dart';

/// SPPB Chair Stand test: a pre-test (stand once, arms folded) that doubles as
/// the counter's calibration, then a timed five-rise test. The camera counts
/// rises with [ChairStandCounter]; the helper can also stop manually on the 5th
/// rise. Time to five rises maps to 0–4 points.
class ChairStandPage extends ConsumerStatefulWidget {
  const ChairStandPage({super.key});

  @override
  ConsumerState<ChairStandPage> createState() => _ChairStandPageState();
}

enum _Phase { pretest, getReady, counting, done }

class _ChairStandPageState extends ConsumerState<ChairStandPage> {
  static const int _targetReps = 5;
  static const _required = [
    Lm.leftShoulder,
    Lm.rightShoulder,
    Lm.leftHip,
    Lm.rightHip
  ];

  final ChairStandCounter _counter = ChairStandCounter();
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _ticker;
  Timer? _cdTimer;

  _Phase _phase = _Phase.pretest;
  bool _bodyOk = false;
  int _countdown = 0;
  double _elapsed = 0;

  @override
  void dispose() {
    _ticker?.cancel();
    _cdTimer?.cancel();
    ref.read(ttsServiceProvider).stop();
    super.dispose();
  }

  bool get _readyToCount => _bodyOk && _counter.isCalibrated;

  void _onFrame(PoseFrame frame) {
    switch (_phase) {
      case _Phase.pretest:
        _bodyOk = frame.allVisible(_required);
        _counter.calibrate(frame);
        setState(() {});
      case _Phase.getReady:
        break; // counting down before the timed reps start
      case _Phase.counting:
        final before = _counter.reps;
        _counter.add(frame);
        if (_counter.reps > before) {
          ref.read(ttsServiceProvider).speak('${_counter.reps}');
        }
        if (_counter.reps >= _targetReps) {
          _finish();
        } else {
          setState(() {});
        }
      case _Phase.done:
        break;
    }
  }

  // "เตรียมตัว… 3-2-1" before the reps start timing, so the senior can get seated
  // and ready without losing time the instant Start is tapped.
  void _startCountdown() {
    setState(() {
      _phase = _Phase.getReady;
      _countdown = 3;
    });
    ref.read(ttsServiceProvider).speak('เตรียมตัว');
    _cdTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      _countdown--;
      if (_countdown <= 0) {
        t.cancel();
        _beginCounting();
      } else {
        setState(() {});
      }
    });
  }

  void _beginCounting() {
    setState(() => _phase = _Phase.counting);
    ref.read(ttsServiceProvider).speak('เริ่ม');
    _stopwatch
      ..reset()
      ..start();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      setState(() => _elapsed = _stopwatch.elapsed.inMilliseconds / 1000.0);
    });
  }

  void _finish() {
    if (_phase == _Phase.done) return;
    _phase = _Phase.done;
    _ticker?.cancel();
    _stopwatch.stop();
    final seconds = _stopwatch.elapsed.inMilliseconds / 1000.0;
    final points = SppbScoring.chairStandPoints(seconds, preTestPassed: true);
    ref.read(assessmentSessionProvider.notifier).setChairStand(
        ChairStandResult(preTestPassed: true, seconds: seconds, points: points));
    context.pushReplacement('/assessment/test/chair_stand/result');
  }

  void _unable() {
    ref.read(assessmentSessionProvider.notifier).setChairStand(
        const ChairStandResult(preTestPassed: false, seconds: 0, points: 0));
    context.pushReplacement('/assessment/test/chair_stand/result');
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(assessmentSessionProvider);
    return AssessmentScaffold(
      title: 'ลุกยืนจากเก้าอี้ 5 ครั้ง',
      progress: _phase == _Phase.pretest
          ? AssessmentProgressRail(
              session: session, currentStage: stageIndexForTest('chair_stand'))
          : null,
      body: Stack(
        fit: StackFit.expand,
        children: [
          PoseCameraView(onFrame: _onFrame),
          _overlay(context),
        ],
      ),
      bottom: _bottom(context),
    );
  }

  Widget? _bottom(BuildContext context) {
    switch (_phase) {
      case _Phase.pretest:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AssessmentButton(
              label: 'เริ่มนับ 5 ครั้ง',
              icon: Icons.timer_outlined,
              onTap: _readyToCount ? _startCountdown : null,
            ),
            SizedBox(height: MediaQuery.sizeOf(context).width * 0.03),
            AssessmentButton(
              label: 'ลุกไม่ได้ (0 คะแนน)',
              primary: false,
              onTap: _unable,
            ),
          ],
        );
      case _Phase.getReady:
        return AssessmentButton(label: 'เตรียมตัว…', onTap: null);
      case _Phase.counting:
        return AssessmentButton(
          label: 'นับครบ 5 ครั้งแล้ว',
          icon: Icons.check_circle_rounded,
          onTap: _finish,
        );
      case _Phase.done:
        return null;
    }
  }

  Widget _overlay(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    switch (_phase) {
      case _Phase.pretest:
        final String prompt;
        if (!_bodyOk) {
          prompt = 'ขยับตำแหน่ง ให้กล้องเห็นทั้งตัว';
        } else if (!_counter.isCalibrated) {
          prompt = 'ทดสอบก่อน: ไขว้แขนแนบอก แล้วลองลุกขึ้นยืนหนึ่งครั้ง';
        } else {
          prompt = 'พร้อม! นั่งลง แล้วกด "เริ่มนับ 5 ครั้ง"';
        }
        return Positioned(
          left: w * 0.04,
          right: w * 0.04,
          bottom: w * 0.04,
          child: _panel(
            w,
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _readyToCount
                      ? Icons.check_circle_rounded
                      : Icons.event_seat_rounded,
                  color:
                      _readyToCount ? KColors.greenLight : const Color(0xFFFFB74D),
                  size: w * 0.12,
                ),
                SizedBox(height: w * 0.02),
                Text(prompt,
                    textAlign: TextAlign.center,
                    style: thaiSans(
                        size: w * 0.05,
                        weight: FontWeight.w800,
                        color: Colors.white)),
              ],
            ),
          ),
        );
      case _Phase.getReady:
        return Center(
          child: Container(
            width: w * 0.44,
            height: w * 0.44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(160),
              shape: BoxShape.circle,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('เตรียมตัว',
                    style: thaiSans(
                        size: w * 0.05,
                        weight: FontWeight.w700,
                        color: Colors.white)),
                Text('$_countdown',
                    style: thaiSans(
                        size: w * 0.26,
                        weight: FontWeight.w900,
                        color: KColors.greenLight)),
              ],
            ),
          ),
        );
      case _Phase.counting:
        return Positioned(
          top: w * 0.04,
          left: w * 0.04,
          right: w * 0.04,
          child: _panel(
            w,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _stat('${_counter.reps}/$_targetReps', 'ครั้ง', w),
                _stat(_elapsed.toStringAsFixed(1), 'วินาที', w),
              ],
            ),
          ),
        );
      case _Phase.done:
        return const SizedBox.shrink();
    }
  }

  Widget _panel(double w, Widget child) => Container(
        margin: EdgeInsets.all(w * 0.02),
        padding: EdgeInsets.all(w * 0.05),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(170),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Center(child: child),
      );

  Widget _stat(String value, String unit, double w) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: thaiSans(
                  size: w * 0.13, weight: FontWeight.w900, color: Colors.white)),
          Text(unit,
              style: thaiSans(
                  size: w * 0.04,
                  weight: FontWeight.w700,
                  color: Colors.white)),
        ],
      );
}
