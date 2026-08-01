import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/shop_repository.dart';

// Shop/profile state: coin balance, which themes/characters/games are owned,
// which theme/character is equipped, and the display name. Persisted via
// ShopRepository (shared_preferences) — hydrated once at startup and saved
// on every change; see shopHydrationProvider/persistShop() below, wired in app.dart.

/// Coin balance. Decremented on purchase.
final coinsProvider = StateProvider<int>((ref) => ShopState.defaults.coins);

/// Theme ids the player owns. 'golden_morning' ships unlocked as the starter theme.
final unlockedThemesProvider = StateProvider<Set<String>>(
    (ref) => ShopState.defaults.unlockedThemes);

/// Theme id currently equipped.
final activeThemeProvider =
    StateProvider<String>((ref) => ShopState.defaults.activeTheme);

/// Character ids the player owns. 'character_kid' ships unlocked as the starter.
final unlockedCharactersProvider = StateProvider<Set<String>>(
    (ref) => ShopState.defaults.unlockedCharacters);

/// Character id currently equipped.
final activeCharacterProvider =
    StateProvider<String>((ref) => ShopState.defaults.activeCharacter);

/// Unlocked game-mode ids (e.g. 'guardian_of_balance').
final unlockedGamesProvider = StateProvider<Set<String>>(
    (ref) => ShopState.defaults.unlockedGames);

/// The user's display name, editable from the customize page.
final userNameProvider =
    StateProvider<String>((ref) => ShopState.defaults.userName);

/// Loads the persisted [ShopState] and pushes it into the providers above.
/// `app.dart` watches this once at startup so the shop/profile state survives
/// app restarts.
final shopHydrationProvider = FutureProvider<void>((ref) async {
  final saved = await ref.watch(shopRepositoryProvider).load();
  ref.read(coinsProvider.notifier).state = saved.coins;
  ref.read(unlockedThemesProvider.notifier).state = saved.unlockedThemes;
  ref.read(activeThemeProvider.notifier).state = saved.activeTheme;
  ref.read(unlockedCharactersProvider.notifier).state =
      saved.unlockedCharacters;
  ref.read(activeCharacterProvider.notifier).state = saved.activeCharacter;
  ref.read(unlockedGamesProvider.notifier).state = saved.unlockedGames;
  ref.read(userNameProvider.notifier).state = saved.userName;
});

/// Writes the current shop/profile state back to disk. Called from a
/// `ref.listen` on each provider above (wired once in app.dart) so every
/// change (purchase, equip, name edit) persists immediately.
void persistShop(WidgetRef ref) {
  ref.read(shopRepositoryProvider).save(ShopState(
        coins: ref.read(coinsProvider),
        unlockedThemes: ref.read(unlockedThemesProvider),
        activeTheme: ref.read(activeThemeProvider),
        unlockedCharacters: ref.read(unlockedCharactersProvider),
        activeCharacter: ref.read(activeCharacterProvider),
        unlockedGames: ref.read(unlockedGamesProvider),
        userName: ref.read(userNameProvider),
      ));
}
