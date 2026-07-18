import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'responsive.dart';

/// Shared "de-slopped" UI primitives.
///
/// These replace the ~40 scattered inline card/pill/stat/section-header widgets
/// with one calm, flat visual language: white fills, hairline borders, muted
/// tints — no big soft drop-shadows, no icon-in-squircle+glow, no gradients.
/// Sizes use `context.r()` so they match the rest of the app.

/// Flat card — white fill + hairline border + a whisper of lift.
/// Replaces the old "floating white rounded card + big soft shadow" idiom.
class KCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final Color color;
  final VoidCallback? onTap;
  const KCard({
    super.key,
    required this.child,
    this.padding,
    this.radius = 18,
    this.color = KColors.white,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: KColors.hairline, width: 1),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 1)),
        ],
      ),
      child: child,
    );
    if (onTap == null) return card;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: card,
    );
  }
}

/// Status / label pill — tinted fill + same-hue hairline (calm, not solid-bright).
/// Generalizes the good `FitnessLevelBadge` pattern for use everywhere.
class KPill extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;
  const KPill(this.text, {super.key, this.color = KColors.purple, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: context.r(10), vertical: context.r(5)),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(90), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: context.r(14), color: color),
            SizedBox(width: context.r(5)),
          ],
          Text(text,
              style: thaiSans(
                  size: context.r(12.5),
                  weight: FontWeight.w700,
                  color: color)),
        ],
      ),
    );
  }
}

/// Flat stat tile — big number + muted label, inside a flat card. No shadow stack.
class KStatTile extends StatelessWidget {
  final String value;
  final String label;
  final Color? valueColor;
  const KStatTile({
    super.key,
    required this.value,
    required this.label,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return KCard(
      padding:
          EdgeInsets.symmetric(vertical: context.r(10), horizontal: context.r(8)),
      child: Column(
        children: [
          Text(value,
              style: montserrat(
                  size: context.r(20),
                  weight: FontWeight.w800,
                  color: valueColor ?? KColors.purple)),
          SizedBox(height: context.r(2)),
          Text(label,
              textAlign: TextAlign.center,
              style: thaiSans(
                  size: context.r(11.5),
                  weight: FontWeight.w600,
                  color: KColors.navyText.withAlpha(140))),
        ],
      ),
    );
  }
}

/// Simple section header — small flat icon + title (no squircle, no pill, no shadow).
class KSectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color color;
  final Widget? trailing;
  const KSectionHeader(
    this.title, {
    super.key,
    this.icon,
    this.color = KColors.purple,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.r(6)),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: context.r(20), color: color),
            SizedBox(width: context.r(8)),
          ],
          Expanded(
            child: Text(title,
                style: montserrat(
                    size: context.r(17),
                    weight: FontWeight.w800,
                    color: KColors.navyText)),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
