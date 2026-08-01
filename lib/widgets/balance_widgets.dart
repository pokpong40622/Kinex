import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/emg_repository.dart';
import '../models/muscle.dart';
import '../models/emg_metrics.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _fmtDate(DateTime dt) =>
    '${dt.year}-'
    '${dt.month.toString().padLeft(2, '0')}-'
    '${dt.day.toString().padLeft(2, '0')}';

/// One leg's row inside the full MVC card: side label + %MVC + Peak/Mean µV.
Widget _mvcSideRow(BuildContext context, String label, Color color, EmgSample? s) {
  final pct = s?.percentMvc;
  return Container(
    padding:
        EdgeInsets.symmetric(horizontal: context.r(10), vertical: context.r(7)),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(context.r(10)),
    ),
    child: Row(
      children: [
        SizedBox(
          width: context.r(58),
          child: Text(label,
              style: thaiSans(
                  size: context.r(12), weight: FontWeight.w800, color: color)),
        ),
        Text(pct == null ? '—' : '${pct.toStringAsFixed(0)}% MVC',
            style: montserrat(
                size: context.r(13), weight: FontWeight.w800, color: color)),
        const Spacer(),
        Text(
          s == null
              ? ''
              : 'Peak ${s.peakMicrovolts.toStringAsFixed(0)} · Mean ${s.meanMicrovolts.toStringAsFixed(0)} µV',
          style: thaiSans(size: context.r(11), color: const Color(0xFF8090AA)),
        ),
      ],
    ),
  );
}

// ─── CCI Ring Gauge ───────────────────────────────────────────────────────────

/// Circular ring showing co-contraction index (0–100 %) for one joint.
class CciRingGauge extends StatelessWidget {
  final double cci; // 0..100
  final Color color;
  final double size;

