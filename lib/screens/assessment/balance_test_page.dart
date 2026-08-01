import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/assessment_session.dart';
import '../../models/assessment_stage.dart';
import '../../models/test_results.dart';
import '../../rep_counters/balance_hold_detector.dart';
import '../../rep_counters/pose_frame.dart';
import '../../services/sppb_scoring.dart';
import '../../services/tts_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/assessment_button.dart';
import '../../widgets/assessment_progress_rail.dart';
import '../../widgets/assessment_scaffold.dart';
import '../../widgets/footprint_diagram.dart';
import '../../widgets/pose_camera_view.dart';

/// SPPB Balance test: three timed stances (side-by-side → semi-tandem → tandem),
/// each a 10-second hold. The camera confirms the body is present and auto-fails
/// on loss of balance; the footprint diagram tells the user how to place their
/// feet. Implements the SPPB gate: failing a stance (<10 s) skips the remaining
/// stances (scored 0) and ends the test.
class BalanceTestPage extends ConsumerStatefulWidget {
  const BalanceTestPage({super.key});

  @override
  ConsumerState<BalanceTestPage> createState() => _BalanceTestPageState();
}

enum _Phase { setup, getReady, holding, done }

class _BalanceTestPageState extends ConsumerState<BalanceTestPage> {
  static const _stances = BalanceStance.values;
  static const double _holdTarget = 10.0; // seconds

  final BalanceHoldDetector _detector = BalanceHoldDetector();
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _ticker;
  Timer? _cdTimer;

  _Phase _phase = _Phase.setup;
  int _index = 0;
  int _countdown = 0;
  double _elapsed = 0;
  bool _bodyReady = false;
  PoseFrame? _lastFrame;

  // Seconds held for each stance (0 if not reached / gated).
  double _sideBySideSec = 0;
  double _semiTandemSec = 0;
  double _tandemSec = 0;

  BalanceStance get _stance => _stances[_index];

  @override
  void dispose() {
    _ticker?.cancel();
    _cdTimer?.cancel();
    ref.read(ttsServiceProvider).stop();
    super.dispose();
  }

  void _onFrame(PoseFrame frame) {
    _lastFrame = frame;
    switch (_phase) {
      case _Phase.setup:
        final ready = _detector.ready(frame);
        if (ready != _bodyReady) setState(() => _bodyReady = ready);
      case _Phase.getReady:
        break; // counting down — just keep _lastFrame fresh for the real start
      case _Phase.holding:
        _detector.add(frame);
        if (_detector.lost) {
          _endHold(success: false);
        } else {
          setState(() {});
        }
      case _Phase.done:
        break;
    }
  }

