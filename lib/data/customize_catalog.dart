import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Shared shop/customize catalog — the single source of truth for which
/// themes and characters exist, their price, and their asset. Both the shop
/// tab (shop_page.dart) and the customize page (customize_page.dart) read
/// from here so the two stay in sync.

class ThemeItem {
  final String id;
  final String title;
  final Gradient gradient;
  final int price;
  const ThemeItem(this.id, this.title, this.gradient, this.price);
}

const kThemeCatalog = <ThemeItem>[
  ThemeItem(
    'golden_morning',
    'สวนผลไม้\nGolden Morning',
    LinearGradient(colors: [Color(0xFFFFD54F), Color(0xFFFF8A65)]),
    0,
  ),
  ThemeItem(
    'neon_dusk',
    'Neon Dusk',
    LinearGradient(colors: [Color(0xFFEC4899), Color(0xFF6366F1)]),
    400,
  ),
  ThemeItem('fantasy_meadow', 'Fantasy Meadow', KColors.tealGradient, 300),
];

class CharacterItem {
  final String id;
  final String name;
  final String asset;
  final int price;
  const CharacterItem(this.id, this.name, this.asset, this.price);
}

const kCharacterCatalog = <CharacterItem>[
  CharacterItem(
      'character_kid', 'น้องคิเน็กซ์', 'assets/images/character_kid.png', 0),
  CharacterItem('char_main', 'ฮีโร่หลัก', 'assets/images/char_main.png', 800),
];

/// Looks up a character by id, falling back to the starter character if the
/// id is unknown (defensive — should not happen once persistence is correct).
CharacterItem characterById(String id) => kCharacterCatalog.firstWhere(
      (c) => c.id == id,
      orElse: () => kCharacterCatalog.first,
    );

/// Looks up a theme by id, falling back to the starter theme.
ThemeItem themeById(String id) => kThemeCatalog.firstWhere(
      (t) => t.id == id,
      orElse: () => kThemeCatalog.first,
    );
