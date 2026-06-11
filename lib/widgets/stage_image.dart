import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';

/// Reference photo for a test/stage (cropped from the official manual), with a
/// graceful fallback to an icon when the asset is missing. Asset names:
/// body, bmi, back_scratch, sit_reach, arm_curl, chair_stand, step_test, tug.
class StageImage extends StatelessWidget {
  final String name;
  final double height;
  final IconData fallbackIcon;

  const StageImage({
    super.key,
    required this.name,
    this.height = 180,
    this.fallbackIcon = Icons.directions_run_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final scaledHeight = context.r(height);
    return Image.asset(
      'assets/images/assessment/$name.png',
      height: scaledHeight,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => SizedBox(
        height: scaledHeight,
        child: Center(
          child: Icon(fallbackIcon,
              size: scaledHeight * 0.5, color: KColors.teal.withAlpha(120)),
        ),
      ),
    );
  }
}
