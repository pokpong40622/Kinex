import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'kawaii_paint_utils.dart';

/// A big, adorable, hand-painted mascot — the star of every topic card.
class MascotIcon extends StatelessWidget {
  final MascotType type;
  final double size;
  final Color accent;

  const MascotIcon({
    super.key,
    required this.type,
    this.size = 96,
    this.accent = AppColors.teal,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _MascotPainter(type, accent),
          isComplex: true,
          willChange: false,
        ),
      ),
    );
  }
}

class _MascotPainter extends CustomPainter {
  final MascotType type;
  final Color accent;
  _MascotPainter(this.type, this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide / 2;
    switch (type) {
      case MascotType.teacup:
        _paintTeacup(canvas, center, r);
        break;
      case MascotType.house:
        _paintHouse(canvas, center, r);
        break;
      case MascotType.sun:
        _paintSun(canvas, center, r);
        break;
      case MascotType.glassesPill:
        _paintGlassesPill(canvas, center, r);
        break;
      case MascotType.heartHands:
        _paintHeartHands(canvas, center, r);
        break;
      case MascotType.buddy:
        _paintBuddy(canvas, center, r);
        break;
    }
  }

  void _paintTeacup(Canvas canvas, Offset c, double r) {
    // Steam heart.
    final heartCenter = c + Offset(0, -r * 0.85);
    _drawHeart(canvas, heartCenter, r * 0.22, accent.withValues(alpha: 0.55));

    // Saucer.
    final saucer = Rect.fromCenter(
      center: c + Offset(0, r * 0.72),
      width: r * 1.7,
      height: r * 0.34,
    );
    canvas.drawOval(saucer, fillPaint(accent.withValues(alpha: 0.25)));
    canvas.drawOval(saucer, outlinePaint(accent, r * 0.06));

    // Cup body (trapezoid-ish with rounded corners).
    final cupPath = Path()
      ..moveTo(c.dx - r * 0.62, c.dy - r * 0.15)
      ..lineTo(c.dx - r * 0.5, c.dy + r * 0.55)
      ..quadraticBezierTo(
        c.dx - r * 0.46,
        c.dy + r * 0.68,
        c.dx - r * 0.3,
        c.dy + r * 0.68,
      )
      ..lineTo(c.dx + r * 0.3, c.dy + r * 0.68)
      ..quadraticBezierTo(
        c.dx + r * 0.46,
        c.dy + r * 0.68,
        c.dx + r * 0.5,
        c.dy + r * 0.55,
      )
      ..lineTo(c.dx + r * 0.62, c.dy - r * 0.15)
      ..close();
    canvas.drawPath(cupPath, fillPaint(Colors.white));
    canvas.drawPath(cupPath, outlinePaint(accent, r * 0.09));

    // Handle.
    final handleRect = Rect.fromCenter(
      center: c + Offset(r * 0.85, r * 0.2),
      width: r * 0.55,
      height: r * 0.62,
    );
    canvas.drawArc(
      handleRect,
      -math.pi * 0.35,
      math.pi * 1.2,
      false,
      outlinePaint(accent, r * 0.1),
    );

    KawaiiFace.paint(
      canvas,
      c + Offset(0, r * 0.12),
      r * 0.78,
      cheekColor: AppColors.coralPink,
    );
  }

