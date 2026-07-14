import 'package:flutter_riverpod/flutter_riverpod.dart';

// MOCKUP — swap to shared_preferences repo later (see lib/data/world_repository.dart
// pattern). Everything below is in-memory only and resets on every app launch.
// Powers the ร้านค้า (Shop) tab: coin balance, which themes/characters/games are
// owned, and which theme/character is currently equipped.

/// Mock coin balance. Decremented on purchase.
final coinsProvider = StateProvider<int>((ref) => 1250);

/// Theme ids the player owns. 'golden_morning' ships unlocked as the starter theme.
final unlockedThemesProvider =
    StateProvider<Set<String>>((ref) => {'golden_morning'});

/// Theme id currently equipped.
final activeThemeProvider = StateProvider<String>((ref) => 'golden_morning');

/// Character ids the player owns. 'character_kid' ships unlocked as the starter.
final unlockedCharactersProvider =
    StateProvider<Set<String>>((ref) => {'character_kid'});

/// Character id currently equipped.
final activeCharacterProvider =
    StateProvider<String>((ref) => 'character_kid');

/// Unlocked game-mode ids (e.g. 'guardian_of_balance').
final unlockedGamesProvider = StateProvider<Set<String>>((ref) => {});
