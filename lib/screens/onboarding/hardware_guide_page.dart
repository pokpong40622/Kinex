import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../ble/ble_service.dart';
import '../../data/emg_repository.dart';
import '../../models/emg_metrics.dart';
import '../../models/muscle.dart';
import '../../theme/app_theme.dart';

enum _StepKind { welcome, install, measure, done }

class _GuideStep {
  final _StepKind kind;
  final String? imagePath; // null for welcome/done
  final String title;
  final String body;
  final int padIndex; // 1..4, or 0
  final Muscle? muscle; // the muscle this pad reads (install/measure)
  const _GuideStep({
    required this.kind,
    this.imagePath,
    required this.title,
    required this.body,
    this.padIndex = 0,
    this.muscle,
  });
}

/// Result of one leg's EMG capture: the real min / mean / max (and sample count)
/// computed from the stream of values the ESP32 sent during the 3-second hold.
/// [max] is the EMGPeak — the 100% MVC reference saved for that muscle/leg.
class _LegCapture {
  final double min;
  final double mean;
  final double max;
  final int count;
  const _LegCapture(this.min, this.mean, this.max, this.count);

  double get percentMvc =>
      max > 0 ? (mean / max * 100).clamp(0, 100).toDouble() : 0;

  EmgSample toSample() => EmgSample(peakMicrovolts: max, meanMicrovolts: mean);
}

/// EMG hardware-install + MVC-capture walkthrough, shown on every app entry.
/// Four pad positions; for each, the user fits the pad on a leg, lifts that leg,
/// and taps the leg's button. The app tells the ESP32 to stream EMG samples for
/// ~3 seconds, then computes the real min/mean/max — the max becomes that
/// muscle/leg's MVC reference (EMGPeak), saved to phone storage.
///
/// Sensor values are mock (random on the ESP32) until the real EMG analogRead is
/// wired in, but the whole 2-device path — command, stream, stats — is live.
class HardwareGuidePage extends ConsumerStatefulWidget {
  const HardwareGuidePage({super.key});

  @override
  ConsumerState<HardwareGuidePage> createState() => _HardwareGuidePageState();
}

