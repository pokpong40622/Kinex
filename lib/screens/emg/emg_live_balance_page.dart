// Live left/right co-contraction (CCI) view for the two leg ESP32 boards.
//
// This is a direct port of the reference dashboard Test_Kinex_EMG.py, so the
// numbers shown here match what that script plots. Key consequences of that,
// which differ from the rest of the app's EMG code:
//
//  * The boards PUSH all four channels continuously (VL,BF,TA,GCM) — there is
//    no START/STOP handshake and no per-channel polling. Do not add one.
//  * %MVC is self-calibrating: each channel's RMS is divided by the largest
//    RMS seen since this screen opened, so it needs no stored MVC calibration
//    from the hardware guide.
//  * CCI here is low/high (Python's `cci()`), NOT the 2·min/(a+b) form used by
//    JointBalance.cci elsewhere in the app. The two are different curves; this
//    file deliberately follows the Python.
//
// Each board spends its first CALIBRATION_SECONDS at rest establishing a
// per-channel baseline and noise floor, exactly as the script does.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../ble/ble_service.dart';
import '../../ble/emg_pipeline.dart';
import '../../ble/emg_session.dart';
import '../../models/muscle.dart';
import '../../theme/app_theme.dart';
import '../../theme/kui.dart';
import '../../theme/responsive.dart';

class EmgLiveBalancePage extends ConsumerStatefulWidget {
  const EmgLiveBalancePage({super.key});

  @override
  ConsumerState<EmgLiveBalancePage> createState() => _EmgLiveBalancePageState();
}

