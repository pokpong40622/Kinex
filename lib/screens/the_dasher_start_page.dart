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

class TheDasherStartPage extends StatefulWidget {
  const TheDasherStartPage({super.key});

  @override
  State<TheDasherStartPage> createState() => _TheDasherStartPageState();
}

class _TheDasherStartPageState extends State<TheDasherStartPage> {
  // The game-intro (3 how-to graphics) shows as a pop-up ON this start page —
  // not on a page before it, nor as an overlay on the running game. Auto-shows on
  // entry; the ⓘ button re-opens it.
  bool _showIntro = true;

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
                        // Re-open the game intro pop-up.
                        _NavButton(
                          icon: Icons.help_outline_rounded,
                          onTap: () => setState(() => _showIntro = true),
                        ),
                        SizedBox(width: context.r(10)),
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
            // Game-intro pop-up, ON the start page (over everything else).
            if (_showIntro)
              _DasherIntroPopup(onDone: () => setState(() => _showIntro = false)),
          ],
        ),
      ),
    );
  }
}

/// The game-intro pop-up shown over the start page: a 3-page carousel of the
/// how-to graphics (move / treasure / kick) with a page indicator, a Skip, and
/// next / "เข้าใจแล้ว" controls. Dismisses (onDone) back to the start page — the
/// player then taps เริ่มภารกิจ to launch.
class _DasherIntroPopup extends StatefulWidget {
  final VoidCallback onDone;
  const _DasherIntroPopup({required this.onDone});

  @override
  State<_DasherIntroPopup> createState() => _DasherIntroPopupState();
}

class _DasherIntroPopupState extends State<_DasherIntroPopup> {
  final _controller = PageController();
  int _page = 0;

  static const _images = [
    'assets/images/the_dasher/intro_move.png',
    'assets/images/the_dasher/intro_treasure.png',
    'assets/images/the_dasher/intro_kick.png',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page == _images.length - 1) {
      widget.onDone();
    } else {
      _controller.animateToPage(
        _page + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _images.length - 1;
    final size = MediaQuery.sizeOf(context);
    // A compact centred card, not a full-screen takeover. Bound both axes so the
    // popup stays small on a tablet.
    final cardW = size.width * 0.82 > context.r(360)
        ? context.r(360)
        : size.width * 0.82;
    final imgH = size.height * 0.34;

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.62),
        child: Center(
          child: SizedBox(
            width: cardW,
            child: Container(
              padding: EdgeInsets.fromLTRB(context.r(16), context.r(8),
                  context.r(16), context.r(16)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(context.r(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Skip in the top-right — dismiss to the start page.
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: widget.onDone,
                      style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              horizontal: context.r(8), vertical: context.r(2)),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      child: Text('ข้าม',
                          style: thaiSans(
                              size: context.r(14),
                              weight: FontWeight.w700,
                              color: KColors.navyText.withAlpha(150))),
                    ),
                  ),
                  SizedBox(
                    height: imgH,
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: _images.length,
                      onPageChanged: (i) => setState(() => _page = i),
                      itemBuilder: (context, index) => Padding(
                        padding: EdgeInsets.symmetric(horizontal: context.r(6)),
                        child:
                            Image.asset(_images[index], fit: BoxFit.contain),
                      ),
                    ),
                  ),
                  SizedBox(height: context.r(14)),
                  // Page indicator dots.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _images.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: EdgeInsets.symmetric(horizontal: context.r(4)),
                        width: i == _page ? context.r(22) : context.r(8),
                        height: context.r(8),
                        decoration: BoxDecoration(
                          color: i == _page
                              ? KColors.deepPurple
                              : KColors.deepPurple.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(context.r(6)),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: context.r(16)),
                  SizedBox(
                    width: double.infinity,
                    child: _PopupButton(
                      label: isLast ? 'เข้าใจแล้ว' : 'ถัดไป',
                      icon: isLast
                          ? Icons.check_rounded
                          : Icons.arrow_forward_rounded,
                      onTap: _next,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Wide pill button used at the bottom of the intro pop-up.
class _PopupButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _PopupButton(
      {required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: context.r(56),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: KColors.deepPurple,
          borderRadius: BorderRadius.circular(context.r(28)),
          boxShadow: [
            BoxShadow(
              color: KColors.deepPurple.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: thaiSans(
                    size: context.r(17),
                    weight: FontWeight.w800,
                    color: Colors.white)),
            SizedBox(width: context.r(8)),
            Icon(icon, color: Colors.white, size: context.r(24)),
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
