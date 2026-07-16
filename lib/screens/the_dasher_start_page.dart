// "The Dasher" mission-briefing screen (Unity scene id "thedasher" — UI name
// only). Shown between the game card and the embedded Unity game.
//
// Flow: practice card → THIS start page → tap เริ่มภารกิจ → game (the tutorial
// pop-ups now appear as an overlay ON the game, not before this page).
//
// The header is the single lightning logo (logo.png) — no wordmark/subtitle, so
// there is only ONE Dasher mark on screen. The three instruction cards overlap
// as a fanned hand with the "sit" card in front; all are pre-designed PNGs that
// read clearly over the photographic park background.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';

class TheDasherStartPage extends StatelessWidget {
  const TheDasherStartPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Transparent status bar (dark icons over the light sky) so no system tint
    // paints a coloured band at the top; the opaque sky-blue Scaffold background
    // guarantees the very top is sky, never a bleed-through from the page below.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF8FC7F0),
        body: Stack(
          children: [
            const Positioned.fill(
              child: Image(
                image: AssetImage('assets/images/the_dasher/start_bg.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    context.r(20), context.r(12), context.r(20), context.r(18)),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _NavButton(
                          icon: Icons.arrow_back_rounded,
                          onTap: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/home');
                            }
                          },
                        ),
                        const Spacer(),
                        const _StarBadge(),
                      ],
                    ),
                    SizedBox(height: context.r(10)),
                    // Single brand mark (item 3: no more double logo / wordmark).
                    Image.asset(
                      'assets/images/the_dasher/logo.png',
                      height: context.r(112),
                      fit: BoxFit.contain,
                    ),
                    const Spacer(),
                    // Fanned instruction cards — middle ("sit") in front (item 2).
                    const _CardFan(),
                    const Spacer(),
                    _StartButton(
                        onTap: () => context.pushReplacement('/the-dasher')),
                    // Lift the button off the very bottom edge (item 1).
                    SizedBox(height: context.r(52)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The three instruction cards fanned out like a hand of cards: the "sit" card
/// sits in front/centre (larger, lowest), the "move" and "kick" cards tuck
/// behind its edges, tilted outward. Matches the reference's staggered fan.
class _CardFan extends StatelessWidget {
  const _CardFan();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final sideW = w * 0.40;
        final midW = w * 0.46;
        return SizedBox(
          height: context.r(212),
          width: w,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              // Left card — tilted left, tucked behind.
              Positioned(
                left: 0,
                bottom: context.r(18),
                child: Transform.rotate(
                  angle: -0.11,
                  alignment: Alignment.bottomRight,
                  child: SizedBox(
                    width: sideW,
                    child: Image.asset(
                      'assets/images/the_dasher/card_move.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              // Right card — tilted right, tucked behind.
              Positioned(
                right: 0,
                bottom: context.r(18),
                child: Transform.rotate(
                  angle: 0.11,
                  alignment: Alignment.bottomLeft,
                  child: SizedBox(
                    width: sideW,
                    child: Image.asset(
                      'assets/images/the_dasher/card_kick.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              // Middle "sit" card — in front, larger, lowest.
              Positioned(
                bottom: 0,
                child: SizedBox(
                  width: midW,
                  child: Image.asset(
                    'assets/images/the_dasher/card_sit.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Bottom green "เริ่มภารกิจ" button — a pre-designed PNG (bordered/shadowed so
/// it stands out on the grass), tappable to launch the game.
class _StartButton extends StatelessWidget {
  final VoidCallback onTap;
  const _StartButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Image.asset(
        'assets/images/the_dasher/start_button.png',
        width: context.r(230),
        fit: BoxFit.contain,
      ),
    );
  }
}

/// Decorative gold-star badge shown in the top-right corner. Not tappable.
class _StarBadge extends StatelessWidget {
  const _StarBadge();

  @override
  Widget build(BuildContext context) {
    final s = context.r(52);
    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        color: const Color(0xFF9BC96B),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: context.r(3)),
        boxShadow: const [
          BoxShadow(color: Color(0x22000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Icon(Icons.star_rounded, color: Colors.amber, size: s * 0.55),
    );
  }
}

/// Small white circular nav button (back/close).
class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: context.r(44),
        height: context.r(44),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(color: Color(0x22000000), blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Icon(icon, size: context.r(22), color: KColors.navyText),
      ),
    );
  }
}
