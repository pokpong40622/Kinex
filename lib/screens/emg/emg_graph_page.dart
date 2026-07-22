// Full 5-group EMG dashboard for both legs — a Flutter reproduction of the
// reference Python dashboard (Test_Kinex_EMG.py). Per leg it shows:
//   1. Raw EMG   — scrolling 4-trace line chart, last ~20 s, y = 0..kAdcMax
//   2. RMS + RMS peak — 4 bars with a peak marker line per muscle
//   3. %MVC      — 4 bars, 0..100
//   4. CCI       — 2 bars (Knee VL-BF, Ankle TA-GCM), 0..100
//   5. Stability — 1 bar, 0..100, plus numeric value + เกร็ง/ไม่เกร็ง label
//
// Signal chain (parsing, RMS, %MVC, CCI) lives entirely in emg_pipeline.dart —
// this file only reads EmgLegMetrics and draws it. Wiring (which controller
// feeds which leg, throttled repaint, reset-on-reconnect) mirrors
// emg_live_balance_page.dart exactly; see that file's header comment for why
// there is no START/STOP handshake here.
import 'dart:async';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
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

/// How far back the raw-EMG trace scrolls, matching Python's
/// PLOT_HISTORY_SECONDS.
const double _plotHistorySeconds = 20.0;

/// Peak-marker line color, matching Python's `ax_rms` axhline color.
const Color _peakLineColor = Color(0xFFE45756);

/// Per-muscle trace/legend colors — VL/BF/TA/GCM, same order and palette the
/// app already uses in emg_detail_page.dart. Not const: KColors.purple is a
/// mutable accent that can be reskinned at runtime (shop "ธีมสี").
List<Color> get _muscleColors => [
      KColors.purple,
      KColors.orange,
      KColors.teal,
      KColors.blue,
    ];

class EmgGraphPage extends ConsumerStatefulWidget {
  const EmgGraphPage({super.key});

  @override
  ConsumerState<EmgGraphPage> createState() => _EmgGraphPageState();
}

