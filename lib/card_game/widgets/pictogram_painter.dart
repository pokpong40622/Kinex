import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/models.dart';
import 'kawaii_paint_utils.dart';

/// Small flat-vector pictograms used to illustrate individual quiz cards.
/// They share the same rounded, chunky, single-accent-color language as
/// the topic mascots so every card in the deck feels like one family.
class PictogramIcon extends StatelessWidget {
  final PictogramType type;
  final double size;
  final Color accent;

  const PictogramIcon({
    super.key,
    required this.type,
    this.size = 72,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _PictogramPainter(type, accent),
          isComplex: true,
          willChange: false,
        ),
      ),
    );
  }
}

class _PictogramPainter extends CustomPainter {
  final PictogramType type;
  final Color accent;
  _PictogramPainter(this.type, this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide / 2;
    switch (type) {
      case PictogramType.bed:
        _bed(canvas, c, r);
        break;
      case PictogramType.shoes:
        _shoes(canvas, c, r);
        break;
      case PictogramType.waterGlass:
        _waterGlass(canvas, c, r);
        break;
      case PictogramType.foodPlate:
        _foodPlate(canvas, c, r);
        break;
      case PictogramType.bathroomMat:
        _bathroomMat(canvas, c, r);
        break;
      case PictogramType.stairsHandrail:
        _stairsHandrail(canvas, c, r);
        break;
      case PictogramType.rugCord:
        _rugCord(canvas, c, r);
        break;
      case PictogramType.nightLight:
        _nightLight(canvas, c, r);
        break;
      case PictogramType.taichi:
        _person(
          canvas,
          c,
          r,
          leftArmAngle: -0.5,
          rightArmAngle: 3.6,
          oneLegLifted: false,
        );
        break;
      case PictogramType.stretching:
        _person(
          canvas,
          c,
          r,
          leftArmAngle: -0.75,
          rightArmAngle: 3.9,
          oneLegLifted: false,
        );
        break;
      case PictogramType.balanceChair:
        _balanceChair(canvas, c, r);
        break;
      case PictogramType.calendarRoutine:
        _calendar(canvas, c, r);
        break;
      case PictogramType.pillDoctor:
        _pillDoctor(canvas, c, r);
        break;
      case PictogramType.glasses:
        _glasses(canvas, c, r, sparkle: false);
        break;
      case PictogramType.glassesClean:
        _glasses(canvas, c, r, sparkle: true);
        break;
      case PictogramType.pillSchedule:
        _pillSchedule(canvas, c, r);
        break;
      case PictogramType.cane:
        _cane(canvas, c, r);
        break;
      case PictogramType.familyTalk:
        _familyTalk(canvas, c, r);
        break;
      case PictogramType.phoneEmergency:
        _phoneEmergency(canvas, c, r);
        break;
      case PictogramType.friendsCommunity:
        _friends(canvas, c, r);
        break;
    }
  }

  // --- shared helpers -------------------------------------------------

  void _person(
    Canvas canvas,
    Offset c,
    double r, {
    required double leftArmAngle,
    required double rightArmAngle,
    bool oneLegLifted = false,
  }) {
    final stroke = outlinePaint(accent, r * 0.14);
    final feet = c + Offset(0, r * 0.85);
    final hip = c + Offset(0, r * 0.15);
    final shoulder = c + Offset(0, r * -0.25);
    final head = c + Offset(0, r * -0.55);

    // Legs.
    canvas.drawLine(hip, feet + Offset(-r * 0.28, 0), stroke);
    canvas.drawLine(
      hip,
      oneLegLifted
          ? feet + Offset(r * 0.1, -r * 0.25)
          : feet + Offset(r * 0.28, 0),
      stroke,
    );
    // Body.
    canvas.drawLine(hip, shoulder, stroke);
    // Arms.
    canvas.drawLine(
      shoulder,
      shoulder +
          Offset(math.cos(leftArmAngle), math.sin(leftArmAngle)) * r * 0.55,
      stroke,
    );
    canvas.drawLine(
      shoulder,
      shoulder +
          Offset(math.cos(rightArmAngle), math.sin(rightArmAngle)) * r * 0.55,
      stroke,
    );
    // Head.
    canvas.drawCircle(head, r * 0.24, fillPaint(accent));
  }

