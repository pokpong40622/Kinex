import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'mascot_painter.dart';
import '../models/models.dart';

/// Keeps the interactive game area comfortably centered on large tablet and
/// desktop screens so players never need to scan from edge to edge.
class CenteredGameArea extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const CenteredGameArea({
    super.key,
    required this.child,
    this.maxWidth = 1180,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}

/// A high-contrast translucent top bar shared by game screens.
class KawaiiTopBar extends StatelessWidget {
  final Widget child;

  const KawaiiTopBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 94),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite.withValues(alpha: .97),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: Colors.white, width: 6),
        boxShadow: [
          BoxShadow(
            color: AppColors.lavenderDark.withValues(alpha: .13),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// A clean white rounded-rectangle card with a thick, colorful rounded
/// border — the single repeating shape the whole deck is built from.
class KawaiiCard extends StatelessWidget {
  final Widget child;
  final Color borderColor;
  final VoidCallback? onTap;
  final double borderWidth;
  final double radius;
  final EdgeInsets padding;
  final Color? fillColor;

  const KawaiiCard({
    super.key,
    required this.child,
    required this.borderColor,
    this.onTap,
    this.borderWidth = 8,
    this.radius = 32,
    this.padding = const EdgeInsets.all(18),
    this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: fillColor ?? AppColors.cardWhite.withValues(alpha: .98),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: .32),
            blurRadius: 0,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppColors.lavenderDark.withValues(alpha: .10),
            blurRadius: 8,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
    if (onTap == null) return card;
    return _Bouncy(onTap: onTap!, child: card);
  }
}

/// Gentle press-scale wrapper so every tap feels soft, never abrupt.
class _Bouncy extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _Bouncy({required this.child, required this.onTap});

  @override
  State<_Bouncy> createState() => _BouncyState();
}

class _BouncyState extends State<_Bouncy> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    return GestureDetector(
      onTapDown: reduceMotion ? null : (_) => setState(() => _scale = 0.96),
      onTapUp: reduceMotion ? null : (_) => setState(() => _scale = 1),
      onTapCancel: reduceMotion ? null : () => setState(() => _scale = 1),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: reduceMotion ? 1 : _scale,
        duration: const Duration(milliseconds: 120),
        child: widget.child,
      ),
    );
  }
}

/// Big pill-shaped call-to-action button used for navigation and retries.
class SoftButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool filled;

  const SoftButton({
    super.key,
    required this.label,
    required this.color,
    required this.onPressed,
    this.icon,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    return _Bouncy(
      onTap: onPressed,
      child: Container(
        constraints: const BoxConstraints(minHeight: 76),
        padding: const EdgeInsets.symmetric(horizontal: 38, vertical: 22),
        decoration: BoxDecoration(
          color: filled ? color : Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: color, width: 6),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: .38),
              blurRadius: 0,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: filled ? Colors.white : color, size: 34),
              const SizedBox(width: 12),
            ],
            Text(
              label,
              style: AppTheme.body(
                size: 23,
                weight: FontWeight.w700,
                color: filled ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A round mascot that plays a happy little wiggle when [active] toggles on.
class WigglingBuddy extends StatefulWidget {
  final bool active;
  final double size;
  final Color color;
  const WigglingBuddy({
    super.key,
    required this.active,
    this.size = 90,
    this.color = AppColors.warmBrown,
  });

  @override
  State<WigglingBuddy> createState() => _WigglingBuddyState();
}

class _WigglingBuddyState extends State<WigglingBuddy>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    if (widget.active) _play();
  }

  @override
  void didUpdateWidget(covariant WigglingBuddy oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _play();
  }

  Future<void> _play() async {
    await _controller.forward();
    if (!mounted) return;
    await _controller.reverse();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    if (reduceMotion) {
      return MascotIcon(
        type: MascotType.buddy,
        size: widget.size,
        accent: widget.color,
      );
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final angle = math.sin(_controller.value * math.pi) * 0.18;
        return Transform.rotate(angle: angle, child: child);
      },
      child: MascotIcon(
        type: MascotType.buddy,
        size: widget.size,
        accent: widget.color,
      ),
    );
  }
}

/// A handful of little sparkle marks that fade & pop in around a widget.
class SparkleBurst extends StatelessWidget {
  final bool show;
  final Color color;
  const SparkleBurst({
    super.key,
    required this.show,
    this.color = AppColors.sunYellow,
  });

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();
    final positions = [
      const Offset(-46, -34),
      const Offset(50, -20),
      const Offset(-20, 36),
      const Offset(40, 34),
    ];
    return SizedBox(
      width: 140,
      height: 110,
      child: Stack(
        alignment: Alignment.center,
        children: positions
            .asMap()
            .entries
            .map((e) => _StaticSparkle(offset: e.value, color: color))
            .toList(),
      ),
    );
  }
}

class _StaticSparkle extends StatelessWidget {
  final Offset offset;
  final Color color;
  const _StaticSparkle({required this.offset, required this.color});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: Icon(Icons.auto_awesome, color: color, size: 24),
    );
  }
}

