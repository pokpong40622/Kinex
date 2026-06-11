import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/assessment_session.dart';
import '../../data/recording_pref.dart';
import '../../models/assessment_stage.dart';
import '../../models/test_results.dart';
import '../../rep_counters/pose_frame.dart';
import '../../rep_counters/tug_detector.dart';
import '../../services/fitness_scoring.dart';
import '../../services/recording_service.dart';
import '../../services/tts_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/assessment_button.dart';
import '../../widgets/assessment_progress_rail.dart';
import '../../widgets/assessment_scaffold.dart';
import '../../widgets/pose_camera_view.dart';

enum _Phase { ready, armed, running, done }

/// Full-screen AI-timed TUG (Timed Up and Go) test.
///
/// Flow:
///   ready  — camera open; user sits; detector.calibrate() runs until
///            detector.isCalibrated. 'เริ่ม' button enables.
///   armed  — show walk instructions; detector.add() runs; when detector.started
///            → transition to running, start Stopwatch, speak 'เริ่ม'.
///   running — show live elapsed MM:SS.t; when detector.finished → finalize.
///   done   — save result and navigate to result screen.
class TugLivePage extends ConsumerStatefulWidget {
  const TugLivePage({super.key});

  @override
  ConsumerState<TugLivePage> createState() => _TugLivePageState();
}

class _TugLivePageState extends ConsumerState<TugLivePage> {
  static const String _testId = 'tug';

  final TugDetector _detector = TugDetector();
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _ticker;
  Duration _elapsed = Duration.zero;
  _Phase _phase = _Phase.ready;
  bool _recordingStarted = false;

  @override
  void dispose() {
    _ticker?.cancel();
    if (_recordingStarted) {
      _recordingStarted = false;
      ref.read(recordingServiceProvider).stopAndSave();
    }
    ref.read(ttsServiceProvider).stop();
    super.dispose();
  }

  void _onFrame(PoseFrame frame) {
    switch (_phase) {
      case _Phase.ready:
        _detector.calibrate(frame);
        setState(() {});

      case _Phase.armed:
        _detector.add(frame);
        if (_detector.started) {
          _startRunning();
        } else {
          setState(() {});
        }

      case _Phase.running:
        _detector.add(frame);
        if (_detector.finished) {
          _finalize();
        } else {
          setState(() {});
        }

      case _Phase.done:
        break;
    }
  }

  void _arm() {
    setState(() => _phase = _Phase.armed);
  }

