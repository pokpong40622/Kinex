import 'package:flutter/material.dart';
import '../models/fitness_level.dart';
import '../theme/app_theme.dart';

Color bmiBandColor(BmiBand band) => switch (band) {
      BmiBand.phom => const Color(0xFF42A5F5), // blue (underweight)
      BmiBand.pokati => const Color(0xFF2E9E5B), // green (normal)
      BmiBand.namnakKoen => const Color(0xFFF6A609), // amber (overweight)
      BmiBand.rokOuan => const Color(0xFFEF6C00), // orange (obese)
      BmiBand.rokOuanAntaray => const Color(0xFFD32F2F), // red (dangerous)
    };

/// Rounded coloured pill showing a BMI band (ผอม … โรคอ้วนอันตราย).
class BmiBandBadge extends StatelessWidget {
  final BmiBand band;
  final double fontSize;
  const BmiBandBadge(this.band, {super.key, this.fontSize = 16});

  @override
  Widget build(BuildContext context) {
    final c = bmiBandColor(band);
    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: fontSize, vertical: fontSize * 0.4),
      decoration: BoxDecoration(
        color: c.withAlpha(28),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c, width: 1.5),
      ),
      child: Text(band.thaiLabel,
          style: thaiSans(size: fontSize, weight: FontWeight.w800, color: c)),
    );
  }
}