/// A single big tappable A/B/C/D answer card.
class AnswerTile extends StatelessWidget {
  final String letter;
  final String text;
  final Color color;
  final VoidCallback? onTap;
  final AnswerTileState state;

  const AnswerTile({
    super.key,
    required this.letter,
    required this.text,
    required this.color,
    required this.onTap,
    this.state = AnswerTileState.idle,
  });

  const AnswerTile.idle({
    super.key,
    required this.letter,
    required this.text,
    required this.color,
    required this.onTap,
  }) : state = AnswerTileState.idle;

  static AnswerTile correct({
    Key? key,
    required String letter,
    required String text,
    required Color color,
  }) => AnswerTile(
    key: key,
    letter: letter,
    text: text,
    color: color,
    onTap: null,
    state: AnswerTileState.correct,
  );

  static AnswerTile wrong({
    Key? key,
    required String letter,
    required String text,
    required Color color,
  }) => AnswerTile(
    key: key,
    letter: letter,
    text: text,
    color: color,
    onTap: null,
    state: AnswerTileState.wrong,
  );

  static AnswerTile faded({
    Key? key,
    required String letter,
    required String text,
    required Color color,
  }) => AnswerTile(
    key: key,
    letter: letter,
    text: text,
    color: color,
    onTap: null,
    state: AnswerTileState.faded,
  );

  @override
  Widget build(BuildContext context) {
    Color border = color;
    Color fill = AppColors.cardWhite;
    Widget? badge;
    double opacity = 1;
    if (state == AnswerTileState.correct) {
      border = AppColors.happyGreen;
      fill = AppColors.happyGreen.withValues(alpha: 0.18);
      badge = const Icon(
        Icons.check_circle_rounded,
        color: AppColors.happyGreen,
        size: 30,
      );
    } else if (state == AnswerTileState.wrong) {
      border = AppColors.gentleRed;
      fill = AppColors.gentleRed.withValues(alpha: 0.14);
      badge = const Icon(
        Icons.circle_outlined,
        color: AppColors.gentleRed,
        size: 26,
      );
    } else if (state == AnswerTileState.faded) {
      opacity = 0.55;
    }

    final card = KawaiiCard(
      borderColor: border,
      fillColor: fill,
      onTap: onTap,
      borderWidth: 8,
      radius: 30,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: border, shape: BoxShape.circle),
            child: Text(
              letter,
              style: AppTheme.body(
                size: 24,
                weight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Text(
              text,
              style: AppTheme.body(size: 22, weight: FontWeight.w700),
            ),
          ),
          if (badge != null) ...[const SizedBox(width: 8), badge],
        ],
      ),
    );
    if (opacity == 1) return card;
    return Opacity(opacity: opacity, child: card);
  }
}

enum AnswerTileState { idle, correct, wrong, faded }

/// Big ✓ / ✗ true-false buttons — soft colors, never harsh.
class TrueFalseButton extends StatelessWidget {
  final bool isTrue;
  final VoidCallback? onTap;
  final bool selected;
  final bool showAsCorrect;

  const TrueFalseButton({
    super.key,
    required this.isTrue,
    required this.onTap,
    this.selected = false,
    this.showAsCorrect = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isTrue ? AppColors.happyGreen : AppColors.gentleRed;
    final label = isTrue ? 'ถูก' : 'ผิด';
    final iconData = isTrue ? Icons.check_rounded : Icons.close_rounded;
    final fillColor = selected || showAsCorrect
        ? Color.alphaBlend(
            color.withValues(alpha: 0.24),
            Colors.white.withValues(alpha: 0.94),
          )
        : Colors.white.withValues(alpha: 0.96);

    final button = Container(
      width: 196,
      height: 196,
      decoration: BoxDecoration(
        color: fillColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: color,
          width: selected || showAsCorrect ? 10 : 8,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(iconData, color: color, size: 66),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTheme.body(
              size: 26,
              weight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return button;
    return _Bouncy(onTap: onTap!, child: button);
  }
}

/// The low-pressure feedback strip shown after every answer. Correct
/// answers get a wiggling buddy and sparkles; gentle misses still get a
/// kind, encouraging tone — nothing here is meant to feel like a test.
class FeedbackBanner extends StatelessWidget {
  final bool correct;
  final String message;
  final VoidCallback onNext;
  final String nextLabel;

  const FeedbackBanner({
    super.key,
    required this.correct,
    required this.message,
    required this.onNext,
    this.nextLabel = 'ต่อไป',
  });

  @override
  Widget build(BuildContext context) {
    final color = correct ? AppColors.happyGreen : AppColors.warmBrown;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color, width: 6),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.14),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            height: 84,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SparkleBurst(show: correct, color: AppColors.sunYellow),
                WigglingBuddy(active: true, size: 78, color: color),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Text(
              message,
              style: AppTheme.body(
                size: 20,
                weight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 16),
          SoftButton(
            label: nextLabel,
            color: color,
            icon: Icons.arrow_forward_rounded,
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}