  const CciRingGauge({
    super.key,
    required this.cci,
    this.color = KColors.teal,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          fraction: (cci / 100).clamp(0.0, 1.0),
          color: color,
        ),
        child: Center(
          child: Text(
            '${cci.toStringAsFixed(0)}%',
            style: montserrat(
              size: size * 0.22,
              weight: FontWeight.w800,
              color: KColors.navyText,
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double fraction;
  final Color color;
  const _RingPainter({required this.fraction, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const strokeW = 14.0;

    // Background track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFFE4EBF2)
        ..strokeWidth = strokeW
        ..style = PaintingStyle.stroke,
    );

    if (fraction > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        math.pi * 2 * fraction,
        false,
        Paint()
          ..color = color
          ..strokeWidth = strokeW
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction || old.color != color;
}

// ─── %MVC Horizontal Bar ─────────────────────────────────────────────────────

/// One muscle's %MVC as a labelled horizontal bar (Advanced view).
class MvcPercentBar extends StatelessWidget {
  final MuscleReading reading;
  final Color barColor;
  const MvcPercentBar({
    super.key,
    required this.reading,
    required this.barColor,
  });

  @override
  Widget build(BuildContext context) {
    final pct = reading.percentMvc.clamp(0.0, 100.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${reading.muscle.code} · ${reading.muscle.thaiName}',
              style: thaiSans(
                size: context.r(13),
                weight: FontWeight.w600,
                color: KColors.navyText,
              ),
            ),
            const Spacer(),
            Text(
              '${pct.toStringAsFixed(0)}% MVC  ·  '
              '${reading.meanMicrovolts.toStringAsFixed(0)} µV',
              style: thaiSans(
                size: context.r(12),
                color: const Color(0xFF8090AA),
              ),
            ),
          ],
        ),
        SizedBox(height: context.r(6)),
        ClipRRect(
          borderRadius: BorderRadius.circular(context.r(6)),
          child: LinearProgressIndicator(
            value: pct / 100,
            minHeight: context.r(10),
            backgroundColor: const Color(0xFFE4EBF2),
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ],
    );
  }
}

// ─── MVC Calibration Card ────────────────────────────────────────────────────

/// Displays the stored MVC calibration peaks, or a prompt to calibrate.
/// [compact] shows a condensed row layout for the Normal view.
class MvcCard extends ConsumerWidget {
  final bool compact;
  const MvcCard({super.key, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mvcAsync = ref.watch(mvcCalibrationProvider);

    return Container(
      decoration: cardDecoration(),
      padding: EdgeInsets.all(context.r(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ค่าสูงสุดของกล้ามเนื้อ (MVC)',
            style: montserrat(
              size: context.r(15),
              weight: FontWeight.w700,
              color: KColors.navyText,
            ),
          ),
          SizedBox(height: context.r(12)),
          mvcAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, stack) => Text(
              'โหลดข้อมูลล้มเหลว',
              style: thaiSans(
                size: context.r(14),
                color: Colors.redAccent,
              ),
            ),
            data: (mvc) => _MvcContent(mvc: mvc, compact: compact),
          ),
        ],
      ),
    );
  }
}

class _MvcContent extends StatelessWidget {
  final MvcCalibration? mvc;
  final bool compact;
  const _MvcContent({required this.mvc, required this.compact});

  @override
  Widget build(BuildContext context) {
    final cal = mvc;
    if (cal == null || !cal.isComplete) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ยังไม่ได้วัดค่าสูงสุด (MVC) — วัดได้ตอนติดตั้งสายรัด EMG',
            style: thaiSans(
              size: context.r(14),
              color: const Color(0xFF8090AA),
            ),
          ),
          SizedBox(height: context.r(12)),
          ElevatedButton(
            onPressed: () => context.push('/hardware-guide'),
            style: ElevatedButton.styleFrom(
              backgroundColor: KColors.teal,
              foregroundColor: KColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.r(12)),
              ),
            ),
            child: Text(
              'ไปวัดค่า EMG',
              style: thaiSans(size: context.r(14), color: KColors.white),
            ),
          ),
        ],
      );
    }

    if (compact) {
      String pk(EmgSample? s) =>
          s == null ? '—' : '${s.peakMicrovolts.toStringAsFixed(0)}µV';
      return Column(
        children: Muscle.values.map((m) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: context.r(3)),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text('${m.code} · ${m.thaiName}',
                      style: thaiSans(
                          size: context.r(13),
                          weight: FontWeight.w700,
                          color: KColors.navyText)),
                ),
                Expanded(
                  flex: 3,
                  child: Text('L ${pk(cal.sampleFor(m, LegSide.left))}',
                      textAlign: TextAlign.end,
                      style: thaiSans(
                          size: context.r(12),
                          weight: FontWeight.w700,
                          color: KColors.teal)),
                ),
                Expanded(
                  flex: 3,
                  child: Text('R ${pk(cal.sampleFor(m, LegSide.right))}',
                      textAlign: TextAlign.end,
                      style: thaiSans(
                          size: context.r(12),
                          weight: FontWeight.w700,
                          color: KColors.indigo)),
                ),
              ],
            ),
          );
        }).toList(),
      );
    }

    // Full layout — each muscle with separate left & right rows (%MVC + Peak/Mean).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...Muscle.values.map((m) => Padding(
              padding: EdgeInsets.only(bottom: context.r(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${m.code} · ${m.thaiName}',
                      style: thaiSans(
                          size: context.r(14),
                          weight: FontWeight.w800,
                          color: KColors.navyText)),
                  SizedBox(height: context.r(6)),
                  _mvcSideRow(context, 'ซ้าย (L)', KColors.teal,
                      cal.sampleFor(m, LegSide.left)),
                  SizedBox(height: context.r(4)),
                  _mvcSideRow(context, 'ขวา (R)', KColors.indigo,
                      cal.sampleFor(m, LegSide.right)),
                ],
              ),
            )),
        SizedBox(height: context.r(4)),
        Text(
          'วัดล่าสุด: ${_fmtDate(cal.calibratedAt)}',
          style: thaiSans(
            size: context.r(12),
            color: const Color(0xFFAAB4C0),
          ),
        ),
      ],
    );
  }
}
