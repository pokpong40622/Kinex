import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';

/// Reusable full-screen hero start page matching the Home-tab card visual style:
/// gradient hero card → tip line → big START button → optional secondary link.
///
/// Designed for portrait tablet; uses [context.r()] for all sizing so it scales
/// gracefully. Contains no game-specific logic — pass callbacks in.
class GameStartScreen extends StatelessWidget {
  final String title;
  final String tagline;
  final Gradient accentGradient;

  /// Optional art placed in the hero card (right side). Can be an Icon widget,
  /// Image.asset, or any widget. Null = no art.
  final Widget? art;

  /// Optional mode badge rendered below the tagline inside the hero card
  /// (e.g. REHAB / EXERCISE chip). Null = no badge.
  final Widget? badge;

  /// One short tip line shown below the card (Thai or English).
  final String tipText;

  final String startLabel;
  final VoidCallback onStart;

  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  /// Called when the back button is tapped. Defaults to context.go('/home').
  final VoidCallback? onBack;

  const GameStartScreen({
    super.key,
    required this.title,
    required this.tagline,
    required this.accentGradient,
    this.art,
    this.badge,
    required this.tipText,
    this.startLabel = 'START',
    required this.onStart,
    this.secondaryLabel,
    this.onSecondary,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: accentGradient),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top bar: back button ──────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(
                    context.r(16), context.r(12), context.r(16), 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _BackBtn(
                    onTap: onBack ?? () => context.go('/home'),
                  ),
                ),
              ),

              // ── Hero card: expands to fill remaining space ────────────────
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      context.r(20), context.r(20), context.r(20), 0),
                  child: _HeroCard(
                    title: title,
                    tagline: tagline,
                    gradient: accentGradient,
                    art: art,
                    badge: badge,
                  ),
                ),
              ),

              // ── Tip line ─────────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(
                    context.r(24), context.r(16), context.r(24), 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: Colors.white70, size: context.r(16)),
                    SizedBox(width: context.r(8)),
                    Expanded(
                      child: Text(
                        tipText,
                        style: thaiSans(
                            size: context.r(13),
                            weight: FontWeight.w500,
                            color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),

              // ── START button ──────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(
                    context.r(20), context.r(16), context.r(20), 0),
                child: GestureDetector(
                  onTap: onStart,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: double.infinity,
                    padding:
                        EdgeInsets.symmetric(vertical: context.r(18)),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(context.r(18)),
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x40000000),
                            blurRadius: 14,
                            offset: Offset(0, 5)),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      startLabel,
                      style: montserrat(
                          size: context.r(20),
                          weight: FontWeight.w900,
                          color: KColors.navyText),
                    ),
                  ),
                ),
              ),

              // ── Optional secondary link ───────────────────────────────────
              if (secondaryLabel != null && onSecondary != null)
                Padding(
                  padding: EdgeInsets.only(top: context.r(12)),
                  child: GestureDetector(
                    onTap: onSecondary,
                    behavior: HitTestBehavior.opaque,
                    child: Text(
                      secondaryLabel!,
                      style: thaiSans(
                          size: context.r(14),
                          weight: FontWeight.w600,
                          color: Colors.white70),
                    ),
                  ),
                ),

              SizedBox(height: context.r(24)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Hero card ────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final String title;
  final String tagline;
  final Gradient gradient;
  final Widget? art;
  final Widget? badge;

  const _HeroCard({
    required this.title,
    required this.tagline,
    required this.gradient,
    this.art,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(28),
        borderRadius: BorderRadius.circular(context.r(28)),
        border: Border.all(color: Colors.white.withAlpha(90), width: 2.5),
        boxShadow: const [
          BoxShadow(
              color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 8)),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(context.r(28)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Text column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: montserrat(
                        size: context.r(36),
                        weight: FontWeight.w900,
                        color: Colors.white),
                  ),
                  SizedBox(height: context.r(10)),
                  Text(
                    tagline,
                    style: thaiSans(
                        size: context.r(15),
                        weight: FontWeight.w600,
                        color: Colors.white.withAlpha(220)),
                  ),
                  if (badge != null) ...[
                    SizedBox(height: context.r(12)),
                    badge!,
                  ],
                ],
              ),
            ),
            // Art (optional)
            if (art != null) ...[
              SizedBox(width: context.r(16)),
              art!,
            ],
          ],
        ),
      ),
    );
  }
}

// ── Back button ───────────────────────────────────────────────────────────────

class _BackBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _BackBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: context.r(48),
        height: context.r(48),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(45),
          borderRadius: BorderRadius.circular(context.r(14)),
        ),
        child: Icon(Icons.arrow_back_rounded,
            size: context.r(24), color: Colors.white),
      ),
    );
  }
}