class _EmgGraphPageState extends ConsumerState<EmgGraphPage> {
  /// Owned by [emgSessionProvider], not this page — shared with the live
  /// balance page so calibration survives navigation between them.
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
    // Drives the calibration countdown and the raw-EMG scroll window, both of
    // which change with the clock rather than with incoming samples.
    _tick = Timer.periodic(const Duration(milliseconds: 200), (_) {
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
                      _legCard(context, LegSide.left, 'ขาซ้าย (Left Leg)', leftOn),
                      SizedBox(height: context.r(14)),
                      _legCard(context, LegSide.right, 'ขาขวา (Right Leg)', rightOn),
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
            'กราฟ EMG',
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

  // ---- Leg card --------------------------------------------------------------
  Widget _legCard(
      BuildContext context, LegSide leg, String legLabel, bool connected) {
    final m = _legs[leg]!;
    return KCard(
      radius: context.r(20),
      padding: EdgeInsets.all(context.r(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _legHeader(context, legLabel, connected, m),
          SizedBox(height: context.r(10)),
          if (!connected)
            _inlineNotice(
              context,
              Icons.bluetooth_disabled_rounded,
              'ยังไม่ได้เชื่อมต่อบอร์ด EMG ข้างนี้',
            )
          else if (!m.calibrated)
            _inlineNotice(
              context,
              Icons.timer_outlined,
              'กำลังตั้งค่าเริ่มต้น — ${(m.calibrationRemaining ?? 0).ceil()} วิ',
              'กรุณาวางขานิ่ง ๆ ระหว่างนี้ ระบบกำลังวัดค่าพื้นฐานและระดับสัญญาณรบกวน',
            )
          else ...[
            _groupTitle(context, 'คลื่นไฟฟ้ากล้ามเนื้อ (Raw EMG)'),
            _rawEmgChart(context, m),
            _legend(context, m),
            SizedBox(height: context.r(12)),
            _groupTitle(context, 'RMS และ RMS สูงสุด'),
            _rmsBars(context, m),
            SizedBox(height: context.r(14)),
            _groupTitle(context, '%MVC'),
            _mvcBars(context, m),
            SizedBox(height: context.r(14)),
            _groupTitle(context, 'ดัชนีการหดตัวร่วม (CCI)'),
            _cciBars(context, m),
            SizedBox(height: context.r(14)),
            _groupTitle(context, 'ความมั่นคง (Stability)'),
            _stabilityRow(context, m),
          ],
          if (connected) ...[
            SizedBox(height: context.r(12)),
            _recalibrateRow(context, leg),
          ],
        ],
      ),
    );
  }

  // ---- Recalibrate -----------------------------------------------------------
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
                size: context.r(11),
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
                  montserrat(size: context.r(11.5), weight: FontWeight.w800)),
        ),
      ],
    );
  }

  Widget _legHeader(
      BuildContext context, String legLabel, bool connected, EmgLegMetrics m) {
    final statusText = !connected
        ? 'ไม่ได้เชื่อมต่อ'
        : !m.calibrated
            ? 'ตั้งค่าเริ่มต้น ${(m.calibrationRemaining ?? 0).ceil()} วิ'
            : 'ทำงานปกติ';
    final dotColor = !connected
        ? const Color(0xFFC3CBDD)
        : !m.calibrated
            ? KColors.orangeDark
            : KColors.teal;
    return Row(
      children: [
        Text(legLabel,
            style: montserrat(
                size: context.r(15.5),
                weight: FontWeight.w900,
                color: KColors.deepPurple)),
        SizedBox(width: context.r(8)),
        Container(
          width: context.r(7),
          height: context.r(7),
          decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
        ),
        SizedBox(width: context.r(5)),
        Text(statusText,
            style: montserrat(
                size: context.r(11.5),
                weight: FontWeight.w700,
                color: dotColor)),
      ],
    );
  }

  Widget _inlineNotice(BuildContext context, IconData icon, String title,
      [String? body]) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.r(14)),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(context.r(14)),
        border: Border.all(color: const Color(0xFFFFB300)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFE65100), size: context.r(24)),
          SizedBox(height: context.r(6)),
          Text(title,
              textAlign: TextAlign.center,
              style: thaiSans(
                  size: context.r(13.5),
                  weight: FontWeight.w700,
                  color: const Color(0xFFE65100))),
          if (body != null) ...[
            SizedBox(height: context.r(4)),
            Text(body,
                textAlign: TextAlign.center,
                style: thaiSans(
                    size: context.r(11.5), color: const Color(0xFF8C6A1E))),
          ],
        ],
      ),
    );
  }

  Widget _groupTitle(BuildContext context, String title) => Padding(
        padding: EdgeInsets.only(bottom: context.r(6)),
        child: Text(title,
            style: montserrat(
                size: context.r(12.5),
                weight: FontWeight.w800,
                color: KColors.deepPurple)),
      );

  // ---- Group 1: Raw EMG ------------------------------------------------------
  Widget _rawEmgChart(BuildContext context, EmgLegMetrics m) {
    final now = DateTime.now();
    final items = m.history
        .where((f) =>
            now.difference(f.t).inMilliseconds / 1000.0 <= _plotHistorySeconds)
        .toList();

    final spotsByChannel = List.generate(kEmgChannels, (_) => <FlSpot>[]);
    double lastElapsed = 0;
    if (items.isNotEmpty) {
      final t0 = items.first.t;
      for (final item in items) {
        final elapsed = item.t.difference(t0).inMilliseconds / 1000.0;
        for (var c = 0; c < kEmgChannels; c++) {
          spotsByChannel[c].add(FlSpot(elapsed, item.raw[c]));
        }
      }
      lastElapsed = spotsByChannel[0].last.x;
    }
    final maxX = max(_plotHistorySeconds, lastElapsed);

    return Container(
      height: context.r(150),
      padding: EdgeInsets.fromLTRB(
          context.r(2), context.r(10), context.r(10), context.r(4)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(14)),
        border: Border.all(color: KColors.hairline),
      ),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: maxX,
          minY: 0,
          maxY: kAdcMax,
          clipData: const FlClipData.all(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: kAdcMax / 4,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: Colors.black12, strokeWidth: 0.6),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: kAdcMax / 4,
                reservedSize: context.r(32),
                getTitlesWidget: (v, meta) => Text(
                  v.toInt().toString(),
                  style: montserrat(
                      size: context.r(9),
                      weight: FontWeight.w500,
                      color: KColors.navyText.withValues(alpha: 0.6)),
                ),
              ),
            ),
            bottomTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            for (var c = 0; c < kEmgChannels; c++)
              LineChartBarData(
                spots: spotsByChannel[c],
                isCurved: false,
                color: _muscleColors[c],
                barWidth: context.r(1.2),
                dotData: const FlDotData(show: false),
              ),
          ],
        ),
      ),
    );
  }

  Widget _legend(BuildContext context, EmgLegMetrics m) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.r(6)),
      child: Wrap(
        spacing: context.r(12),
        runSpacing: context.r(4),
        children: [
          for (var c = 0; c < kEmgChannels; c++)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: context.r(9),
                  height: context.r(9),
                  decoration: BoxDecoration(
                      shape: BoxShape.circle, color: _muscleColors[c]),
                ),
                SizedBox(width: context.r(4)),
                Text('${kMuscleLabels[c]} ${m.raw[c].toInt()}',
                    style: montserrat(
                        size: context.r(11),
                        weight: FontWeight.w700,
                        color: KColors.navyText)),
              ],
            ),
        ],
      ),
    );
  }

  // ---- Groups 2-5: bars -------------------------------------------------------
  Widget _rmsBars(BuildContext context, EmgLegMetrics m) {
    final bars = [
      for (var c = 0; c < kEmgChannels; c++)
        _BarSpec(kMuscleLabels[c], m.rmsValues[c], KColors.blue,
            peak: m.rmsPeak[c]),
    ];
    // Mirrors Python's _scale_axis(rms + rms_peak, minimum=50).
    final allVals = [...m.rmsValues, ...m.rmsPeak];
    final axisMax = max(50.0, allVals.reduce(max) * 1.2);
    return _barRow(context, bars, axisMax);
  }

  Widget _mvcBars(BuildContext context, EmgLegMetrics m) {
    final bars = [
      for (var c = 0; c < kEmgChannels; c++)
        _BarSpec(kMuscleLabels[c], m.mvc[c], KColors.greenDark),
    ];
    return _barRow(context, bars, 100);
  }

  Widget _cciBars(BuildContext context, EmgLegMetrics m) {
    final bars = [
      _BarSpec('Knee\nVL-BF', m.kneeCci, KColors.orange),
      _BarSpec('Ankle\nTA-GCM', m.ankleCci, KColors.purple),
    ];
    return _barRow(context, bars, 100, height: 78);
  }

  Widget _stabilityRow(BuildContext context, EmgLegMetrics m) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: context.r(84),
          child:
              _barRow(context, [_BarSpec('Stability', m.stability, KColors.teal)], 100, height: 64),
        ),
        SizedBox(width: context.r(16)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(m.stability.toStringAsFixed(1),
                  style: montserrat(
                      size: context.r(22),
                      weight: FontWeight.w900,
                      color: KColors.navyText)),
              SizedBox(height: context.r(6)),
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: context.r(10), vertical: context.r(4)),
                decoration: BoxDecoration(
                  color: (m.isContracting ? KColors.teal : const Color(0xFF9099BC))
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                      color: (m.isContracting
                              ? KColors.teal
                              : const Color(0xFF9099BC))
                          .withValues(alpha: 0.35)),
                ),
                child: Text(
                  m.isContracting ? 'เกร็ง' : 'ไม่เกร็ง',
                  style: thaiSans(
                      size: context.r(12.5),
                      weight: FontWeight.w800,
                      color: m.isContracting
                          ? KColors.tealDark
                          : const Color(0xFF6D78A8)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Renders a row of vertical bars. [axisMax] is the value at full bar height
  /// (0..axisMax mapped to 0..[height]); each bar optionally shows a thin peak
  /// marker line (RMS group only).
  Widget _barRow(BuildContext context, List<_BarSpec> bars, double axisMax,
      {double height = 88}) {
    final h = context.r(height);
    final scale = max(1.0, axisMax);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final b in bars)
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: context.r(5)),
              child: Column(
                children: [
                  Text(
                    b.value.toStringAsFixed(b.value >= 10 ? 0 : 1),
                    style: montserrat(
                        size: context.r(11),
                        weight: FontWeight.w800,
                        color: b.color),
                  ),
                  SizedBox(height: context.r(4)),
                  SizedBox(
                    height: h,
                    width: double.infinity,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: b.color.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(context.r(6)),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          height: (b.value / scale).clamp(0.0, 1.0) * h,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: b.color,
                              borderRadius: BorderRadius.circular(context.r(6)),
                            ),
                          ),
                        ),
                        if (b.peak != null)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom:
                                (((b.peak! / scale).clamp(0.0, 1.0) * h) -
                                        context.r(1))
                                    .clamp(0.0, h),
                            height: context.r(2),
                            child: Container(color: _peakLineColor),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: context.r(4)),
                  Text(
                    b.label,
                    textAlign: TextAlign.center,
                    style: montserrat(
                        size: context.r(10.5),
                        weight: FontWeight.w700,
                        color: KColors.navyText.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
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
              'ทั้งสองบอร์ดจะ calibrate ท่านิ่ง 30 วินาทีแรกหลังเชื่อมต่อ '
              'RMS peak (เส้นสีแดง) คือแรงสูงสุดที่วัดได้นับตั้งแต่ calibrate เสร็จ '
              '%MVC จึงปรับตัวขึ้นเมื่อออกแรงมากกว่าเดิม',
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

/// One bar's data for [_EmgGraphPageState._barRow].
class _BarSpec {
  final String label;
  final double value;
  final Color color;
  final double? peak;
  const _BarSpec(this.label, this.value, this.color, {this.peak});
}
