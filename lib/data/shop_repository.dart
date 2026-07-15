import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The shop/profile state: coin balance, which cosmetics are owned, which
/// theme/character is equipped, and the display name. One record — mirrors
/// EmgRepository's single-JSON-string-in-shared_preferences pattern.
class ShopState {
  final int coins;
  final Set<String> unlockedThemes;
  final String activeTheme;
  final Set<String> unlockedCharacters;
  final String activeCharacter;
  final Set<String> unlockedGames;
  final String userName;

  const ShopState({
    required this.coins,
    required this.unlockedThemes,
    required this.activeTheme,
    required this.unlockedCharacters,
    required this.activeCharacter,
    required this.unlockedGames,
    required this.userName,
  });

  static const defaults = ShopState(
    coins: 1250,
    unlockedThemes: {'golden_morning'},
    activeTheme: 'golden_morning',
    unlockedCharacters: {'character_kid'},
    activeCharacter: 'character_kid',
    unlockedGames: {},
    userName: 'ผู้ใช้ KINEX',
  );

  Map<String, dynamic> toJson() => {
        'coins': coins,
        'unlockedThemes': unlockedThemes.toList(),
        'activeTheme': activeTheme,
        'unlockedCharacters': unlockedCharacters.toList(),
        'activeCharacter': activeCharacter,
        'unlockedGames': unlockedGames.toList(),
        'userName': userName,
      };

  factory ShopState.fromJson(Map<String, dynamic> j) => ShopState(
        coins: (j['coins'] as num?)?.toInt() ?? defaults.coins,
        unlockedThemes:
            (j['unlockedThemes'] as List?)?.cast<String>().toSet() ??
                defaults.unlockedThemes,
        activeTheme: j['activeTheme'] as String? ?? defaults.activeTheme,
        unlockedCharacters:
            (j['unlockedCharacters'] as List?)?.cast<String>().toSet() ??
                defaults.unlockedCharacters,
        activeCharacter:
            j['activeCharacter'] as String? ?? defaults.activeCharacter,
        unlockedGames: (j['unlockedGames'] as List?)?.cast<String>().toSet() ??
            defaults.unlockedGames,
        userName: j['userName'] as String? ?? defaults.userName,
      );
}

class ShopRepository {
  static const _key = 'kinex_shop_state';

  Future<ShopState> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return ShopState.defaults;
    return ShopState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save(ShopState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.toJson()));
  }
}

final shopRepositoryProvider =
    Provider<ShopRepository>((ref) => ShopRepository());