  // --- pictograms -------------------------------------------------------

  void _bed(Canvas canvas, Offset c, double r) {
    final frame = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: c + Offset(0, r * 0.15),
        width: r * 1.7,
        height: r,
      ),
      Radius.circular(r * 0.2),
    );
    canvas.drawRRect(frame, fillPaint(Colors.white));
    canvas.drawRRect(frame, outlinePaint(accent, r * 0.09));
    final pillow = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: c + Offset(-r * 0.55, -r * 0.08),
        width: r * 0.55,
        height: r * 0.4,
      ),
      Radius.circular(r * 0.16),
    );
    canvas.drawRRect(pillow, fillPaint(accent.withValues(alpha: 0.35)));
    canvas.drawRRect(pillow, outlinePaint(accent, r * 0.06));
    final blanket = Path()
      ..moveTo(c.dx - r * 0.1, c.dy + r * 0.05)
      ..quadraticBezierTo(
        c.dx + r * 0.3,
        c.dy - r * 0.15,
        c.dx + r * 0.75,
        c.dy + r * 0.05,
      );
    canvas.drawPath(blanket, outlinePaint(accent, r * 0.08));
    // Legs.
    for (final dx in [-0.7, 0.7]) {
      canvas.drawLine(
        c + Offset(r * dx, r * 0.6),
        c + Offset(r * dx, r * 0.85),
        outlinePaint(accent, r * 0.08),
      );
    }
  }

  void _shoes(Canvas canvas, Offset c, double r) {
    final path = Path()
      ..moveTo(c.dx - r * 0.75, c.dy + r * 0.3)
      ..lineTo(c.dx - r * 0.75, c.dy - r * 0.05)
      ..quadraticBezierTo(
        c.dx - r * 0.6,
        c.dy - r * 0.3,
        c.dx - r * 0.2,
        c.dy - r * 0.2,
      )
      ..lineTo(c.dx + r * 0.35, c.dy + r * 0.05)
      ..quadraticBezierTo(
        c.dx + r * 0.8,
        c.dy + r * 0.05,
        c.dx + r * 0.8,
        c.dy + r * 0.3,
      )
      ..close();
    canvas.drawPath(path, fillPaint(Colors.white));
    canvas.drawPath(path, outlinePaint(accent, r * 0.09));
    canvas.drawLine(
      c + Offset(-r * 0.35, -r * 0.05),
      c + Offset(-r * 0.1, r * 0.12),
      outlinePaint(accent, r * 0.055),
    );
    canvas.drawLine(
      c + Offset(-r * 0.15, -r * 0.13),
      c + Offset(r * 0.1, r * 0.05),
      outlinePaint(accent, r * 0.055),
    );
  }

  void _waterGlass(Canvas canvas, Offset c, double r) {
    final path = Path()
      ..moveTo(c.dx - r * 0.42, c.dy - r * 0.7)
      ..lineTo(c.dx - r * 0.3, c.dy + r * 0.7)
      ..lineTo(c.dx + r * 0.3, c.dy + r * 0.7)
      ..lineTo(c.dx + r * 0.42, c.dy - r * 0.7)
      ..close();
    canvas.drawPath(path, fillPaint(Colors.white));
    canvas.save();
    canvas.clipPath(path);
    canvas.drawRect(
      Rect.fromLTWH(c.dx - r, c.dy, r * 2, r),
      fillPaint(accent.withValues(alpha: 0.45)),
    );
    final wavePaint = outlinePaint(accent, r * 0.06);
    final wave = Path()
      ..moveTo(c.dx - r * 0.5, c.dy)
      ..quadraticBezierTo(c.dx - r * 0.2, c.dy - r * 0.12, c.dx, c.dy)
      ..quadraticBezierTo(
        c.dx + r * 0.2,
        c.dy + r * 0.12,
        c.dx + r * 0.5,
        c.dy,
      );
    canvas.drawPath(wave, wavePaint);
    canvas.restore();
    canvas.drawPath(path, outlinePaint(accent, r * 0.08));
  }

  void _foodPlate(Canvas canvas, Offset c, double r) {
    canvas.drawCircle(c, r * 0.85, fillPaint(Colors.white));
    canvas.drawCircle(c, r * 0.85, outlinePaint(accent, r * 0.08));
    canvas.drawCircle(
      c,
      r * 0.6,
      outlinePaint(accent.withValues(alpha: 0.4), r * 0.04),
    );
    final colors = [
      accent,
      accent.withValues(alpha: 0.6),
      accent.withValues(alpha: 0.35),
    ];
    final offsets = [
      Offset(-r * 0.25, -r * 0.1),
      Offset(r * 0.28, -r * 0.15),
      Offset(0, r * 0.3),
    ];
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(c + offsets[i], r * 0.22, fillPaint(colors[i]));
    }
  }

  void _bathroomMat(Canvas canvas, Offset c, double r) {
    final mat = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: c + Offset(0, r * 0.25),
        width: r * 1.5,
        height: r * 0.8,
      ),
      Radius.circular(r * 0.3),
    );
    canvas.drawRRect(mat, fillPaint(accent.withValues(alpha: 0.3)));
    canvas.drawRRect(mat, outlinePaint(accent, r * 0.08));
    for (final dx in [-0.35, 0.0, 0.35]) {
      _droplet(canvas, c + Offset(r * dx, -r * 0.45), r * 0.22);
    }
  }

  void _droplet(Canvas canvas, Offset c, double r) {
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx + r, c.dy + r * 0.3, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx - r, c.dy + r * 0.3, c.dx, c.dy - r)
      ..close();
    canvas.drawPath(path, fillPaint(accent.withValues(alpha: 0.55)));
    canvas.drawPath(path, outlinePaint(accent, r * 0.18));
  }

  void _stairsHandrail(Canvas canvas, Offset c, double r) {
    final stepPaint = fillPaint(accent.withValues(alpha: 0.35));
    final outline = outlinePaint(accent, r * 0.06);
    final path = Path();
    const steps = 4;
    final stepW = r * 0.42;
    final stepH = r * 0.32;
    final start = c + Offset(-r * 0.85, r * 0.5);
    path.moveTo(start.dx, start.dy);
    for (int i = 0; i < steps; i++) {
      path.lineTo(start.dx + stepW * i, start.dy - stepH * i);
      path.lineTo(start.dx + stepW * (i + 1), start.dy - stepH * i);
    }
    path.lineTo(start.dx + stepW * steps, start.dy);
    path.close();
    canvas.drawPath(path, stepPaint);
    canvas.drawPath(path, outline);
    // Handrail.
    final railStart = start + Offset(0, -r * 0.15);
    final railEnd = Offset(
      start.dx + stepW * steps,
      start.dy - stepH * steps - r * 0.15,
    );
    canvas.drawLine(railStart, railEnd, outlinePaint(accent, r * 0.1));
    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      canvas.drawLine(
        Offset(
          railStart.dx + (railEnd.dx - railStart.dx) * t,
          railStart.dy + (railEnd.dy - railStart.dy) * t,
        ),
        Offset(
              railStart.dx + (railEnd.dx - railStart.dx) * t,
              railStart.dy + (railEnd.dy - railStart.dy) * t,
            ) +
            Offset(0, r * 0.2),
        outlinePaint(accent, r * 0.05),
      );
    }
  }

  void _rugCord(Canvas canvas, Offset c, double r) {
    final path = Path()..moveTo(c.dx - r * 0.85, c.dy - r * 0.3);
    path.cubicTo(
      c.dx - r * 0.3,
      c.dy - r * 0.9,
      c.dx + r * 0.1,
      c.dy + r * 0.5,
      c.dx + r * 0.85,
      c.dy - r * 0.2,
    );
    canvas.drawPath(path, outlinePaint(accent, r * 0.13));
    canvas.drawCircle(
      c + Offset(-r * 0.85, -r * 0.3),
      r * 0.1,
      fillPaint(accent),
    );
    canvas.drawCircle(
      c + Offset(r * 0.85, -r * 0.2),
      r * 0.1,
      fillPaint(accent),
    );
  }

  void _nightLight(Canvas canvas, Offset c, double r) {
    for (int i = 0; i < 6; i++) {
      final angle = (math.pi * 2 / 6) * i;
      final start = c + Offset(math.cos(angle), math.sin(angle)) * r * 0.55;
      final end = c + Offset(math.cos(angle), math.sin(angle)) * r * 0.78;
      canvas.drawLine(
        start,
        end,
        outlinePaint(accent.withValues(alpha: 0.6), r * 0.07),
      );
    }
    canvas.drawCircle(c, r * 0.42, fillPaint(accent));
    canvas.drawCircle(
      c,
      r * 0.42,
      outlinePaint(accent.withValues(alpha: 0.9), r * 0.05),
    );
    final base = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: c + Offset(0, r * 0.65),
        width: r * 0.3,
        height: r * 0.3,
      ),
      Radius.circular(r * 0.08),
    );
    canvas.drawRRect(base, fillPaint(accent.withValues(alpha: 0.5)));
  }

  void _balanceChair(Canvas canvas, Offset c, double r) {
    // Chair.
    final seat = c + Offset(r * 0.5, r * 0.2);
    canvas.drawLine(
      seat + Offset(-r * 0.3, 0),
      seat + Offset(r * 0.3, 0),
      outlinePaint(accent, r * 0.09),
    );
    canvas.drawLine(
      seat + Offset(-r * 0.3, 0),
      seat + Offset(-r * 0.3, -r * 0.55),
      outlinePaint(accent, r * 0.08),
    );
    for (final dx in [-0.25, 0.25]) {
      canvas.drawLine(
        seat + Offset(r * dx, 0),
        seat + Offset(r * dx, r * 0.55),
        outlinePaint(accent, r * 0.07),
      );
    }
    // Person balancing on one leg holding chair.
    _person(
      canvas,
      c + Offset(-r * 0.35, 0),
      r * 0.9,
      leftArmAngle: 0.0,
      rightArmAngle: -2.6,
      oneLegLifted: true,
    );
  }

  void _calendar(Canvas canvas, Offset c, double r) {
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: c + Offset(0, r * 0.05),
        width: r * 1.5,
        height: r * 1.3,
      ),
      Radius.circular(r * 0.16),
    );
    canvas.drawRRect(body, fillPaint(Colors.white));
    canvas.drawRRect(body, outlinePaint(accent, r * 0.08));
    final headerRect = Rect.fromCenter(
      center: c + Offset(0, -r * 0.5),
      width: r * 1.5,
      height: r * 0.3,
    );
    canvas.drawRect(headerRect, fillPaint(accent));
    for (final dx in [-0.3, 0.3]) {
      canvas.drawLine(
        c + Offset(r * dx, -r * 0.68),
        c + Offset(r * dx, -r * 0.42),
        outlinePaint(Colors.white, r * 0.06),
      );
    }
    final check = Path()
      ..moveTo(c.dx - r * 0.28, c.dy + r * 0.15)
      ..lineTo(c.dx - r * 0.05, c.dy + r * 0.4)
      ..lineTo(c.dx + r * 0.4, c.dy - r * 0.2);
    canvas.drawPath(check, outlinePaint(accent, r * 0.11));
  }

  void _pillDoctor(Canvas canvas, Offset c, double r) {
    canvas.save();
    canvas.translate(c.dx - r * 0.15, c.dy + r * 0.1);
    canvas.rotate(-math.pi / 6);
    final pill = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: r * 1.15, height: r * 0.55),
      Radius.circular(r * 0.28),
    );
    canvas.drawRRect(pill, fillPaint(Colors.white));
    canvas.save();
    canvas.clipRRect(pill);
    canvas.drawRect(
      Rect.fromLTWH(-r * 0.6, -r * 0.3, r * 0.6, r * 0.6),
      fillPaint(accent.withValues(alpha: 0.8)),
    );
    canvas.restore();
    canvas.drawRRect(pill, outlinePaint(accent, r * 0.06));
    canvas.restore();

    // Medical cross badge.
    final badgeCenter = c + Offset(r * 0.45, -r * 0.45);
    canvas.drawCircle(
      badgeCenter,
      r * 0.32,
      fillPaint(accent.withValues(alpha: 0.25)),
    );
    canvas.drawCircle(badgeCenter, r * 0.32, outlinePaint(accent, r * 0.05));
    canvas.drawLine(
      badgeCenter + Offset(-r * 0.14, 0),
      badgeCenter + Offset(r * 0.14, 0),
      outlinePaint(accent, r * 0.07),
    );
    canvas.drawLine(
      badgeCenter + Offset(0, -r * 0.14),
      badgeCenter + Offset(0, r * 0.14),
      outlinePaint(accent, r * 0.07),
    );
  }

  void _glasses(Canvas canvas, Offset c, double r, {required bool sparkle}) {
    final left = c + Offset(-r * 0.4, 0);
    final right = c + Offset(r * 0.4, 0);
    final gPaint = outlinePaint(accent, r * 0.11);
    canvas.drawCircle(left, r * 0.36, fillPaint(Colors.white));
    canvas.drawCircle(right, r * 0.36, fillPaint(Colors.white));
    canvas.drawCircle(left, r * 0.36, gPaint);
    canvas.drawCircle(right, r * 0.36, gPaint);
    canvas.drawLine(
      left + Offset(r * 0.36, 0),
      right - Offset(r * 0.36, 0),
      gPaint,
    );
    canvas.drawLine(
      left - Offset(r * 0.36, 0),
      left + Offset(-r * 0.2, -r * 0.08),
      gPaint,
    );
    canvas.drawLine(
      right + Offset(r * 0.36, 0),
      right + Offset(r * 0.2, -r * 0.08),
      gPaint,
    );
    if (sparkle) {
      _sparkleMark(canvas, left + Offset(-r * 0.1, -r * 0.1), r * 0.14, accent);
      _sparkleMark(
        canvas,
        right + Offset(r * 0.05, -r * 0.12),
        r * 0.1,
        accent,
      );
    }
  }

  void _sparkleMark(Canvas canvas, Offset c, double r, Color color) {
    final p = outlinePaint(color, r * 0.35);
    canvas.drawLine(c + Offset(-r, -r), c + Offset(r, r), p);
    canvas.drawLine(c + Offset(-r, r), c + Offset(r, -r), p);
  }

  void _pillSchedule(Canvas canvas, Offset c, double r) {
    final box = RRect.fromRectAndRadius(
      Rect.fromCenter(center: c, width: r * 1.6, height: r * 1.1),
      Radius.circular(r * 0.16),
    );
    canvas.drawRRect(box, fillPaint(Colors.white));
    canvas.drawRRect(box, outlinePaint(accent, r * 0.08));
    canvas.drawLine(
      c + Offset(0, -r * 0.55),
      c + Offset(0, r * 0.55),
      outlinePaint(accent, r * 0.05),
    );
    canvas.drawLine(
      c + Offset(-r * 0.8, 0),
      c + Offset(r * 0.8, 0),
      outlinePaint(accent, r * 0.05),
    );
    for (final o in [
      Offset(-r * 0.4, -r * 0.28),
      Offset(r * 0.4, -r * 0.28),
      Offset(-r * 0.4, r * 0.28),
    ]) {
      canvas.drawCircle(
        c + o,
        r * 0.13,
        fillPaint(accent.withValues(alpha: 0.7)),
      );
    }
  }

  void _cane(Canvas canvas, Offset c, double r) {
    final path = Path()
      ..moveTo(c.dx - r * 0.15, c.dy - r * 0.85)
      ..quadraticBezierTo(
        c.dx - r * 0.55,
        c.dy - r * 0.85,
        c.dx - r * 0.55,
        c.dy - r * 0.5,
      )
      ..quadraticBezierTo(
        c.dx - r * 0.55,
        c.dy - r * 0.2,
        c.dx - r * 0.15,
        c.dy - r * 0.15,
      )
      ..lineTo(c.dx + r * 0.05, c.dy + r * 0.85);
    canvas.drawPath(path, outlinePaint(accent, r * 0.13));
    canvas.drawLine(
      c + Offset(-r * 0.3, r * 0.85),
      c + Offset(r * 0.4, r * 0.85),
      outlinePaint(accent.withValues(alpha: 0.5), r * 0.07),
    );
  }

  void _familyTalk(Canvas canvas, Offset c, double r) {
    _person(
      canvas,
      c + Offset(-r * 0.4, r * 0.1),
      r * 0.8,
      leftArmAngle: -0.6,
      rightArmAngle: 0.9,
      oneLegLifted: false,
    );
    _person(
      canvas,
      c + Offset(r * 0.4, r * 0.1),
      r * 0.8,
      leftArmAngle: math.pi - 0.9,
      rightArmAngle: math.pi + 0.6,
      oneLegLifted: false,
    );
    // Speech bubble.
    final bubble = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: c + Offset(0, -r * 0.65),
        width: r * 0.7,
        height: r * 0.42,
      ),
      Radius.circular(r * 0.18),
    );
    canvas.drawRRect(bubble, fillPaint(Colors.white));
    canvas.drawRRect(bubble, outlinePaint(accent, r * 0.06));
  }

  void _phoneEmergency(Canvas canvas, Offset c, double r) {
    final phone = RRect.fromRectAndRadius(
      Rect.fromCenter(center: c, width: r * 1.05, height: r * 1.7),
      Radius.circular(r * 0.28),
    );
    canvas.drawRRect(phone, fillPaint(Colors.white));
    canvas.drawRRect(phone, outlinePaint(accent, r * 0.08));
    final screen = RRect.fromRectAndRadius(
      Rect.fromCenter(center: c, width: r * 0.8, height: r * 1.3),
      Radius.circular(r * 0.14),
    );
    canvas.drawRRect(screen, fillPaint(accent.withValues(alpha: 0.25)));
    canvas.drawLine(
      c + Offset(-r * 0.18, 0),
      c + Offset(r * 0.18, 0),
      outlinePaint(accent, r * 0.1),
    );
    canvas.drawLine(
      c + Offset(0, -r * 0.18),
      c + Offset(0, r * 0.18),
      outlinePaint(accent, r * 0.1),
    );
  }

  void _friends(Canvas canvas, Offset c, double r) {
    _person(
      canvas,
      c + Offset(-r * 0.55, r * 0.15),
      r * 0.75,
      leftArmAngle: -0.6,
      rightArmAngle: 1.1,
      oneLegLifted: false,
    );
    _person(
      canvas,
      c,
      r * 0.9,
      leftArmAngle: -0.6,
      rightArmAngle: 3.7,
      oneLegLifted: false,
    );
    _person(
      canvas,
      c + Offset(r * 0.55, r * 0.15),
      r * 0.75,
      leftArmAngle: math.pi - 1.1,
      rightArmAngle: math.pi + 0.6,
      oneLegLifted: false,
    );
  }

  @override
  bool shouldRepaint(covariant _PictogramPainter oldDelegate) =>
      oldDelegate.type != type || oldDelegate.accent != accent;
}
