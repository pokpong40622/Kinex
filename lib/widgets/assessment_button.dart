import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

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
    final bg = primary ? KColors.teal : Colors.white;

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(18),
            border: primary
                ? null
                : Border.all(color: KColors.teal, width: 2),
            boxShadow: primary
                ? const [
                    BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 10,
                        offset: Offset(0, 4)),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: fg, size: 24),
                const SizedBox(width: 10),
              ],
              Text(
                label,
                style: thaiSans(size: 20, weight: FontWeight.w800, color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
