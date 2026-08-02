import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import '../theme/game_brand.dart';
import '../theme/responsive.dart';

/// "ฝึกซ้อม" — the practice tab, where every game is launched from.
///
/// Rebuilt against the Figma frame `NewPracticePageUIRef`: instead of a vertical
/// list of five banner cards, one game fills the screen at a time and the user
/// SWIPES between them, with the next card peeking in from the right edge. A
/// single big "เข้าเกม" button underneath is the only way in, so the tap target
/// is in the same place for every game.
///
/// Figma geometry is authored on a 927x1427 frame; the app's responsive helper
/// `context.r()` is baselined at 412dp wide. Every size below is therefore the
/// Figma value x (412/927) = 0.444, rounded — noted per constant so the mapping
/// stays checkable against the design.
class PracticeTab extends StatefulWidget {
  /// MEGA DANCE launches through the parent so it can switch the shell tab
  /// rather than pushing on top of it.
  final VoidCallback onStartGame;

  const PracticeTab({super.key, required this.onStartGame});

  @override
  State<PracticeTab> createState() => _PracticeTabState();
}

class _PracticeTabState extends State<PracticeTab> {
  // 0.84 leaves ~16% of the viewport for the neighbouring card, which is what
  // produces the peeking second card in the design (it sits at x=856 of 927).
  late final PageController _pager = PageController(viewportFraction: 0.84);
  int _index = 0;

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  void _launch(BuildContext context, _PracticeGame game) {
    // push vs go is NOT interchangeable here: the game routes live inside the
    // ShellRoute, so pushing one from a page already in the shell stacks a
    // second shell entry with the same key and trips the navigator's
    // duplicate-key assertion. Each game keeps whichever it used before.
    if (game.onTap != null) {
      game.onTap!();
    } else if (game.useGo) {
      context.go(game.route);
    } else {
      context.push(game.route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final games = _games(widget.onStartGame);
    final current = games[_index.clamp(0, games.length - 1)];

    return Stack(
      fit: StackFit.expand,
      children: [
        // Figma builds the page background out of the same image the card
        // shows, blurred. That was a single shared valley shot back when every
        // card shared one piece of art; now that each card is its own Unity
        // render, the backdrop follows the SELECTED card, so swiping repaints
        // the whole screen in that game's colours.
        //
        // It is blurred far harder than the old shared shot (22 vs 8): that one
        // had to stay legible as a landscape because it was the only scenery on
        // screen, whereas this one sits directly behind a card showing the very
        // same image sharp. Anything less than a full colour wash reads as a
        // duplicate of the card rather than as a backdrop.
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 420),
          child: _Backdrop(key: ValueKey(current.art), asset: current.art),
        ),
        Container(color: Colors.black.withValues(alpha: 0.32)),
        SafeArea(
          // LayoutBuilder, not context.sh: constraints.maxHeight is the real
          // vertical budget for this tab AFTER SafeArea's insets, while sh is
          // the raw screen height and would over-count on notched/gesture-bar
          // devices. The four gaps below are sized as a fraction of that real
          // budget (same fraction context.r() would have produced at the
          // 412x915 baseline, i.e. 10/915 etc.), so they shrink automatically
          // on a short screen. They are plain SizedBoxes, NOT Flexible: Column
          // splits free space EQUALLY among same-flex siblings, so a Flexible
          // gap next to the carousel's Expanded took 1/5 of the leftover
          // height each and collapsed the carousel — Expanded below is the
          // ONLY flex child, so it alone absorbs whatever the fixed
          // header/plaque/dots/button/gaps don't use, i.e. its fraction of
          // availH shrinks first, automatically, without any flex contest.
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availH = constraints.maxHeight;
              return Column(
                children: [
                  _Header(onAssess: () => context.push('/assessment')),
                  _ActivityPlaque(index: _index + 1, total: games.length),
                  SizedBox(height: availH * (10 / 915)),
                  Expanded(
                    // Takes whatever height is left after the fixed
                    // header/plaque/dots/button/gaps above — i.e. a fraction
                    // of availH, not a fixed/aspect-derived height.
                    child: PageView.builder(
                      controller: _pager,
                      itemCount: games.length,
                      onPageChanged: (i) => setState(() => _index = i),
                      itemBuilder: (context, i) => _GameCard(
                        game: games[i],
                        pager: _pager,
                        position: i,
                        onTap: () => _launch(context, games[i]),
                      ),
                    ),
                  ),
                  SizedBox(height: availH * (14 / 915)),
                  _Dots(count: games.length, index: _index),
                  SizedBox(height: availH * (12 / 915)),
                  _EnterGameButton(onTap: () => _launch(context, current)),
                  // Clears the floating nav bar, which is drawn outside this tab.
                  SizedBox(height: availH * (16 / 915)),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Data ────────────────────────────────────────────────────────────────────

class _PracticeGame {
  /// Matches GameSessionRecord.gameId so the card can borrow the game's
  /// existing brand colours instead of inventing a second palette.
  final String id;
  final String title;
  final String blurb;
  /// Hero shot rendered out of that game's own Unity scene (900x1014, lit for
  /// visible shadows, no text baked in). It fills the whole card.
  ///
  /// This replaced the old shared blurred-valley background + floating banner
  /// badge. Those banners were gradient bars with the wordmark on the right and
  /// a deliberately empty left half — space the old `_PracticeCard` used for its
  /// "click to start" button — so they needed a crop hack to not read as a
  /// half-empty bar. The card now shows the actual game instead, and the title
  /// is drawn as live text (see [_Wordmark]) rather than baked into the art.
  final String art;
  final String route;
  final bool useGo;
  final VoidCallback? onTap;

  const _PracticeGame({
    required this.id,
    required this.title,
    required this.blurb,
    required this.art,
    this.route = '',
    this.useGo = false,
    this.onTap,
  });
}

List<_PracticeGame> _games(VoidCallback onStartGame) => [
  const _PracticeGame(
    id: 'hangglider',
    title: 'HANG GLIDER',
    blurb: 'เอียงตัวและกางแขนบังคับเครื่องร่อน ตอบคำถามระหว่างทาง',
    art: 'assets/images/practice/cards/hangglider.png',
    route: '/hang-glider',
  ),
  const _PracticeGame(
    id: 'quakeescape',
    title: 'QUAKE ESCAPE',
    blurb: 'ทรงตัวบนขาข้างเดียว หลบเมืองที่กำลังถล่ม',
    art: 'assets/images/practice/cards/quakeescape.png',
    route: '/quake-escape',
  ),
  const _PracticeGame(
    id: 'thedasher',
    title: 'THE DASHER',
    blurb: 'ก้าวซ้ายขวา 3 เลน หลบอุกกาบาต เก็บสมบัติ และเตะโดรน',
    art: 'assets/images/practice/cards/thedasher.png',
    route: '/the-dasher-start',
  ),
  _PracticeGame(
    id: 'megadance',
    title: 'MEGA DANCE',
    blurb: 'เต้นตามโค้ชเพื่อฝึกท่ากายภาพบำบัด',
    art: 'assets/images/practice/cards/megadance.png',
    onTap: onStartGame,
  ),
  const _PracticeGame(
    id: 'world',
    title: 'KINEX WORLD',
    blurb: 'คลาสออกกำลังกายรวมท่าฝึกกล้ามเนื้อและการทรงตัว',
    art: 'assets/images/practice/cards/world.png',
    route: '/world',
    useGo: true,
  ),
];

// ── Backdrop ────────────────────────────────────────────────────────────────

/// The selected card's own art, blurred into a full-screen colour wash.
class _Backdrop extends StatelessWidget {
  final String asset;
  const _Backdrop({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: ImageFiltered(
        // TileMode.clamp, not the sampling default: at sigma 22 a decal edge
        // pulls transparent pixels in from outside the image and leaves a
        // washed-out band down all four sides of the screen.
        imageFilter: ui.ImageFilter.blur(
          sigmaX: 22,
          sigmaY: 22,
          tileMode: TileMode.clamp,
        ),
        child: Image.asset(
          asset,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(color: const Color(0xFF2B3550)),
        ),
      ),
    );
  }
}

// ── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final VoidCallback onAssess;
  const _Header({required this.onAssess});

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Left/right are page margins, so they're a percent of screen width
      // (20/412 and 16/412 at the Figma-derived 412dp baseline) rather than
      // context.r(), which is now the more-constrained-axis scale and would
      // shrink these on a short screen even though width isn't the problem.
      padding: EdgeInsets.fromLTRB(
        context.w(20 / 412),
        context.r(8),
        context.w(16 / 412),
        context.r(4),
      ),
      child: Row(
        children: [
          // Figma: 120px on a 927-wide frame. Straight conversion gives r(53),
          // which the Thai "ฝึกซ้อม" (wider than the mock's Latin "Practice")
          // pushes into the assessment button, so it is held at r(40).
          Expanded(
            child: Text(
              'ฝึกซ้อม',
              style:
                  montserrat(
                    size: context.r(40),
                    weight: FontWeight.w900,
                    color: Colors.white,
                  ).copyWith(
                    shadows: const [
                      Shadow(
                        color: Color(0xFF0B52C6),
                        offset: Offset(0, 3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
            ),
          ),
          // Kept from the previous design. The mock has no assessment entry
          // point at all, but dropping a working shortcut to fit a reference
          // would be a silent feature removal — it moves up here instead of
          // floating bottom-right, where it would now collide with เข้าเกม.
          _AssessButton(onTap: onAssess),
        ],
      ),
    );
  }
}

class _AssessButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AssessButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.r(14),
          vertical: context.r(9),
        ),
        decoration: BoxDecoration(
          gradient: KColors.assessmentCardGradient,
          borderRadius: BorderRadius.circular(context.r(20)),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.45),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.monitor_heart_rounded,
              color: Colors.white,
              size: context.r(18),
            ),
            SizedBox(width: context.r(6)),
            Text(
              'ประเมิน',
              style: thaiSans(
                size: context.r(14),
                weight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── "กิจกรรมที่ N/M" plaque ─────────────────────────────────────────────────

class _ActivityPlaque extends StatelessWidget {
  final int index;
  final int total;
  const _ActivityPlaque({required this.index, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      // Figma 400x110 -> 178x49.
      width: context.r(178),
      padding: EdgeInsets.symmetric(vertical: context.r(7)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFAF5E1C), Color(0xFF7E3709)],
        ),
        border: Border.all(color: const Color(0xFFEFB365), width: context.r(4)),
        borderRadius: BorderRadius.circular(context.r(11)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: context.r(10),
            offset: Offset(0, context.r(4)),
          ),
        ],
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'กิจกรรมที่ ',
              style: thaiSans(
                size: context.r(19),
                weight: FontWeight.w800,
                color: const Color(0xFFF8F6F6),
              ),
            ),
            // Gold counter, as in the mock.
            TextSpan(
              text: '$index/$total',
              style: thaiSans(
                size: context.r(19),
                weight: FontWeight.w800,
                color: const Color(0xFFFCD557),
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ── Game card ───────────────────────────────────────────────────────────────

class _GameCard extends StatelessWidget {
  final _PracticeGame game;
  final PageController pager;
  final int position;
  final VoidCallback onTap;

  const _GameCard({
    required this.game,
    required this.pager,
    required this.position,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brand = gameBrandOf(game.id);
    return AnimatedBuilder(
      animation: pager,
      builder: (context, child) {
        // Shrink cards as they leave centre so the peeking one sits visually
        // behind. `hasClients` guards the first frame, before the controller is
        // attached and `page` would throw.
        var delta = 0.0;
        if (pager.hasClients && pager.position.haveDimensions) {
          delta = ((pager.page ?? position.toDouble()) - position).abs();
        }
        final scale = (1 - delta * 0.12).clamp(0.86, 1.0);
        return Transform.scale(scale: scale, child: child);
      },
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: EdgeInsets.symmetric(
            horizontal: context.r(6),
            vertical: context.r(4),
          ),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            // Figma: radius 60 -> 27, white-45% stroke 14 -> 6.
            borderRadius: BorderRadius.circular(context.r(27)),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.45),
              width: context.r(6),
            ),
            // Each card now shows ITS OWN game, rendered from that game's Unity
            // scene, instead of the shared blurred valley every card used to
            // share.
            image: DecorationImage(
              image: AssetImage(game.art),
              fit: BoxFit.cover,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: context.r(16),
                offset: Offset(context.r(2), context.r(4)),
              ),
            ],
          ),
          child: Column(
              children: [
                SizedBox(height: context.r(22)),
                // Wordmark, floated near the top the way the mock floats the Hang
                // Glider logo. Drawn as LIVE TEXT rather than a baked image: the
                // app owns no transparent logos (only opaque gradient banners),
                // and text stays crisp at any card size, restyles per game, and
                // costs no extra assets.
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.r(14)),
                  child: _Wordmark(text: game.title, stroke: brand.end),
                ),
                const Spacer(),
                // Title + blurb sit on a scrim rising off the card's bottom edge.
                // Plain white text straight onto the artwork was unreadable on
                // device — the valley is busy and mid-toned right where the blurb
                // falls. The scrim also gives the card a base so the brand stripe
                // is not the only thing anchoring it.
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(
                    context.r(16),
                    context.r(22),
                    context.r(16),
                    context.r(14),
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.55),
                        Colors.black.withValues(alpha: 0.78),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // No title here — the wordmark at the top of the card is
                      // the title now, and repeating it read as a mistake.
                      Text(
                        game.blurb,
                        textAlign: TextAlign.center,
                        style: thaiSans(
                          size: context.r(13),
                          weight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.92),
                        ),
                      ),
                    ],
                  ),
                ),
                // Thin brand stripe so each card is identifiable while swiping.
                Container(
                  height: context.r(6),
                  decoration: BoxDecoration(gradient: brand.gradient),
                ),
              ],
          ),
        ),
      ),
    );
  }
}

