import 'package:flutter/material.dart';
import '../models/fitness_level.dart';
import '../theme/app_theme.dart';

Color fitnessLevelColor(FitnessLevel level) => switch (level) {
      FitnessLevel.dimak => const Color(0xFF2E9E5B), // green
      FitnessLevel.di => const Color(0xFF1E88E5), // blue
      FitnessLevel.siang => const Color(0xFFE2541E), // orange-red
    };

/// Rounded coloured pill showing a ดีมาก/ดี/เสี่ยง level.
class FitnessLevelBadge extends StatelessWidget {
  final FitnessLevel level;
  final double fontSize;
  const FitnessLevelBadge(this.level, {super.key, this.fontSize = 16});

  @override
  Widget build(BuildContext context) {
    final c = fitnessLevelColor(level);
    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: fontSize, vertical: fontSize * 0.4),
      decoration: BoxDecoration(
        color: c.withAlpha(28),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c, width: 1.5),
      ),
      child: Text(level.thaiLabel,
          style: thaiSans(size: fontSize, weight: FontWeight.w800, color: c)),
    );
  }
}
