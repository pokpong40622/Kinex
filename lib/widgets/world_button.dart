import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';

/// Large action button for Kinex World, on the purple background.
/// [primary] = filled white (deep-purple text); otherwise an outlined-white
/// secondary. A null [onTap] renders a disabled state.
class WorldButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool primary;
  final IconData? icon;

  const WorldButton({
    super.key,
    required this.label,
    required this.onTap,
    this.primary = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final fg = primary ? KColors.deepPurple : Colors.white;
    final bg = primary ? Colors.white : Colors.transparent;

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: context.r(18)),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(18),
            border: primary
                ? null
                : Border.all(color: Colors.white, width: 2),
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
