import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';

/// Large, high-contrast action button for the assessment flow.
/// [primary] = filled teal; otherwise a white/outlined secondary button.
/// A null [onTap] renders a disabled state. Sized for elderly touch targets.
class AssessmentButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool primary;
  final IconData? icon;

  const AssessmentButton({
    super.key,
    required this.label,
    required this.onTap,
    this.primary = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final fg = primary ? Colors.white : KColors.tealDark;

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: context.r(18)),
          decoration: BoxDecoration(
            color: primary ? null : Colors.white,
            gradient: primary ? KColors.tealButtonGradient : null,
            borderRadius: BorderRadius.circular(context.r(20)),
            border:
                primary ? null : Border.all(color: KColors.teal, width: 2),
            boxShadow: primary
                ? [
                    BoxShadow(
                        color: KColors.tealDark.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6)),
                  ]
                : [
                    BoxShadow(
                        color: KColors.teal.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 3)),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: fg, size: context.r(24)),
                SizedBox(width: context.r(10)),
              ],
              Text(
                label,
                style: thaiSans(
                    size: context.r(20), weight: FontWeight.w800, color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
