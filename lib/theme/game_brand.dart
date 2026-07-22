import 'package:flutter/material.dart';

// Per-game icon identity for the shop and history lists.
//
// The raw art in assets/images/game_icons/ is not uniform: THE DASHER,
// MEGA DANCE and TEMPLE HUNT are square icons, but QUAKE ESCAPE and HANG GLIDER
// are ~3.3:1 title BANNERS and KINEX WORLD is a text-crammed card. Dropped into
// the ~48 px square icon slot those three came out as an unreadable letterboxed
// sliver of wordmark on a generic purple plate — every game looking the same
// and none of them legible.
//
// So: each game gets its own fixed colour plate. Games with usable square art
// show it on that plate; the banner/text ones show a glyph instead, which reads
// instantly at icon size where their wordmark cannot. The colours are pulled
// from each game's own art so the icon still matches the game you land in.
//
// These are deliberately const, NOT derived from KColors.purple — that one is
// mutable and gets reskinned by the shop's "ธีมสี" sets, and a game's identity
// should not change colour when the user buys a theme.
class GameBrand {
  final Color start;
  final Color end;
  final IconData glyph;

  /// Square art to show instead of [glyph], or null when the game's art is a
  /// wide banner that cannot survive being squared off.
  final String? art;

  const GameBrand({
    required this.start,
    required this.end,
    required this.glyph,
    this.art,
  });

  LinearGradient get gradient => LinearGradient(
        colors: [start, end],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}

const _fallbackBrand = GameBrand(
  start: Color(0xFF8E9BC4),
  end: Color(0xFF5C6890),
  glyph: Icons.sports_esports_rounded,
);

// Keyed by GameSessionRecord.gameId / _GameUnlock.id. The world game is
// recorded under both 'world' (history) and 'kinex_world' (shop).
const Map<String, GameBrand> _brands = {
  'thedasher': GameBrand(
    start: Color(0xFF8CD94B),
    end: Color(0xFF4E9E0E),
    glyph: Icons.bolt_rounded,
    art: 'assets/images/game_icons/thedasher.png',
  ),
  'quakeescape': GameBrand(
    start: Color(0xFFFFB524),
    end: Color(0xFFE4571C),
    glyph: Icons.crisis_alert_rounded,
  ),
  'hangglider': GameBrand(
    start: Color(0xFF7FA8F0),
    end: Color(0xFF2FB3A4),
    glyph: Icons.paragliding_rounded,
  ),
  'world': GameBrand(
    start: Color(0xFFB44BF0),
    end: Color(0xFF6A2BD9),
    glyph: Icons.public_rounded,
  ),
  'kinex_world': GameBrand(
    start: Color(0xFFB44BF0),
    end: Color(0xFF6A2BD9),
    glyph: Icons.public_rounded,
  ),
  'megadance': GameBrand(
    start: Color(0xFFFF5C9E),
    end: Color(0xFFC9256F),
    glyph: Icons.music_note_rounded,
    art: 'assets/images/game_icons/megadance.png',
  ),
  'templehunt': GameBrand(
    start: Color(0xFFF2C14E),
    end: Color(0xFFA9761A),
    glyph: Icons.temple_buddhist_rounded,
    art: 'assets/images/game_icons/templehunt.png',
  ),
  'dancestar': GameBrand(
    start: Color(0xFFFFD25A),
    end: Color(0xFFE08A00),
    glyph: Icons.star_rounded,
    art: 'assets/images/game_icons/dancestar.png',
  ),
};

GameBrand gameBrandOf(String gameId) => _brands[gameId] ?? _fallbackBrand;

/// The square game badge used by both the shop list and the history list, so
/// the same game reads identically in both places.
class GameIconTile extends StatelessWidget {
  final String gameId;
  final double size;
  final double radius;

  const GameIconTile({
    super.key,
    required this.gameId,
    required this.size,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final brand = gameBrandOf(gameId);
    final art = brand.art;
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: brand.gradient,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: brand.end.withValues(alpha: 0.28),
            blurRadius: size * 0.12,
            offset: Offset(0, size * 0.05),
          ),
        ],
      ),
      // cover, not contain: every `art` entry here is already square, and the
      // gradient behind it fills the transparent rounded corners some of the
      // source PNGs carry. A missing/failed asset falls back to the glyph, so
      // the tile is never an empty plate.
      child: art == null
          ? Center(child: _glyph(brand))
          : Image.asset(
              art,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) =>
                  Center(child: _glyph(brand)),
            ),
    );
  }

  Widget _glyph(GameBrand brand) =>
      Icon(brand.glyph, size: size * 0.55, color: Colors.white);
}