/// The game's name, floated on the card art. Figma draws these as white text
/// with a thick coloured outline and a soft drop shadow (`#FEFDFE` fill,
/// 10px gradient stroke, `2px 4px 16px rgba(0,0,0,0.45)` shadow) — reproduced
/// here as two stacked Texts, because Flutter has no single-pass stroke+fill.
/// The stroke takes the game's own brand colour, darkened so it stays readable
/// over a bright sky as well as a dark cave.
class _Wordmark extends StatelessWidget {
  final String text;
  final Color stroke;
  const _Wordmark({required this.text, required this.stroke});

  @override
  Widget build(BuildContext context) {
    // 0.5, not 0.35: at 0.35 the palest brand colour (Hang Glider's light
    // teal) stayed too close to the white fill to read as an outline against a
    // bright sky. Halfway to black keeps every game's hue recognisable while
    // guaranteeing the fill/outline contrast the shape depends on.
    final outline = Color.lerp(stroke, Colors.black, 0.5)!;
    // 46, sized to the SHORTEST titles: FittedBox scales the longer ones down
    // to the card width rather than wrapping or overflowing, so this is an
    // upper bound and each name lands somewhere in 34-41 depending on length.
    final size = context.r(46);
    // FittedBox keeps a long name ("QUAKE ESCAPE") on one line at any card
    // width instead of wrapping or overflowing.
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Stack(
        children: [
          Text(
            text,
            style: montserrat(size: size, weight: FontWeight.w900).copyWith(
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: context.r(18),
                  offset: Offset(context.r(2), context.r(4)),
                ),
              ],
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = context.r(9)
                ..strokeJoin = StrokeJoin.round
                ..color = outline,
            ),
          ),
          Text(
            text,
            style: montserrat(
              size: size,
              weight: FontWeight.w900,
              color: const Color(0xFFFEFDFE),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Page dots ───────────────────────────────────────────────────────────────

class _Dots extends StatelessWidget {
  final int count;
  final int index;
  const _Dots({required this.count, required this.index});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: EdgeInsets.symmetric(horizontal: context.r(3)),
          width: active ? context.r(20) : context.r(7),
          height: context.r(7),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(context.r(4)),
          ),
        );
      }),
    );
  }
}