class _EmgLiveBalancePageState extends ConsumerState<EmgLiveBalancePage> {
  /// Owned by [emgSessionProvider], not this page — shared with the graph
  /// page so calibration survives navigation between them.
  Map<LegSide, EmgLegMetrics> get _legs => ref.read(emgSessionProvider).legs;
  final Map<LegSide, StreamSubscription<String>?> _subs = {};
  final Map<LegSide, bool> _listening = {
    LegSide.left: false,
    LegSide.right: false,
  };
  DateTime _lastPaint = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
    // Drives the calibration countdown, which changes with the clock rather
    // than with incoming samples.
    _tick = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() {});
    });
  }

  BleController _controllerFor(LegSide leg) => leg == LegSide.left
      ? ref.read(bleControllerProvider.notifier)
      : ref.read(legRBleProvider.notifier);

  bool _isConnected(LegSide leg) =>
      (leg == LegSide.left
          ? ref.read(bleControllerProvider).status
          : ref.read(legRBleProvider).status) ==
      BleStatus.connected;

  /// Attach/detach each leg's listener to match its connection state.
  void _sync() {
    for (final leg in LegSide.values) {
      final connected = _isConnected(leg);
      final listening = _listening[leg] ?? false;
      if (connected && !listening) {
        _subs[leg]?.cancel();
        // Calibration state lives in emgSessionProvider now, not per page —
        // do NOT reset here, or navigating between EMG pages would restart
        // an already-calibrated leg's 30 s window.
        _subs[leg] = _controllerFor(leg).incoming.listen((l) => _onLine(leg, l));
        _listening[leg] = true;
      } else if (!connected && listening) {
        _subs[leg]?.cancel();
        _subs[leg] = null;
        _listening[leg] = false;
      }
    }
  }

  void _onLine(LegSide leg, String line) {
    final values = parseEmgLine(line);
    if (values.length < kEmgChannels) return;
    _legs[leg]!.update(values);

    final now = DateTime.now();
    if (now.difference(_lastPaint) < kEmgPaintInterval) return;
    _lastPaint = now;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tick?.cancel();
    for (final s in _subs.values) {
      s?.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(bleControllerProvider, (_, _) => _sync());
    ref.listen(legRBleProvider, (_, _) => _sync());

    final leftOn = ref.watch(bleControllerProvider).status == BleStatus.connected;
    final rightOn = ref.watch(legRBleProvider).status == BleStatus.connected;
    final anyCalibrating = (leftOn && !_legs[LegSide.left]!.calibrated) ||
        (rightOn && !_legs[LegSide.right]!.calibrated);

    return Scaffold(
      backgroundColor: KColors.appBg,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(context.r(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(context, leftOn, rightOn),
              SizedBox(height: context.r(14)),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!leftOn || !rightOn)
                        _connectionNotice(context, leftOn, rightOn),
                      if ((!leftOn || !rightOn) && anyCalibrating)
                        SizedBox(height: context.r(14)),
                      if (anyCalibrating) _calibrationNotice(context),
                      if (leftOn || rightOn) ...[
                        SizedBox(height: context.r(14)),
                        _jointCard(context, 'ข้อเข่า', 'VL – BF',
                            (m) => m.kneeCci, leftOn, rightOn),
                        SizedBox(height: context.r(14)),
                        _jointCard(context, 'ข้อเท้า', 'TA – GCM',
                            (m) => m.ankleCci, leftOn, rightOn),
                        SizedBox(height: context.r(14)),
                        _recalibrateCard(context, leftOn, rightOn),
                      ],
                      SizedBox(height: context.r(14)),
                      _footerNote(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- Header --------------------------------------------------------------
  Widget _header(BuildContext context, bool leftOn, bool rightOn) {
    return Row(
      children: [
        Material(
          color: Colors.white,
          shape: const CircleBorder(),
          elevation: 1,
          child: IconButton(
            onPressed: () => context.pop(),
            icon: Icon(Icons.arrow_back_rounded, color: KColors.navyText),
          ),
        ),
        SizedBox(width: context.r(8)),
        Expanded(
          child: Text(
            'สมดุลกล้ามเนื้อ (เรียลไทม์)',
            style: montserrat(
                size: context.r(17),
                weight: FontWeight.w900,
                color: KColors.navyText),
          ),
        ),
        _legDot(context, 'L', leftOn),
        SizedBox(width: context.r(8)),
        _legDot(context, 'R', rightOn),
      ],
    );
  }

  Widget _legDot(BuildContext context, String label, bool connected) {
    final c = connected ? KColors.teal : const Color(0xFFC3CBDD);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: context.r(8),
          height: context.r(8),
          decoration: BoxDecoration(shape: BoxShape.circle, color: c),
        ),
        SizedBox(width: context.r(4)),
        Text(label,
            style: montserrat(
                size: context.r(12), weight: FontWeight.w800, color: c)),
      ],
    );
  }

  // ---- Notices -------------------------------------------------------------
  Widget _warningBox(
      BuildContext context, IconData icon, String title, String body) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.r(16)),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(context.r(16)),
        border: Border.all(color: const Color(0xFFFFB300)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFE65100), size: context.r(30)),
          SizedBox(height: context.r(10)),
          Text(title,
              textAlign: TextAlign.center,
              style: thaiSans(
                  size: context.r(15),
                  weight: FontWeight.w700,
                  color: const Color(0xFFE65100))),
          SizedBox(height: context.r(6)),
          Text(body,
              textAlign: TextAlign.center,
              style: thaiSans(
                  size: context.r(13), color: const Color(0xFF8C6A1E))),
        ],
      ),
    );
  }

  Widget _connectionNotice(BuildContext context, bool leftOn, bool rightOn) {
    final title = !leftOn && !rightOn
        ? 'ยังไม่ได้เชื่อมต่อบอร์ด EMG ทั้งสองข้าง'
        : !leftOn
            ? 'ยังไม่ได้เชื่อมต่อบอร์ด EMG ขาซ้าย'
            : 'ยังไม่ได้เชื่อมต่อบอร์ด EMG ขาขวา';
    return _warningBox(context, Icons.bluetooth_disabled_rounded, title,
        'ข้างที่เชื่อมต่ออยู่ยังแสดงค่าได้ตามปกติ');
  }

  Widget _calibrationNotice(BuildContext context) {
    String secs(LegSide leg) {
      final r = _legs[leg]!.calibrationRemaining;
      return r == null ? 'พร้อม' : '${r.ceil()} วิ';
    }

    final left = ref.read(bleControllerProvider).status == BleStatus.connected;
    final right = ref.read(legRBleProvider).status == BleStatus.connected;
    final parts = <String>[
      if (left) 'ซ้าย ${secs(LegSide.left)}',
      if (right) 'ขวา ${secs(LegSide.right)}',
    ];
    return _warningBox(
        context,
        Icons.timer_outlined,
        'กำลังตั้งค่าเริ่มต้น — ${parts.join('  ·  ')}',
        'กรุณาวางขานิ่ง ๆ ระหว่างนี้ ระบบกำลังวัดค่าพื้นฐานและระดับสัญญาณรบกวนของแต่ละกล้ามเนื้อ');
  }

  // ---- Joint card ----------------------------------------------------------
  Widget _jointCard(
    BuildContext context,
    String thaiLabel,
    String pairLabel,
    double Function(EmgLegMetrics) pick,
    bool leftOn,
    bool rightOn,
  ) {
    double? valueFor(LegSide leg, bool connected) {
      final m = _legs[leg]!;
      if (!connected || !m.calibrated) return null;
      return pick(m);
    }

    return KCard(
      radius: context.r(20),
      padding: EdgeInsets.all(context.r(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(thaiLabel,
                  style: montserrat(
                      size: context.r(16),
                      weight: FontWeight.w900,
                      color: KColors.deepPurple)),
              SizedBox(width: context.r(8)),
              Text(pairLabel,
                  style: montserrat(
                      size: context.r(11.5),
                      weight: FontWeight.w700,
                      color: const Color(0xFF9099BC))),
            ],
          ),
          SizedBox(height: context.r(2)),
          Text('CCI (ดัชนีการหดตัวร่วม)',
              style: montserrat(
                  size: context.r(11.5),
                  weight: FontWeight.w500,
                  color: const Color(0xFF6D78A8))),
          SizedBox(height: context.r(12)),
          Row(
            children: [
              Expanded(
                  child: _cciTile(context, 'ขาซ้าย', KColors.indigo,
                      valueFor(LegSide.left, leftOn))),
              SizedBox(width: context.r(10)),
              Expanded(
                  child: _cciTile(context, 'ขาขวา', const Color(0xFFFA7F00),
                      valueFor(LegSide.right, rightOn))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cciTile(
      BuildContext context, String label, Color color, double? cci) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: context.r(12)),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(context.r(14)),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(label,
              style: montserrat(
                  size: context.r(12.5),
                  weight: FontWeight.w800,
                  color: color)),
          SizedBox(height: context.r(4)),
          Text(cci == null ? '—' : '${cci.toStringAsFixed(0)}%',
              style: montserrat(
                  size: context.r(26),
                  weight: FontWeight.w900,
                  color: color)),
          SizedBox(height: context.r(6)),
          _bar(context, cci, color),
        ],
      ),
    );
  }

  /// 0–100% fill so the two legs can be compared at a glance, not just read.
  Widget _bar(BuildContext context, double? cci, Color color) {
    final frac = ((cci ?? 0) / 100).clamp(0.0, 1.0);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.r(14)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(context.r(4)),
        child: LinearProgressIndicator(
          value: frac,
          minHeight: context.r(6),
          backgroundColor: color.withValues(alpha: 0.15),
          valueColor: AlwaysStoppedAnimation<Color>(
              cci == null ? Colors.transparent : color),
        ),
      ),
    );
  }

  // ---- Recalibrate -----------------------------------------------------------
  Widget _recalibrateCard(BuildContext context, bool leftOn, bool rightOn) {
    return KCard(
      radius: context.r(20),
      padding: EdgeInsets.all(context.r(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (leftOn) _recalibrateRow(context, LegSide.left),
          if (leftOn && rightOn) SizedBox(height: context.r(10)),
          if (rightOn) _recalibrateRow(context, LegSide.right),
        ],
      ),
    );
  }

  Widget _recalibrateRow(BuildContext context, LegSide leg) {
    final m = _legs[leg]!;
    final label = leg == LegSide.left
        ? 'ปรับเทียบใหม่ (ขาซ้าย)'
        : 'ปรับเทียบใหม่ (ขาขวา)';
    final calibratedAt = m.calibratedAt;
    return Row(
      children: [
        Expanded(
          child: Text(
            calibratedAt == null
                ? 'ยังไม่ได้ปรับเทียบ'
                : 'ปรับเทียบเมื่อ ${DateFormat('d MMM HH:mm').format(calibratedAt)}',
            style: montserrat(
                size: context.r(11.5),
                weight: FontWeight.w600,
                color: const Color(0xFF6D78A8)),
          ),
        ),
        SizedBox(width: context.r(8)),
        TextButton(
          onPressed: () async {
            await ref.read(emgSessionProvider).recalibrate(leg);
            if (mounted) setState(() {});
          },
          style: TextButton.styleFrom(
            foregroundColor: KColors.deepPurple,
            padding: EdgeInsets.symmetric(horizontal: context.r(10)),
          ),
          child: Text(label,
              style:
                  montserrat(size: context.r(12), weight: FontWeight.w800)),
        ),
      ],
    );
  }

  // ---- Footer note ---------------------------------------------------------
  Widget _footerNote(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.r(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(14)),
        border: Border.all(color: KColors.hairline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              size: context.r(16), color: const Color(0xFF9099BC)),
          SizedBox(width: context.r(8)),
          Expanded(
            child: Text(
              'CCI = กล้ามเนื้อที่ทำงานน้อยกว่า ÷ กล้ามเนื้อที่ทำงานมากกว่า × 100 '
              '(100% = ทำงานพอ ๆ กันทั้งคู่)  ·  %MVC เทียบกับแรงสูงสุดที่วัดได้ '
              'นับตั้งแต่เปิดหน้านี้ ค่าจึงปรับตัวขึ้นเมื่อออกแรงมากกว่าเดิม',
              style: montserrat(
                  size: context.r(11),
                  weight: FontWeight.w500,
                  color: const Color(0xFF9099BC)),
            ),
          ),
        ],
      ),
    );
  }
}