  void _paintHouse(Canvas canvas, Offset c, double r) {
    // Roof.
    final roof = Path()
      ..moveTo(c.dx - r * 0.9, c.dy - r * 0.05)
      ..lineTo(c.dx, c.dy - r * 0.85)
      ..lineTo(c.dx + r * 0.9, c.dy - r * 0.05)
      ..quadraticBezierTo(
        c.dx + r * 0.8,
        c.dy - r * 0.15,
        c.dx + r * 0.7,
        c.dy - r * 0.05,
      )
      ..lineTo(c.dx, c.dy - r * 0.68)
      ..lineTo(c.dx - r * 0.7, c.dy - r * 0.05)
      ..close();
    canvas.drawPath(roof, fillPaint(accent));
    canvas.drawPath(
      roof,
      outlinePaint(accent.withValues(alpha: 0.9), r * 0.06),
    );

    // Body.
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: c + Offset(0, r * 0.35),
        width: r * 1.5,
        height: r * 1.0,
      ),
      Radius.circular(r * 0.2),
    );
    canvas.drawRRect(bodyRect, fillPaint(Colors.white));
    canvas.drawRRect(bodyRect, outlinePaint(accent, r * 0.08));

    // Round windows.
    for (final dx in [-0.5, 0.5]) {
      final wc = c + Offset(r * dx, r * 0.1);
      canvas.drawCircle(wc, r * 0.18, fillPaint(accent.withValues(alpha: 0.3)));
      canvas.drawCircle(wc, r * 0.18, outlinePaint(accent, r * 0.05));
    }

    // Open door.
    final door = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: c + Offset(0, r * 0.68),
        width: r * 0.42,
        height: r * 0.5,
      ),
      Radius.circular(r * 0.14),
    );
    canvas.drawRRect(door, fillPaint(accent.withValues(alpha: 0.55)));

    KawaiiFace.paint(
      canvas,
      c + Offset(0, r * 0.1),
      r * 0.42,
      cheekColor: AppColors.coralPink,
      eyeSpacing: 0.9,
      smileWidth: 0.7,
    );
  }

  void _paintSun(Canvas canvas, Offset c, double r) {
    // Rays.
    final rayPaint = outlinePaint(accent, r * 0.12);
    for (int i = 0; i < 8; i++) {
      final angle = (math.pi * 2 / 8) * i;
      final start = c + Offset(math.cos(angle), math.sin(angle)) * (r * 0.72);
      final end = c + Offset(math.cos(angle), math.sin(angle)) * (r * 0.98);
      canvas.drawLine(start, end, rayPaint);
    }

    // Little stretching arms.
    final armPaint = outlinePaint(accent, r * 0.1);
    canvas.drawLine(
      c + Offset(-r * 0.45, -r * 0.1),
      c + Offset(-r * 0.9, -r * 0.55),
      armPaint,
    );
    canvas.drawLine(
      c + Offset(r * 0.45, -r * 0.1),
      c + Offset(r * 0.9, -r * 0.55),
      armPaint,
    );

    // Face circle.
    canvas.drawCircle(c, r * 0.62, fillPaint(accent));
    canvas.drawCircle(
      c,
      r * 0.62,
      outlinePaint(accent.withValues(alpha: 0.9), r * 0.05),
    );

    KawaiiFace.paint(
      canvas,
      c,
      r * 0.6,
      lineColor: AppColors.ink,
      cheekColor: AppColors.coralPink,
    );
  }

  void _paintGlassesPill(Canvas canvas, Offset c, double r) {
    // Pill capsule character body, tilted.
    canvas.save();
    canvas.translate(c.dx, c.dy + r * 0.15);
    canvas.rotate(-math.pi / 10);
    final pillRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: r * 1.5, height: r * 0.78),
      Radius.circular(r * 0.39),
    );
    canvas.drawRRect(pillRect, fillPaint(Colors.white));
    // Half-fill for the pill's colored end.
    canvas.save();
    canvas.clipRRect(pillRect);
    canvas.drawRect(
      Rect.fromLTWH(-r * 0.75, -r * 0.4, r * 0.8, r * 0.8),
      fillPaint(accent.withValues(alpha: 0.75)),
    );
    canvas.restore();
    canvas.drawRRect(pillRect, outlinePaint(accent, r * 0.07));
    canvas.restore();

    KawaiiFace.paint(
      canvas,
      c + Offset(r * 0.12, r * 0.15),
      r * 0.5,
      cheekColor: AppColors.coralPink,
    );

    // Glasses resting above.
    final glassesY = c.dy - r * 0.5;
    final leftEye = Offset(c.dx - r * 0.34, glassesY);
    final rightEye = Offset(c.dx + r * 0.34, glassesY);
    final gPaint = outlinePaint(accent, r * 0.09);
    canvas.drawCircle(leftEye, r * 0.28, fillPaint(Colors.white));
    canvas.drawCircle(rightEye, r * 0.28, fillPaint(Colors.white));
    canvas.drawCircle(leftEye, r * 0.28, gPaint);
    canvas.drawCircle(rightEye, r * 0.28, gPaint);
    canvas.drawLine(
      leftEye + Offset(r * 0.28, 0),
      rightEye - Offset(r * 0.28, 0),
      gPaint,
    );
    canvas.drawLine(
      leftEye - Offset(r * 0.28, 0),
      leftEye - Offset(r * 0.5, -r * 0.06),
      gPaint,
    );
    canvas.drawLine(
      rightEye + Offset(r * 0.28, 0),
      rightEye + Offset(r * 0.5, -r * 0.06),
      gPaint,
    );
  }

  void _paintHeartHands(Canvas canvas, Offset c, double r) {
    _drawHeart(
      canvas,
      c + Offset(0, -r * 0.05),
      r * 0.95,
      accent,
      outline: true,
      outlineColor: accent,
      strokeWidth: r * 0.08,
    );

    KawaiiFace.paint(
      canvas,
      c + Offset(0, -r * 0.12),
      r * 0.62,
      cheekColor: Colors.white.withValues(alpha: 0.8),
    );

    // Two little hands meeting at the bottom, "holding" together.
    final handPaint = fillPaint(Colors.white);
    final handOutline = outlinePaint(accent, r * 0.05);
    for (final dx in [-0.24, 0.24]) {
      final hc = c + Offset(r * dx, r * 0.62);
      final path = Path()
        ..addOval(
          Rect.fromCenter(center: hc, width: r * 0.38, height: r * 0.3),
        );
      canvas.drawPath(path, handPaint);
      canvas.drawPath(path, handOutline);
    }
  }

  void _paintBuddy(Canvas canvas, Offset c, double r) {
    // Simple round celebratory blob buddy used for feedback moments.
    canvas.drawCircle(c + Offset(0, r * 0.05), r * 0.78, fillPaint(accent));
    canvas.drawCircle(
      c + Offset(0, r * 0.05),
      r * 0.78,
      outlinePaint(accent.withValues(alpha: 0.85), r * 0.05),
    );

    // Raised arms.
    final armPaint = outlinePaint(accent, r * 0.11);
    canvas.drawLine(
      c + Offset(-r * 0.6, r * 0.15),
      c + Offset(-r * 1.05, -r * 0.35),
      armPaint,
    );
    canvas.drawLine(
      c + Offset(r * 0.6, r * 0.15),
      c + Offset(r * 1.05, -r * 0.35),
      armPaint,
    );

    KawaiiFace.paint(
      canvas,
      c + Offset(0, r * 0.05),
      r * 0.7,
      cheekColor: AppColors.coralPink,
    );
  }

  void _drawHeart(
    Canvas canvas,
    Offset c,
    double r,
    Color color, {
    bool outline = false,
    Color? outlineColor,
    double strokeWidth = 2,
  }) {
    final path = Path();
    path.moveTo(c.dx, c.dy + r * 0.75);
    path.cubicTo(
      c.dx - r * 1.3,
      c.dy - r * 0.2,
      c.dx - r * 0.5,
      c.dy - r * 1.1,
      c.dx,
      c.dy - r * 0.35,
    );
    path.cubicTo(
      c.dx + r * 0.5,
      c.dy - r * 1.1,
      c.dx + r * 1.3,
      c.dy - r * 0.2,
      c.dx,
      c.dy + r * 0.75,
    );
    path.close();
    canvas.drawPath(path, fillPaint(color));
    if (outline && outlineColor != null) {
      canvas.drawPath(
        path,
        outlinePaint(outlineColor.withValues(alpha: 0.85), strokeWidth),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MascotPainter oldDelegate) =>
      oldDelegate.type != type || oldDelegate.accent != accent;
}