// ── "เข้าเกม" call to action ────────────────────────────────────────────────

class _EnterGameButton extends StatelessWidget {
  final VoidCallback onTap;
  const _EnterGameButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        // Figma 470x120 -> 209x53, but as a MINIMUM, not a fixed size. Pinning
        // the width overflowed: "เข้าเกม" is seven code points (เ ข ้ า เ ก ม),
        // not four glyphs, so at r(26) the label alone is ~257dp and the row
        // blew past 209 on every screen. Padding + minWidth keeps the mock's
        // proportions where they fit and grows instead of clipping where they
        // don't.
        constraints: BoxConstraints(minWidth: context.r(209)),
        padding: EdgeInsets.symmetric(
          horizontal: context.r(22),
          vertical: context.r(9),
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFAD17), Color(0xFFF37801)],
          ),
          border: Border.all(
            color: const Color(0xFFFEDC38).withValues(alpha: 0.75),
            width: context.r(2),
          ),
          borderRadius: BorderRadius.circular(context.r(16)),
          boxShadow: [
            // The mock's outer glow; the two inset highlights it also carries
            // are not expressible on a BoxDecoration, so the gradient alone
            // supplies the top-to-bottom sheen.
            BoxShadow(
              color: const Color(0xFFD88600),
              blurRadius: context.r(10),
              spreadRadius: context.r(1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/practice/ic_play.png',
              width: context.r(30),
              height: context.r(30),
              errorBuilder: (_, _, _) => Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: context.r(30),
              ),
            ),
            SizedBox(width: context.r(10)),
            Text(
              'เข้าเกม',
              style: thaiSans(
                size: context.r(26),
                weight: FontWeight.w900,
                color: Colors.white.withValues(alpha: 0.95),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
