import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// The three scored SPPB balance stances (in administration order).
enum BalanceStance { sideBySide, semiTandem, tandem }

extension BalanceStanceInfo on BalanceStance {
  String get thaiName => switch (this) {
        BalanceStance.sideBySide => 'ยืนเท้าชิดกัน',
        BalanceStance.semiTandem => 'ยืนเหลื่อมเท้าครึ่งก้าว',
        BalanceStance.tandem => 'ยืนต่อส้น-ปลายเท้า',
      };

  String get thaiHint => switch (this) {
        BalanceStance.sideBySide => 'วางเท้าสองข้างชิดกัน ปลายเท้าเสมอกัน',
        BalanceStance.semiTandem =>
          'เลื่อนเท้าหนึ่งไปข้างหน้า ให้ส้นเท้าแตะข้างนิ้วโป้งของอีกเท้า',
        BalanceStance.tandem =>
          'วางเท้าต่อกันเป็นเส้นตรง ส้นเท้าหน้าชิดปลายเท้าหลัง',
      };
}

/// Draws the two-foot placement for a balance stance, like the reference slide's
/// footprint icons. Front foot is tinted teal, back foot grey, so the offset is
/// easy to read.
class FootprintDiagram extends StatelessWidget {
  final BalanceStance stance;
  final double size;

  const FootprintDiagram({super.key, required this.stance, this.size = 160});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _FootprintPainter(stance)),
    );
  }
}

class _FootprintPainter extends CustomPainter {
  final BalanceStance stance;
  _FootprintPainter(this.stance);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final footW = size.width * 0.20;
    final footH = footW * 2.6;

    final front = Paint()..color = KColors.teal;
    final back = Paint()..color = const Color(0xFF9AA6A2);

    switch (stance) {
      case BalanceStance.sideBySide:
        _foot(canvas, Offset(cx - footW * 0.7, cy), footW, footH, back);
        _foot(canvas, Offset(cx + footW * 0.7, cy), footW, footH, front);
      case BalanceStance.semiTandem:
        // Back foot lower/right, front foot advanced up by half a foot length.
        _foot(canvas, Offset(cx + footW * 0.7, cy + footH * 0.22), footW, footH,
            back);
        _foot(canvas, Offset(cx - footW * 0.7, cy - footH * 0.22), footW, footH,
            front);
      case BalanceStance.tandem:
        // Feet collinear, heel-to-toe.
        _foot(canvas, Offset(cx, cy + footH * 0.52), footW, footH, back);
        _foot(canvas, Offset(cx, cy - footH * 0.52), footW, footH, front);
    }
  }

  /// A single upward-pointing foot centred at [c]: a rounded capsule (sole) with
  /// a toe cap near the top.
  void _foot(Canvas canvas, Offset c, double w, double h, Paint paint) {
    final rect = Rect.fromCenter(center: c, width: w, height: h);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(w * 0.5)),
      paint,
    );
    // Toe cap (top) — a slightly wider circle to signal the pointing direction.
    canvas.drawCircle(Offset(c.dx, c.dy - h * 0.5 + w * 0.35), w * 0.55, paint);
  }

  @override
  bool shouldRepaint(covariant _FootprintPainter old) => old.stance != stance;
}