  // "เตรียมตัว… 3-2-1" before the hold actually times, so a caregiver still
  // positioning the senior doesn't lose seconds the instant they tap Start.
  void _startCountdown() {
    if (_lastFrame == null) return;
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
        _beginHold();
      } else {
        setState(() {});
      }
    });
  }

  void _beginHold() {
    final frame = _lastFrame;
    if (frame == null) return;
    _detector.start(frame);
    _elapsed = 0;
    _phase = _Phase.holding;
    ref.read(ttsServiceProvider).speak('เริ่ม');
    _stopwatch
      ..reset()
      ..start();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _elapsed = _stopwatch.elapsed.inMilliseconds / 1000.0;
      if (_elapsed >= _holdTarget) {
        _endHold(success: true);
      } else {
        setState(() {});
      }
    });
  }

  void _endHold({required bool success}) {
    if (_phase == _Phase.done) return;
    _ticker?.cancel();
    _stopwatch.stop();
    final seconds = success ? _holdTarget : _elapsed.clamp(0.0, _holdTarget);

    switch (_stance) {
      case BalanceStance.sideBySide:
        _sideBySideSec = seconds;
      case BalanceStance.semiTandem:
        _semiTandemSec = seconds;
      case BalanceStance.tandem:
        _tandemSec = seconds;
    }

    ref.read(ttsServiceProvider).speak(success ? 'เยี่ยม' : 'ไม่เป็นไร');

    // SPPB gating: a failed side-by-side or semi-tandem ends the test; the
    // remaining stances stay at their default 0 seconds.
    final gated = !success &&
        (_stance == BalanceStance.sideBySide ||
            _stance == BalanceStance.semiTandem);

    if (gated || _index >= _stances.length - 1) {
      _finish();
    } else {
      _detector.reset();
      setState(() {
        _index++;
        _phase = _Phase.setup;
        _bodyReady = false;
      });
    }
  }

  void _finish() {
    _phase = _Phase.done;
    final points = SppbScoring.balanceTotal(
      sideBySideSec: _sideBySideSec,
      semiTandemSec: _semiTandemSec,
      tandemSec: _tandemSec,
    );
    ref.read(assessmentSessionProvider.notifier).setBalance(BalanceResult(
          sideBySideSec: _sideBySideSec,
          semiTandemSec: _semiTandemSec,
          tandemSec: _tandemSec,
          points: points,
        ));
    context.pushReplacement('/assessment/test/balance/result');
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(assessmentSessionProvider);
    final w = MediaQuery.sizeOf(context).width;

    return AssessmentScaffold(
      title: 'ประเมินการทรงตัว',
      progress: _phase == _Phase.setup
          ? AssessmentProgressRail(
              session: session, currentStage: stageIndexForTest('balance'))
          : null,
      body: Stack(
        fit: StackFit.expand,
        children: [
          PoseCameraView(onFrame: _onFrame),
          _overlay(w),
        ],
      ),
      bottom: _bottom(),
    );
  }

  Widget? _bottom() {
    switch (_phase) {
      case _Phase.setup:
        return AssessmentButton(
          label: 'เริ่มจับเวลา 10 วินาที',
          icon: Icons.timer_outlined,
          onTap: _bodyReady ? _startCountdown : null,
        );
      case _Phase.getReady:
        return AssessmentButton(label: 'เตรียมตัว…', onTap: null);
      case _Phase.holding:
        return AssessmentButton(
          label: 'ผู้สูงอายุเสียหลัก / ขยับเท้า',
          primary: false,
          onTap: () => _endHold(success: false),
        );
      case _Phase.done:
        return null;
    }
  }

  Widget _overlay(double w) {
    switch (_phase) {
      case _Phase.setup:
        return Positioned(
          left: w * 0.04,
          right: w * 0.04,
          bottom: w * 0.04,
          child: _panel(
            w,
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('ท่าที่ ${_index + 1} จาก ${_stances.length}',
                    style: thaiSans(
                        size: w * 0.04,
                        weight: FontWeight.w700,
                        color: KColors.greenLight)),
                SizedBox(height: w * 0.02),
                FootprintDiagram(stance: _stance, size: w * 0.34),
                SizedBox(height: w * 0.02),
                Text(_stance.thaiName,
                    textAlign: TextAlign.center,
                    style: thaiSans(
                        size: w * 0.058,
                        weight: FontWeight.w800,
                        color: Colors.white)),
                SizedBox(height: w * 0.01),
                Text(_stance.thaiHint,
                    textAlign: TextAlign.center,
                    style: thaiSans(
                        size: w * 0.038,
                        weight: FontWeight.w600,
                        color: Colors.white70)),
                SizedBox(height: w * 0.02),
                Text(
                  _bodyReady
                      ? 'จัดวางเท้าตามภาพ แล้วกด "เริ่มจับเวลา"'
                      : (_detector.guidance ?? 'กำลังค้นหาร่างกาย…'),
                  textAlign: TextAlign.center,
                  style: thaiSans(
                      size: w * 0.042,
                      weight: FontWeight.w700,
                      color: _bodyReady
                          ? KColors.greenLight
                          : const Color(0xFFFFB74D)),
                ),
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
      case _Phase.holding:
        final remaining = (_holdTarget - _elapsed).clamp(0.0, _holdTarget);
        return Stack(
          children: [
            Positioned(
              top: w * 0.06,
              left: 0,
              right: 0,
              child: Center(
                child: SizedBox(
                  width: w * 0.42,
                  height: w * 0.42,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: w * 0.42,
                        height: w * 0.42,
                        child: CircularProgressIndicator(
                          value: (_elapsed / _holdTarget).clamp(0.0, 1.0),
                          strokeWidth: w * 0.03,
                          backgroundColor: Colors.black38,
                          valueColor: const AlwaysStoppedAnimation(KColors.teal),
                        ),
                      ),
                      Text(remaining.ceil().toString(),
                          style: thaiSans(
                              size: w * 0.16,
                              weight: FontWeight.w900,
                              color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
            if (_detector.guidance != null)
              Positioned(
                left: w * 0.04,
                right: w * 0.04,
                bottom: w * 0.04,
                child: _panel(
                  w,
                  Text(_detector.guidance!,
                      textAlign: TextAlign.center,
                      style: thaiSans(
                          size: w * 0.05,
                          weight: FontWeight.w800,
                          color: const Color(0xFFFF8A65))),
                ),
              ),
          ],
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
}
