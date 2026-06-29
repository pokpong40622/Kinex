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

// ─── Right-Leg Diagram ────────────────────────────────────────────────────────

/// Stylised right-leg diagram with labelled dots at the knee and ankle,
/// each showing its CCI %.
class LegDiagram extends StatelessWidget {
  final double kneeCci;
  final double ankleCci;
  const LegDiagram({super.key, required this.kneeCci, required this.ankleCci});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.48,
      child: CustomPaint(
        painter: _LegPainter(kneeCci: kneeCci, ankleCci: ankleCci),
      ),
    );
  }
}

class _LegPainter extends CustomPainter {
  final double kneeCci;
  final double ankleCci;
  const _LegPainter({required this.kneeCci, required this.ankleCci});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.40;

    final hipY = h * 0.06;
    final kneeY = h * 0.43;
    final ankleY = h * 0.78;
    final footY = h * 0.90;

    const bgColor = Color(0xFFBFDFF2);

    // Thigh
    canvas.drawLine(
      Offset(cx, hipY + w * 0.12),
      Offset(cx, kneeY),
      Paint()
        ..color = bgColor
        ..strokeWidth = w * 0.30
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    // Shin / calf
    canvas.drawLine(
      Offset(cx, kneeY),
      Offset(cx, ankleY),
      Paint()
        ..color = bgColor
        ..strokeWidth = w * 0.22
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    // Foot stub
    canvas.drawLine(
      Offset(cx, ankleY),
      Offset(cx + w * 0.18, footY),
      Paint()
        ..color = bgColor
        ..strokeWidth = w * 0.16
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    // Hip cap
    canvas.drawCircle(
      Offset(cx, hipY + w * 0.12),
      w * 0.09,
      Paint()..color = const Color(0xFFA8CDE0),
    );

    // Knee dot
    _drawDot(
      canvas,
      Offset(cx, kneeY),
      w * 0.11,
      KColors.teal,
      '${kneeCci.toStringAsFixed(0)}%',
      w * 0.135,
      w,
    );

    // Ankle dot
    _drawDot(
      canvas,
      Offset(cx, ankleY),
      w * 0.09,
      KColors.blue,
      '${ankleCci.toStringAsFixed(0)}%',
      w * 0.120,
      w,
    );
  }

  void _drawDot(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
    String label,
    double fontSize,
    double canvasW,
  ) {
    // Glow ring
    canvas.drawCircle(
      center,
      radius + 5,
      Paint()..color = color.withValues(alpha: 0.18),
    );
    // Solid dot
    canvas.drawCircle(center, radius, Paint()..color = color);
    // White core
    canvas.drawCircle(center, radius * 0.42, Paint()..color = Colors.white);

    // Label to the right
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontFamily: 'Kanit',
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: canvasW * 0.55);

    tp.paint(
      canvas,
      Offset(center.dx + radius + 7, center.dy - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(_LegPainter old) =>
      old.kneeCci != kneeCci || old.ankleCci != ankleCci;
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
            'ยังไม่ได้ปรับเทียบค่าสูงสุด (MVC)',
            style: thaiSans(
              size: context.r(14),
              color: const Color(0xFF8090AA),
            ),
          ),
          SizedBox(height: context.r(12)),
          ElevatedButton(
            onPressed: () => context.push('/assessment/mvc'),
            style: ElevatedButton.styleFrom(
              backgroundColor: KColors.teal,
              foregroundColor: KColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.r(12)),
              ),
            ),
            child: Text(
              'ไปปรับเทียบ',
              style: thaiSans(size: context.r(14), color: KColors.white),
            ),
          ),
        ],
      );
    }

    if (compact) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: Muscle.values.map((m) {
          final peak = cal.peakFor(m) ?? 0;
          return Column(
            children: [
              Text(
                m.code,
                style: montserrat(
                  size: context.r(13),
                  weight: FontWeight.w700,
                  color: KColors.teal,
                ),
              ),
              Text(
                '${peak.toStringAsFixed(0)} µV',
                style: thaiSans(size: context.r(12), color: KColors.navyText),
              ),
            ],
          );
        }).toList(),
      );
    }

    // Full layout
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...Muscle.values.map((m) {
          final peak = cal.peakFor(m) ?? 0;
          return Padding(
            padding: EdgeInsets.only(bottom: context.r(8)),
            child: Row(
              children: [
                Text(
                  '${m.code} · ${m.thaiName}',
                  style: thaiSans(
                    size: context.r(14),
                    color: KColors.navyText,
                  ),
                ),
                const Spacer(),
                Text(
                  '${peak.toStringAsFixed(0)} µV',
                  style: montserrat(
                    size: context.r(14),
                    weight: FontWeight.w700,
                    color: KColors.teal,
                  ),
                ),
              ],
            ),
          );
        }),
        SizedBox(height: context.r(4)),
        Text(
          'ปรับเทียบล่าสุด: ${_fmtDate(cal.calibratedAt)}',
          style: thaiSans(
            size: context.r(12),
            color: const Color(0xFFAAB4C0),
          ),
        ),
      ],
    );
  }
}