class _HardwareGuidePageState extends ConsumerState<HardwareGuidePage>
    with SingleTickerProviderStateMixin {
  /// Pad position (1-based) → muscle. Correct hardware mapping:
  /// R1 = VL, R2 = BF, R3 = TA, R4 = GCM.
  static const List<Muscle> _padMuscles = [
    Muscle.vl, // R1
    Muscle.bf, // R2
    Muscle.ta, // R3
    Muscle.gcm, // R4
  ];

  // Length of one leg's capture window. The ESP streams at 20 Hz, so this is
  // ~60 samples — plenty for a stable min/mean/max.
  static const Duration _captureWindow = Duration(seconds: 3);

  int _step = 0;
  late final List<_GuideStep> _steps;

  // muscle → (side → captured stats). Filled one leg at a time.
  final Map<Muscle, Map<LegSide, _LegCapture>> _captures = {};

  late final AnimationController _bar; // capture-window progress
  LegSide? _capturingLeg; // which leg is mid-capture (null = idle)
  final List<double> _buffer = []; // samples for the in-flight capture
  StreamSubscription<String>? _rxSub;

  @override
  void initState() {
    super.initState();
    _steps = _buildSteps();
    _bar = AnimationController(vsync: this, duration: _captureWindow)
      ..addListener(() => setState(() {}))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) _onCaptureDone();
      });
  }

  @override
  void dispose() {
    _rxSub?.cancel();
    _bar.dispose();
    super.dispose();
  }

  List<_GuideStep> _buildSteps() {
    final steps = <_GuideStep>[];
    steps.add(const _GuideStep(
      kind: _StepKind.welcome,
      title: 'ติดตั้งอุปกรณ์ EMG',
      body: 'ติดแผ่นเซนเซอร์ EMG 4 จุด บนขาทั้งสองข้าง '
          '(ซ้ายและขวา ตำแหน่งเดียวกัน) แล้ววัดค่ากล้ามเนื้อก่อนเริ่มใช้งาน',
    ));
    for (var n = 1; n <= 4; n++) {
      final m = _padMuscles[n - 1];
      steps.add(_GuideStep(
        kind: _StepKind.install,
        imagePath: 'assets/images/hardware_guide/R$n-1.png',
        title: 'ติดแผ่น ${m.code} · ${m.thaiName}',
        body: 'ติดแผ่น ${m.code} · ${m.thaiName} '
            'บนขาทั้งสองข้าง ตำแหน่งเดียวกันตามภาพ แล้วกด "ถัดไป"',
        padIndex: n,
        muscle: m,
      ));
      steps.add(_GuideStep(
        kind: _StepKind.measure,
        imagePath: 'assets/images/hardware_guide/R$n-2.png',
        title: '${m.code} · ${m.thaiName} — ยกขาค้างไว้',
        body: 'ยกขาทีละข้างขึ้นค้างไว้ แล้วแตะปุ่มของขาข้างนั้น (ซ้าย/ขวา) '
            'เพื่อวัดค่า ${m.thaiName} (${m.code}) ข้างละ 3 วินาที',
        padIndex: n,
        muscle: m,
      ));
    }
    steps.add(const _GuideStep(
      kind: _StepKind.done,
      title: 'วัดค่าครบแล้ว',
      body: 'บันทึกค่าสูงสุด (MVC) ของกล้ามเนื้อทั้ง 4 มัดเรียบร้อย พร้อมใช้งาน!',
    ));
    return steps;
  }

  // ---- Navigation ----------------------------------------------------------
  void _next() {
    if (_step < _steps.length - 1) setState(() => _goTo(_step + 1));
  }

  void _back() {
    if (_step > 0) setState(() => _goTo(_step - 1));
  }

  void _goTo(int index) {
    _abortCapture();
    _step = index;
  }

  // ---- Capture (the live 2-device path) ------------------------------------

  bool _muscleDone(Muscle? m) {
    final c = _captures[m];
    return c != null && c[LegSide.left] != null && c[LegSide.right] != null;
  }

  /// Parse one incoming line like "EMG:L:287" into the value for [leg].
  double? _parseSample(String line, LegSide leg) {
    final p = line.split(':');
    if (p.length != 3 || p[0] != 'EMG' || p[1] != leg.code) return null;
    return double.tryParse(p[2]);
  }

  /// Real min / mean / max over the captured samples.
  _LegCapture _computeStats(List<double> xs) {
    if (xs.isEmpty) return const _LegCapture(0, 0, 0, 0);
    var mn = xs.first, mx = xs.first, sum = 0.0;
    for (final x in xs) {
      if (x < mn) mn = x;
      if (x > mx) mx = x;
      sum += x;
    }
    return _LegCapture(mn, sum / xs.length, mx, xs.length);
  }

  void _startCapture(LegSide leg) {
    if (_capturingLeg != null) return;
    final m = _steps[_step].muscle;
    if (m == null) return;

    final ctl = ref.read(bleControllerProvider.notifier);
    if (ref.read(bleControllerProvider).status != BleStatus.connected) {
      _snack('ยังไม่ได้เชื่อมต่ออุปกรณ์ EMG');
      return;
    }

    _buffer.clear();
    setState(() => _capturingLeg = leg);

    // Listen for streamed samples, then ask the ESP32 to start this leg.
    _rxSub?.cancel();
    _rxSub = ctl.incoming.listen((line) {
      final v = _parseSample(line, leg);
      if (v != null) _buffer.add(v);
    });
    ctl.send('START:${leg.code}');

    _bar.forward(from: 0);
  }

  void _onCaptureDone() {
    final leg = _capturingLeg;
    final m = _steps[_step].muscle;

    ref.read(bleControllerProvider.notifier).send('STOP');
    _rxSub?.cancel();
    _rxSub = null;

    if (leg == null || m == null) {
      setState(() => _capturingLeg = null);
      return;
    }

    final stats = _computeStats(List.of(_buffer));
    if (stats.count == 0) {
      setState(() => _capturingLeg = null);
      _snack('ไม่ได้รับข้อมูลจากอุปกรณ์ ลองอีกครั้ง');
      return;
    }

    setState(() {
      (_captures[m] ??= {})[leg] = stats;
      _capturingLeg = null;
    });
  }

  /// Cancel an in-flight capture (navigating away / disposing) without saving.
  void _abortCapture() {
    if (_capturingLeg != null) {
      ref.read(bleControllerProvider.notifier).send('STOP');
    }
    _rxSub?.cancel();
    _rxSub = null;
    _bar.reset();
    _capturingLeg = null;
    _buffer.clear();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg, style: thaiSans(size: 14, color: Colors.white)),
        backgroundColor: KColors.navyText,
        behavior: SnackBarBehavior.floating,
      ));
  }

  Future<void> _finish() async {
    final cal = MvcCalibration(
      samples: {
        for (final e in _captures.entries)
          e.key: {for (final s in e.value.entries) s.key: s.value.toSample()},
      },
      calibratedAt: DateTime.now(),
    );
    await ref.read(emgRepositoryProvider).saveCalibration(cal);
    ref.invalidate(mvcCalibrationProvider);
    if (!mounted) return;
    context.pop(true);
  }

  Future<void> _skipFlow() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('ข้ามการติดตั้ง EMG?',
            style: thaiSans(
                size: 18, weight: FontWeight.w700, color: KColors.navyText)),
        content: Text('สามารถตั้งค่าใหม่ได้ในภายหลัง',
            style: thaiSans(size: 15, color: const Color(0xFF5A6685))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('ยกเลิก',
                style: thaiSans(size: 15, color: KColors.navyText)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('ข้าม',
                style: thaiSans(
                    size: 15, weight: FontWeight.w700, color: KColors.blue)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) Navigator.pop(context, 'skipped');
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final step = _steps[_step];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFEFF3FB)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(w * 0.06, w * 0.04, w * 0.06, w * 0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(w, step),
                SizedBox(height: w * 0.04),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: _buildBody(w, step),
                  ),
                ),
                SizedBox(height: w * 0.04),
                _buildBottom(w, step),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---- Header: back affordance + position progress -------------------------
  Widget _buildHeader(double w, _GuideStep step) {
    final showProgress =
        step.kind == _StepKind.install || step.kind == _StepKind.measure;
    return Row(
      children: [
        SizedBox(
          width: w * 0.11,
          height: w * 0.11,
          child: _step == 0
              ? const SizedBox.shrink()
              : Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  elevation: 2,
                  shadowColor: const Color(0x22000000),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _back,
                    child: Icon(Icons.arrow_back_ios_new_rounded,
                        size: w * 0.05, color: KColors.navyText),
                  ),
                ),
        ),
        Expanded(
          child:
              showProgress ? _buildProgress(w, step) : const SizedBox.shrink(),
        ),
        SizedBox(
          width: w * 0.11,
          child:
              (step.kind == _StepKind.install || step.kind == _StepKind.measure)
                  ? TextButton(
                      onPressed: _skipFlow,
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      child: Text('ข้าม',
                          style: thaiSans(
                              size: w * 0.035,
                              weight: FontWeight.w600,
                              color: KColors.blue)),
                    )
                  : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildProgress(double w, _GuideStep step) {
    return Column(
      children: [
        Text(
          '${step.muscle?.code ?? ''} · ${step.muscle?.thaiName ?? ''} (${step.padIndex}/4)',
          textAlign: TextAlign.center,
          style: thaiSans(
              size: w * 0.038, weight: FontWeight.w600, color: KColors.blue),
        ),
        SizedBox(height: w * 0.02),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) {
            final filled = i < step.padIndex;
            final current = i == step.padIndex - 1;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: EdgeInsets.symmetric(horizontal: w * 0.012),
              width: current ? w * 0.07 : w * 0.025,
              height: w * 0.025,
              decoration: BoxDecoration(
                gradient: filled ? KColors.blueGradient : null,
                color: filled ? null : const Color(0xFFD7DEEC),
                borderRadius: BorderRadius.circular(w * 0.02),
              ),
            );
          }),
        ),
      ],
    );
  }

  // ---- Body ----------------------------------------------------------------
  Widget _buildBody(double w, _GuideStep step) {
    switch (step.kind) {
      case _StepKind.welcome:
        return _buildWelcome(w, step);
      case _StepKind.done:
        return _buildDone(w, step);
      case _StepKind.install:
        return _buildInstall(w, step);
      case _StepKind.measure:
        return _buildMeasure(w, step);
    }
  }

  Widget _buildWelcome(double w, _GuideStep step) {
    return Column(
      children: [
        SizedBox(height: w * 0.06),
        Container(
          width: w * 0.62,
          height: w * 0.62,
          decoration: BoxDecoration(
            gradient: KColors.blueGradient,
            borderRadius: BorderRadius.circular(w * 0.09),
            boxShadow: [
              BoxShadow(
                  color: KColors.blue.withValues(alpha: 0.35),
                  blurRadius: 30,
                  offset: const Offset(0, 14)),
            ],
          ),
          padding: EdgeInsets.all(w * 0.1),
          child:
              Image.asset('assets/images/kinex_logo.png', fit: BoxFit.contain),
        ),
        SizedBox(height: w * 0.09),
        _title(w, step.title),
        SizedBox(height: w * 0.035),
        _bodyText(w, step.body),
        SizedBox(height: w * 0.07),
        OutlinedButton(
          onPressed: _skipFlow,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: KColors.blue.withValues(alpha: 0.5)),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(w * 0.05)),
            padding:
                EdgeInsets.symmetric(horizontal: w * 0.08, vertical: w * 0.028),
          ),
          child: Text('ข้ามขั้นตอนนี้',
              style: thaiSans(
                  size: w * 0.04,
                  weight: FontWeight.w600,
                  color: KColors.blue)),
        ),
      ],
    );
  }

  Widget _buildDone(double w, _GuideStep step) {
    return Column(
      children: [
        SizedBox(height: w * 0.06),
        Container(
          width: w * 0.32,
          height: w * 0.32,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: KColors.tealGradient,
            boxShadow: [
              BoxShadow(
                  color: Color(0x3311C18E),
                  blurRadius: 30,
                  offset: Offset(0, 14)),
            ],
          ),
          child: Icon(Icons.check_rounded, color: Colors.white, size: w * 0.2),
        ),
        SizedBox(height: w * 0.06),
        _title(w, step.title),
        SizedBox(height: w * 0.03),
        _bodyText(w, step.body),
        SizedBox(height: w * 0.06),
        _summaryCard(w),
      ],
    );
  }

  Widget _buildInstall(double w, _GuideStep step) {
    return Column(
      children: [
        SizedBox(height: w * 0.02),
        _imageCard(w, step),
        SizedBox(height: w * 0.06),
        _title(w, step.title),
        SizedBox(height: w * 0.03),
        _bodyText(w, step.body),
      ],
    );
  }

  Widget _buildMeasure(double w, _GuideStep step) {
    return Column(
      children: [
        SizedBox(height: w * 0.02),
        _imageCard(w, step),
        SizedBox(height: w * 0.05),
        _title(w, step.title),
        SizedBox(height: w * 0.03),
        _bodyText(w, step.body),
        SizedBox(height: w * 0.05),
        _captureArea(w, step),
      ],
    );
  }

  // ---- Capture area: per-leg buttons → live stats --------------------------
  Widget _captureArea(double w, _GuideStep step) {
    final m = step.muscle!;
    if (_muscleDone(m)) return _resultCard(w, m);

    final connected =
        ref.watch(bleControllerProvider).status == BleStatus.connected;

    return Column(
      children: [
        if (!connected) ...[
          _connectNotice(w),
          SizedBox(height: w * 0.04),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _legTile(w, m, LegSide.left, connected)),
            SizedBox(width: w * 0.03),
            Expanded(child: _legTile(w, m, LegSide.right, connected)),
          ],
        ),
      ],
    );
  }

  Widget _connectNotice(double w) {
    final ble = ref.watch(bleControllerProvider);
    final busy = ble.status == BleStatus.scanning ||
        ble.status == BleStatus.connecting;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(w * 0.04),
        border: Border.all(color: const Color(0xFFFFB300)),
      ),
      child: Column(
        children: [
          Text('ยังไม่ได้เชื่อมต่ออุปกรณ์ EMG',
              textAlign: TextAlign.center,
              style: thaiSans(
                  size: w * 0.038,
                  weight: FontWeight.w700,
                  color: const Color(0xFFE65100))),
          SizedBox(height: w * 0.025),
          OutlinedButton.icon(
            onPressed: busy
                ? null
                : () => ref.read(bleControllerProvider.notifier).quickConnect(),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFFFB300)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(w * 0.04)),
            ),
            icon: busy
                ? SizedBox(
                    width: w * 0.04,
                    height: w * 0.04,
                    child: const CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFFE65100)),
                  )
                : Icon(Icons.bluetooth_searching_rounded,
                    size: w * 0.045, color: const Color(0xFFE65100)),
            label: Text(busy ? 'กำลังค้นหา…' : 'เชื่อมต่ออุปกรณ์',
                style: thaiSans(
                    size: w * 0.038,
                    weight: FontWeight.w700,
                    color: const Color(0xFFE65100))),
          ),
        ],
      ),
    );
  }

  Widget _legTile(double w, Muscle m, LegSide leg, bool connected) {
    final cap = _captures[m]?[leg];
    final isCapturing = _capturingLeg == leg;
    final otherBusy = _capturingLeg != null && _capturingLeg != leg;
    final label = 'ขา${leg.thaiName} (${leg.code})';

    if (isCapturing) {
      final secsLeft = (3 * (1 - _bar.value)).ceil().clamp(0, 3);
      return _tileShell(
        w,
        accent: KColors.greenDark,
        child: Column(
          children: [
            Text(label,
                style: thaiSans(
                    size: w * 0.036,
                    weight: FontWeight.w800,
                    color: KColors.greenDark)),
            SizedBox(height: w * 0.02),
            Text('กำลังวัด $secsLeft วินาที',
                style: thaiSans(size: w * 0.034, color: KColors.greenDark)),
            SizedBox(height: w * 0.025),
            _greenBar(w, _bar.value),
          ],
        ),
      );
    }

    if (cap != null) {
      // captured → compact stats with a re-measure affordance
      return _tileShell(
        w,
        accent: KColors.greenDark,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_rounded,
                    color: KColors.greenDark, size: w * 0.045),
                SizedBox(width: w * 0.015),
                Text(label,
                    style: thaiSans(
                        size: w * 0.036,
                        weight: FontWeight.w800,
                        color: KColors.greenDark)),
              ],
            ),
            SizedBox(height: w * 0.02),
            _kv(w, 'Max', '${cap.max.toStringAsFixed(0)} µV'),
            _kv(w, 'Mean', '${cap.mean.toStringAsFixed(0)} µV'),
            _kv(w, 'Min', '${cap.min.toStringAsFixed(0)} µV'),
            SizedBox(height: w * 0.01),
            GestureDetector(
              onTap: connected && !otherBusy ? () => _remeasure(m, leg) : null,
              child: Text('วัดใหม่',
                  style: thaiSans(
                      size: w * 0.032,
                      weight: FontWeight.w700,
                      color: connected && !otherBusy
                          ? KColors.blue
                          : const Color(0xFFB9C2D6))),
            ),
          ],
        ),
      );
    }

    // idle → start button
    final enabled = connected && !otherBusy;
    return GestureDetector(
      onTap: enabled ? () => _startCapture(leg) : null,
      child: _tileShell(
        w,
        accent: enabled ? KColors.greenDark : const Color(0xFFC3CBDD),
        filled: enabled,
        child: Column(
          children: [
            Icon(Icons.play_arrow_rounded,
                color: enabled ? Colors.white : const Color(0xFF9AA5BF),
                size: w * 0.07),
            SizedBox(height: w * 0.01),
            Text('วัด$label',
                textAlign: TextAlign.center,
                style: thaiSans(
                    size: w * 0.036,
                    weight: FontWeight.w800,
                    color: enabled ? Colors.white : const Color(0xFF9AA5BF))),
          ],
        ),
      ),
    );
  }

  void _remeasure(Muscle m, LegSide leg) {
    setState(() => _captures[m]?.remove(leg));
    _startCapture(leg);
  }

  Widget _tileShell(double w,
      {required Widget child, required Color accent, bool filled = false}) {
    return Container(
      padding: EdgeInsets.all(w * 0.035),
      decoration: BoxDecoration(
        gradient: filled
            ? const LinearGradient(colors: [KColors.greenLight, KColors.greenDark])
            : null,
        color: filled ? null : Colors.white,
        borderRadius: BorderRadius.circular(w * 0.04),
        border: filled ? null : Border.all(color: accent.withValues(alpha: 0.35)),
        boxShadow: filled
            ? const [
                BoxShadow(
                    color: Color(0x335EC832),
                    blurRadius: 14,
                    offset: Offset(0, 6))
              ]
            : null,
      ),
      child: child,
    );
  }

  Widget _greenBar(double w, double value) {
    return Container(
      height: w * 0.045,
      decoration: BoxDecoration(
        color: const Color(0xFFE2EFD9),
        borderRadius: BorderRadius.circular(w * 0.03),
      ),
      clipBehavior: Clip.antiAlias,
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: value.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [KColors.greenLight, KColors.greenDark],
              ),
              borderRadius: BorderRadius.circular(w * 0.03),
            ),
          ),
        ),
      ),
    );
  }

  Widget _resultCard(double w, Muscle m) {
    final l = _captures[m]?[LegSide.left];
    final r = _captures[m]?[LegSide.right];
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(w * 0.045),
      decoration: BoxDecoration(
        color: const Color(0xFFF1FAEC),
        borderRadius: BorderRadius.circular(w * 0.05),
        border: Border.all(color: KColors.greenDark.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_rounded,
                  color: KColors.greenDark, size: w * 0.055),
              SizedBox(width: w * 0.02),
              Flexible(
                child: Text('วัด ${m.thaiName} (${m.code}) สำเร็จ',
                    textAlign: TextAlign.center,
                    style: thaiSans(
                        size: w * 0.04,
                        weight: FontWeight.w800,
                        color: KColors.greenDark)),
              ),
            ],
          ),
          SizedBox(height: w * 0.035),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _sideBlock(w, 'ขาซ้าย (L)', KColors.blue, l)),
              SizedBox(width: w * 0.03),
              Expanded(child: _sideBlock(w, 'ขาขวา (R)', KColors.blue, r)),
            ],
          ),
          SizedBox(height: w * 0.02),
          GestureDetector(
            onTap: () => setState(() => _captures.remove(m)),
            child: Text('วัดกล้ามเนื้อนี้ใหม่',
                style: thaiSans(
                    size: w * 0.034,
                    weight: FontWeight.w700,
                    color: KColors.blue)),
          ),
        ],
      ),
    );
  }

  Widget _sideBlock(double w, String label, Color accent, _LegCapture? s) {
    return Container(
      padding: EdgeInsets.all(w * 0.035),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(w * 0.035),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Container(
            padding:
                EdgeInsets.symmetric(horizontal: w * 0.025, vertical: w * 0.008),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(w * 0.05),
            ),
            child: Text(label,
                style: thaiSans(
                    size: w * 0.034, weight: FontWeight.w800, color: accent)),
          ),
          SizedBox(height: w * 0.02),
          _kv(w, 'Mean', s == null ? '—' : '${s.mean.toStringAsFixed(0)} µV'),
          _kv(w, 'Peak', s == null ? '—' : '${s.max.toStringAsFixed(0)} µV'),
          _kv(w, 'Min', s == null ? '—' : '${s.min.toStringAsFixed(0)} µV'),
          _kv(w, '%MVC',
              s == null ? '—' : '${s.percentMvc.toStringAsFixed(0)}%'),
        ],
      ),
    );
  }

  Widget _kv(double w, String k, String v) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: w * 0.006),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k,
              style:
                  thaiSans(size: w * 0.032, color: const Color(0xFF7A88A6))),
          Text(v,
              style: montserrat(
                  size: w * 0.036,
                  weight: FontWeight.w800,
                  color: KColors.navyText)),
        ],
      ),
    );
  }

  Widget _summaryCard(double w) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(w * 0.05),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(w * 0.05),
        boxShadow: const [
          BoxShadow(
              color: Color(0x14000000), blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Text('สรุปค่ากล้ามเนื้อ (MVC)',
              style: thaiSans(
                  size: w * 0.045,
                  weight: FontWeight.w800,
                  color: KColors.navyText)),
          SizedBox(height: w * 0.03),
          for (var n = 1; n <= 4; n++) _summaryRow(w, _padMuscles[n - 1]),
        ],
      ),
    );
  }

  Widget _summaryRow(double w, Muscle m) {
    final l = _captures[m]?[LegSide.left];
    final r = _captures[m]?[LegSide.right];
    String peakStr(_LegCapture? s) =>
        s == null ? '—' : '${s.max.toStringAsFixed(0)}µV';
    return Padding(
      padding: EdgeInsets.symmetric(vertical: w * 0.014),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text('${m.code} · ${m.thaiName}',
                style: thaiSans(
                    size: w * 0.036,
                    weight: FontWeight.w700,
                    color: KColors.navyText)),
          ),
          Expanded(
            flex: 3,
            child: Text('L ${peakStr(l)}',
                textAlign: TextAlign.right,
                style: thaiSans(
                    size: w * 0.034,
                    weight: FontWeight.w700,
                    color: KColors.blue)),
          ),
          Expanded(
            flex: 3,
            child: Text('R ${peakStr(r)}',
                textAlign: TextAlign.right,
                style: thaiSans(
                    size: w * 0.034,
                    weight: FontWeight.w700,
                    color: KColors.blue)),
          ),
        ],
      ),
    );
  }

  Widget _imageCard(double w, _GuideStep step) {
    final radius = w * 0.075;
    return Container(
      width: double.infinity,
      height: w * 1.0,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
              color: Color(0x18000000), blurRadius: 28, offset: Offset(0, 14)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: step.imagePath == null
          ? const SizedBox.shrink()
          : Image.asset(step.imagePath!, fit: BoxFit.cover),
    );
  }

  // ---- Bottom button -------------------------------------------------------
  Widget _buildBottom(double w, _GuideStep step) {
    switch (step.kind) {
      case _StepKind.done:
        return _primaryButton(w, 'เริ่มใช้งาน', _finish);
      case _StepKind.welcome:
      case _StepKind.install:
        return _primaryButton(w, 'ถัดไป', _next);
      case _StepKind.measure:
        // Advance only after BOTH legs of this muscle are captured.
        if (_muscleDone(step.muscle)) return _primaryButton(w, 'ถัดไป', _next);
        return Center(
          child: Text(
            _capturingLeg != null
                ? 'กำลังวัดค่า...'
                : 'ยกขาแล้วแตะปุ่มขาซ้าย/ขวา เพื่อเริ่มวัด',
            style: thaiSans(
                size: w * 0.04,
                weight: FontWeight.w500,
                color: const Color(0xFF8C99B5)),
          ),
        );
    }
  }

  Widget _primaryButton(double w, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: w * 0.15,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: KColors.blueGradient,
          borderRadius: BorderRadius.circular(w * 0.075),
          boxShadow: const [
            BoxShadow(
                color: Color(0x402766EF),
                blurRadius: 18,
                offset: Offset(0, 8)),
          ],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label,
              style: thaiSans(
                  size: w * 0.05,
                  weight: FontWeight.w700,
                  color: Colors.white)),
        ),
      ),
    );
  }

  // ---- Shared text helpers -------------------------------------------------
  Widget _title(double w, String text) {
    return Text(
      text,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: thaiSans(
          size: w * 0.062, weight: FontWeight.w700, color: KColors.navyText),
    );
  }

  Widget _bodyText(double w, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: w * 0.02),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: thaiSans(
            size: w * 0.043,
            weight: FontWeight.w400,
            color: const Color(0xFF5A6685)),
      ),
    );
  }
}
