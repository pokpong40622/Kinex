import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/assessment_session.dart';
import '../../models/assessment_stage.dart';
import '../../models/test_results.dart';
import '../../services/sppb_scoring.dart';
import '../../services/tts_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive.dart';
import '../../widgets/assessment_button.dart';
import '../../widgets/assessment_progress_rail.dart';
import '../../widgets/assessment_scaffold.dart';

/// SPPB Gait Speed test: a helper-operated stopwatch for the 4-metre walk. The
/// camera cannot measure a 4 m course, so the helper taps start on the first
/// step and stop at the 4 m line. Run twice; the faster time is scored.
class GaitSpeedPage extends ConsumerStatefulWidget {
  const GaitSpeedPage({super.key});

  @override
  ConsumerState<GaitSpeedPage> createState() => _GaitSpeedPageState();
}

enum _Phase { idle, running }

class _GaitSpeedPageState extends ConsumerState<GaitSpeedPage> {
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _ticker;
  _Phase _phase = _Phase.idle;
  Duration _elapsed = Duration.zero;
  final List<double> _times = []; // recorded run times (seconds)

  @override
  void dispose() {
    _ticker?.cancel();
    ref.read(ttsServiceProvider).stop();
    super.dispose();
  }

  void _start() {
    setState(() => _phase = _Phase.running);
    ref.read(ttsServiceProvider).speak('เริ่ม');
    _stopwatch
      ..reset()
      ..start();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      setState(() => _elapsed = _stopwatch.elapsed);
    });
  }

  void _stop() {
    _ticker?.cancel();
    _stopwatch.stop();
    _times.add(_stopwatch.elapsed.inMilliseconds / 1000.0);
    setState(() => _phase = _Phase.idle);
  }

  void _finish() {
    final best = _times.reduce(math.min);
    final points = SppbScoring.gaitPoints(best);
    ref
        .read(assessmentSessionProvider.notifier)
        .setGait(GaitResult(seconds: best, unable: false, points: points));
    context.pushReplacement('/assessment/test/gait_speed/result');
  }

  void _unable() {
    ref
        .read(assessmentSessionProvider.notifier)
        .setGait(const GaitResult(seconds: 0, unable: true, points: 0));
    context.pushReplacement('/assessment/test/gait_speed/result');
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(assessmentSessionProvider);
    return AssessmentScaffold(
      title: 'วัดความเร็วในการเดิน 4 เมตร',
      progress: _phase == _Phase.idle
          ? AssessmentProgressRail(
              session: session, currentStage: stageIndexForTest('gait_speed'))
          : null,
      body: Padding(
        padding: EdgeInsets.all(context.r(20)),
        child: _phase == _Phase.running ? _runningView(context) : _idleView(context),
      ),
      bottom: _bottom(context),
    );
  }

  Widget _idleView(BuildContext context) {
    final runNo = _times.length + 1;
    return ListView(
      children: [
        _card(
          context,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.straighten_rounded,
                    color: KColors.tealDark, size: context.r(26)),
                SizedBox(width: context.r(10)),
                Expanded(
                  child: Text('ทำเครื่องหมายระยะ 4 เมตรบนพื้นทางเดินราบ',
                      style: thaiSans(size: context.r(16), weight: FontWeight.w700)),
                ),
              ]),
              SizedBox(height: context.r(12)),
              Text(
                'ผู้ดูแลกด "เริ่มจับเวลา" เมื่อก้าวเท้าแรก และกด "หยุด" เมื่อผ่านเส้น 4 เมตร '
                'ให้เดินด้วยความเร็วปกติ',
                style: thaiSans(size: context.r(15), weight: FontWeight.w600),
              ),
            ],
          ),
        ),
        SizedBox(height: context.r(16)),
        if (_times.isEmpty)
          _bigLabel(context, 'ครั้งที่ $runNo จาก 2', '00.0 วินาที')
        else ...[
          for (var i = 0; i < _times.length; i++)
            _recordedRow(context, i + 1, _times[i]),
          SizedBox(height: context.r(8)),
          Text(
            _times.length < 2 ? 'ทำอีกครั้งเพื่อความแม่นยำ หรือใช้ผลนี้ได้เลย'
                : 'ระบบจะใช้เวลาที่เร็วที่สุด (${_times.reduce(math.min).toStringAsFixed(1)} วินาที)',
            textAlign: TextAlign.center,
            style: thaiSans(
                size: context.r(15),
                weight: FontWeight.w700,
                color: KColors.tealDark),
          ),
        ],
      ],
    );
  }

  Widget _runningView(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final s = _elapsed.inMilliseconds / 1000.0;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.directions_walk_rounded,
              size: w * 0.16, color: KColors.teal),
          SizedBox(height: context.r(8)),
          Text('${s.toStringAsFixed(1)} วินาที',
              style: thaiSans(size: w * 0.18, weight: FontWeight.w900)),
          SizedBox(height: context.r(8)),
          Text('กด "หยุด" เมื่อผู้สูงอายุผ่านเส้น 4 เมตร',
              textAlign: TextAlign.center,
              style: thaiSans(size: context.r(16), weight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget? _bottom(BuildContext context) {
    switch (_phase) {
      case _Phase.running:
        return AssessmentButton(
          label: 'หยุด (ถึงเส้น 4 เมตร)',
          icon: Icons.stop_circle_outlined,
          onTap: _stop,
        );
      case _Phase.idle:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_times.isNotEmpty)
              AssessmentButton(
                label: 'ใช้ผลนี้ (ไปต่อ)',
                icon: Icons.check_rounded,
                onTap: _finish,
              ),
            if (_times.isNotEmpty) SizedBox(height: context.r(12)),
            AssessmentButton(
              label: _times.isEmpty
                  ? 'เริ่มจับเวลา'
                  : (_times.length < 2 ? 'จับเวลาครั้งที่ 2' : 'จับเวลาใหม่'),
              icon: Icons.timer_outlined,
              primary: _times.isEmpty,
              onTap: _start,
            ),
            SizedBox(height: context.r(12)),
            AssessmentButton(
              label: 'เดินไม่ได้ (0 คะแนน)',
              primary: false,
              onTap: _unable,
            ),
          ],
        );
    }
  }

  Widget _card(BuildContext context, Widget child) => Container(
        width: double.infinity,
        padding: EdgeInsets.all(context.r(18)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(color: Color(0x18000000), blurRadius: 10, offset: Offset(0, 3)),
          ],
        ),
        child: child,
      );

  Widget _bigLabel(BuildContext context, String label, String value) => Column(
        children: [
          Text(label,
              style: thaiSans(
                  size: context.r(16),
                  weight: FontWeight.w700,
                  color: KColors.tealDark)),
          SizedBox(height: context.r(6)),
          Text(value, style: thaiSans(size: context.r(40), weight: FontWeight.w900)),
        ],
      );

  Widget _recordedRow(BuildContext context, int runNo, double seconds) =>
      Container(
        margin: EdgeInsets.only(bottom: context.r(10)),
        padding: EdgeInsets.symmetric(
            horizontal: context.r(16), vertical: context.r(14)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text('ครั้งที่ $runNo',
                  style: thaiSans(size: context.r(16), weight: FontWeight.w700)),
            ),
            Text('${seconds.toStringAsFixed(1)} วินาที',
                style: thaiSans(size: context.r(18), weight: FontWeight.w900)),
          ],
        ),
      );
}
