import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../ble/ble_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive.dart';

/// Realtime 4-channel EMG graph (right leg: VL / BF / TA / GCM). Reached after
/// the 6-digit gate. On entry it tells the ESP32 to STREAM:ON and plots the
/// incoming `EMG4:v0,v1,v2,v3` lines; on exit it sends STREAM:OFF.
class EmgDetailPage extends ConsumerStatefulWidget {
  const EmgDetailPage({super.key});

  @override
  ConsumerState<EmgDetailPage> createState() => _EmgDetailPageState();
}

class _Channel {
  final String label;
  final Color color;
  const _Channel(this.label, this.color);
}

// Channel order MUST match the firmware's EMG_PINS[] (pin7=VL, 6=BF, 5=TA, 4=GCM).
const List<_Channel> _channels = [
  _Channel('VL', KColors.purple),
  _Channel('BF', KColors.orange),
  _Channel('TA', KColors.teal),
  _Channel('GCM', KColors.blue),
];

const int _windowLen = 200;   // ~10 s at 20 Hz (serial-plotter-like history)
const double _adcMax = 4095;  // 12-bit raw ADC ceiling

class _EmgDetailPageState extends ConsumerState<EmgDetailPage> {
  BleController? _ctl;
  StreamSubscription<String>? _sub;
  final List<List<double>> _buf = [[], [], [], []];

  @override
  void initState() {
    super.initState();
    // Start after first frame so ref is safe to read.
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  void _start() {
    if (ref.read(bleControllerProvider).status != BleStatus.connected) return;
    final ctl = ref.read(bleControllerProvider.notifier);
    _ctl = ctl;
    _sub = ctl.incoming.listen(_onLine);
    ctl.send('STREAM:ON');
  }

  void _onLine(String line) {
    if (!line.startsWith('EMG4:')) return;
    final parts = line.substring(5).split(',');
    if (parts.length != 4) return;
    final vals = <double>[];
    for (final p in parts) {
      final v = double.tryParse(p.trim());
      if (v == null) return; // malformed → drop the whole sample
      vals.add(v);
    }
    for (var i = 0; i < 4; i++) {
      final b = _buf[i];
      b.add(vals[i]);
      if (b.length > _windowLen) b.removeAt(0);
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ctl?.send('STREAM:OFF');
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connected =
        ref.watch(bleControllerProvider).status == BleStatus.connected;
    return Scaffold(
      backgroundColor: const Color(0xFF0E1630),
      body: SafeArea(
        child: connected ? _graphView(context) : _disconnectedView(context),
      ),
    );
  }

  Widget _graphView(BuildContext context) {
    return Column(
      children: [
        _header(context),
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                context.r(16), 0, context.r(16), context.r(12)),
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  context.r(8), context.r(16), context.r(14), context.r(10)),
              decoration: cardDecoration(radius: 22, color: Colors.white),
              child: LineChart(_chartData()),
            ),
          ),
        ),
        _legend(context),
        SizedBox(height: context.r(12)),
        _stopButton(context),
        SizedBox(height: context.r(16)),
      ],
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          context.r(6), context.r(6), context.r(16), context.r(6)),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          Text(
            'EMG เรียลไทม์',
            style: thaiSans(
                size: context.r(20),
                weight: FontWeight.w800,
                color: Colors.white),
          ),
          const Spacer(),
          Container(
            width: context.r(9),
            height: context.r(9),
            decoration: const BoxDecoration(
                shape: BoxShape.circle, color: KColors.teal),
          ),
          SizedBox(width: context.r(6)),
          Text('LIVE',
              style: montserrat(
                  size: context.r(12),
                  weight: FontWeight.w800,
                  color: KColors.teal)),
        ],
      ),
    );
  }

  LineChartData _chartData() {
    // Auto-scale the Y axis to the visible data (like a serial plotter), so the
    // traces fill the card regardless of whether the signal is a raw wave or an
    // envelope. Falls back to the full 0–4095 range before any data arrives.
    double lo = 0, hi = _adcMax;
    bool any = false;
    for (final b in _buf) {
      for (final v in b) {
        if (!any) {
          lo = v;
          hi = v;
          any = true;
        } else {
          if (v < lo) lo = v;
          if (v > hi) hi = v;
        }
      }
    }
    if (any) {
      if (hi - lo < 60) {
        final mid = (hi + lo) / 2; // near-flat signal → give it a small band
        lo = mid - 60;
        hi = mid + 60;
      }
      final pad = (hi - lo) * 0.12;
      lo = (lo - pad).clamp(0, _adcMax).toDouble();
      hi = (hi + pad).clamp(0, _adcMax).toDouble();
    }
    final interval = ((hi - lo) / 4).clamp(1, _adcMax).toDouble();

    return LineChartData(
      minX: 0,
      maxX: (_windowLen - 1).toDouble(),
      minY: lo,
      maxY: hi,
      clipData: const FlClipData.all(),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: interval,
        getDrawingHorizontalLine: (_) =>
            const FlLine(color: Colors.black12, strokeWidth: 0.8),
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: interval,
            reservedSize: context.r(38),
            getTitlesWidget: (v, meta) => Text(
              v.toInt().toString(),
              style: montserrat(
                  size: context.r(10),
                  weight: FontWeight.w500,
                  color: KColors.navyText),
            ),
          ),
        ),
        bottomTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      lineTouchData: const LineTouchData(enabled: false),
      lineBarsData: [
        for (var i = 0; i < 4; i++)
          LineChartBarData(
            spots: [
              for (var x = 0; x < _buf[i].length; x++)
                FlSpot(x.toDouble(), _buf[i][x]),
            ],
            isCurved: false,
            color: _channels[i].color,
            barWidth: context.r(1.4),
            dotData: const FlDotData(show: false),
          ),
      ],
    );
  }

  Widget _legend(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.r(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var i = 0; i < 4; i++)
            Row(
              children: [
                Container(
                  width: context.r(11),
                  height: context.r(11),
                  decoration: BoxDecoration(
                      shape: BoxShape.circle, color: _channels[i].color),
                ),
                SizedBox(width: context.r(6)),
                Text(
                  _channels[i].label,
                  style: montserrat(
                      size: context.r(13),
                      weight: FontWeight.w800,
                      color: Colors.white),
                ),
                SizedBox(width: context.r(5)),
                Text(
                  _buf[i].isEmpty ? '—' : _buf[i].last.toInt().toString(),
                  style: montserrat(
                      size: context.r(13),
                      weight: FontWeight.w500,
                      color: Colors.white70),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _stopButton(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.r(16)),
      child: GestureDetector(
        onTap: () => context.pop(),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: context.r(15)),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(24),
            borderRadius: BorderRadius.circular(context.r(16)),
            border: Border.all(color: Colors.white.withAlpha(46)),
          ),
          child: Text(
            'หยุด',
            style: thaiSans(
                size: context.r(17),
                weight: FontWeight.w800,
                color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _disconnectedView(BuildContext context) {
    return Stack(
      children: [
        Align(
          alignment: Alignment.topLeft,
          child: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bluetooth_disabled_rounded,
                  color: Colors.white54, size: context.r(56)),
              SizedBox(height: context.r(16)),
              Text(
                'เชื่อมต่ออุปกรณ์ Kinex ก่อน',
                style: thaiSans(
                    size: context.r(17),
                    weight: FontWeight.w700,
                    color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
