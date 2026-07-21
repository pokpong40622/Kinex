import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Shared drawing helpers so every hand-painted mascot / pictogram in the
/// app reads as one consistent, flat, kawaii-vector family.
class KawaiiFace {
  /// Paints a simple happy face (two closed happy-arc eyes, a soft smile,
  /// and rosy cheeks) centered at [center], scaled by [radius].
  static void paint(
    Canvas canvas,
    Offset center,
    double radius, {
    Color lineColor = const Color(0xFF5B4636),
    Color cheekColor = const Color(0xFFF2897E),
    double eyeSpacing = 0.42,
    double eyeY = -0.05,
    double smileWidth = 0.36,
    double smileY = 0.22,
  }) {
    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.6, radius * 0.09)
      ..strokeCap = StrokeCap.round;

    // Happy closed eyes: two little upward arcs "︶ ︶".
    for (final dx in [-eyeSpacing, eyeSpacing]) {
      final eyeCenter = center + Offset(radius * dx, radius * eyeY);
      final rect = Rect.fromCenter(
        center: eyeCenter,
        width: radius * 0.34,
        height: radius * 0.34,
      );
      canvas.drawArc(rect, math.pi * 0.15, math.pi * 0.7, false, linePaint);
    }

    // Soft smile.
    final smilePath = Path()
      ..moveTo(center.dx - radius * smileWidth, center.dy + radius * smileY)
      ..quadraticBezierTo(
        center.dx,
        center.dy + radius * (smileY + 0.22),
        center.dx + radius * smileWidth,
        center.dy + radius * smileY,
      );
    canvas.drawPath(smilePath, linePaint);

    // Rosy cheeks.
    final cheekPaint = Paint()
      ..color = cheekColor.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;
    for (final dx in [-eyeSpacing * 1.55, eyeSpacing * 1.55]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: center + Offset(radius * dx, radius * 0.16),
          width: radius * 0.34,
          height: radius * 0.2,
        ),
        cheekPaint,
      );
    }
  }
}

/// A soft drop shadow used behind every card / mascot shape to keep the
/// whole app feeling gently three-dimensional without hard edges.
Paint softShadowPaint({double opacity = 0.12}) => Paint()
  ..color = Colors.black.withValues(alpha: opacity)
  ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

Paint outlinePaint(Color color, double strokeWidth) => Paint()
  ..color = color
  ..style = PaintingStyle.stroke
  ..strokeWidth = strokeWidth
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

Paint fillPaint(Color color) => Paint()
  ..color = color
  ..style = PaintingStyle.fill;