  void _startRunning() {
    _stopwatch.start();
    _phase = _Phase.running;
    if (ref.read(recordingEnabledProvider)) {
      _recordingStarted = true;
      ref.read(recordingServiceProvider).start(_testId);
    }
    ref.read(ttsServiceProvider).speak('เริ่ม');
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      setState(() => _elapsed = _stopwatch.elapsed);
    });
  }

  void _finalize() {
    if (_phase == _Phase.done) return;
    _stopwatch.stop();
    _ticker?.cancel();
    _elapsed = _stopwatch.elapsed;
    _phase = _Phase.done;
    if (_recordingStarted) {
      _recordingStarted = false;
      ref.read(recordingServiceProvider).stopAndSave();
    }

    final seconds = _elapsed.inMilliseconds / 1000.0;
    final level = FitnessScoring.tugLevel(seconds);
    ref
        .read(assessmentSessionProvider.notifier)
        .setMovementResult(_testId, TimedResult(seconds, level));
    context.pushReplacement('/assessment/test/$_testId/result');
  }

  void _manualStop() {
    _finalize();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(assessmentSessionProvider);
    final w = MediaQuery.sizeOf(context).width;
    final showRail = _phase == _Phase.ready || _phase == _Phase.armed;

    return AssessmentScaffold(
      title: 'ลุก-เดิน-นั่ง ไปกลับ',
      progress: showRail
          ? AssessmentProgressRail(
              session: session,
              currentStage: stageIndexForTest(_testId),
            )
          : null,
      body: Stack(
        fit: StackFit.expand,
        children: [
          PoseCameraView(onFrame: _onFrame),
          _overlay(context, w),
          // TEMP debug readout — remove after TUG tuning.
          Positioned(
            top: w * 0.02,
            left: w * 0.02,
            child: Container(
              padding: EdgeInsets.all(w * 0.02),
              color: Colors.black.withAlpha(160),
              child: Text(
                _detector.debug,
                style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 11,
                    fontFamily: 'monospace'),
              ),
            ),
          ),
        ],
      ),
      bottom: _bottom(),
    );
  }

  Widget? _bottom() {
    switch (_phase) {
      case _Phase.ready:
        return AssessmentButton(
          label: 'เริ่ม',
          icon: Icons.play_arrow_rounded,
          onTap: _detector.isCalibrated ? _arm : null,
        );
      case _Phase.running:
        return AssessmentButton(
          label: 'หยุด (ด้วยตนเอง)',
          primary: false,
          onTap: _manualStop,
        );
      case _Phase.armed:
      case _Phase.done:
        return null;
    }
  }

  Widget _overlay(BuildContext context, double w) {
    final children = <Widget>[];

    switch (_phase) {
      case _Phase.ready:
        final calibrated = _detector.isCalibrated;
        children.add(Positioned(
          left: w * 0.04,
          right: w * 0.04,
          bottom: w * 0.04,
          child: _panel(
            w,
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (calibrated)
                  Icon(Icons.check_circle_rounded,
                      color: KColors.greenLight, size: w * 0.10),
                Text(
                  calibrated
                      ? 'พร้อมแล้ว กด "เริ่ม" เพื่อออกคำสั่ง'
                      : _detector.calibrationPrompt,
                  textAlign: TextAlign.center,
                  style: thaiSans(
                      size: w * 0.055,
                      weight: FontWeight.w800,
                      color: Colors.white),
                ),
                if (_detector.guidance != null) ...[
                  SizedBox(height: w * 0.02),
                  Text(
                    _detector.guidance!,
                    textAlign: TextAlign.center,
                    style: thaiSans(
                        size: w * 0.042,
                        weight: FontWeight.w700,
                        color: const Color(0xFFFF8A65)),
                  ),
                ],
              ],
            ),
          ),
        ));

      case _Phase.armed:
        children.add(Positioned(
          left: w * 0.04,
          right: w * 0.04,
          bottom: w * 0.04,
          child: _panel(
            w,
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.directions_walk_rounded,
                    color: KColors.greenLight, size: w * 0.10),
                SizedBox(height: w * 0.02),
                Text(
                  'เมื่อพร้อม ให้ลุกขึ้นยืน\nเดิน 3 เมตร อ้อมกลับมานั่ง',
                  textAlign: TextAlign.center,
                  style: thaiSans(
                      size: w * 0.055,
                      weight: FontWeight.w800,
                      color: Colors.white),
                ),
                if (_detector.guidance != null) ...[
                  SizedBox(height: w * 0.02),
                  Text(
                    _detector.guidance!,
                    textAlign: TextAlign.center,
                    style: thaiSans(
                        size: w * 0.042,
                        weight: FontWeight.w700,
                        color: const Color(0xFFFF8A65)),
                  ),
                ],
              ],
            ),
          ),
        ));

      case _Phase.running:
        final minutes = _elapsed.inMinutes.remainder(60);
        final seconds = _elapsed.inSeconds.remainder(60);
        final tenths = (_elapsed.inMilliseconds ~/ 100).remainder(10);
        final display =
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.$tenths';

        children.add(Positioned(
          top: w * 0.04,
          left: w * 0.04,
          right: w * 0.04,
          child: _panel(
            w,
            Text(
              display,
              style: thaiSans(
                  size: w * 0.20,
                  weight: FontWeight.w900,
                  color: Colors.white),
            ),
          ),
        ));

        if (_detector.guidance != null) {
          children.add(Positioned(
            left: w * 0.04,
            right: w * 0.04,
            bottom: w * 0.04,
            child: _panel(
              w,
              Text(
                _detector.guidance!,
                textAlign: TextAlign.center,
                style: thaiSans(
                    size: w * 0.05,
                    weight: FontWeight.w800,
                    color: const Color(0xFFFF8A65)),
              ),
            ),
          ));
        }

      case _Phase.done:
        break;
    }

    return Stack(children: children);
  }

  Widget _panel(double w, Widget child) => Container(
        margin: EdgeInsets.all(w * 0.02),
        padding: EdgeInsets.all(w * 0.05),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(160),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Center(child: child),
      );
}
