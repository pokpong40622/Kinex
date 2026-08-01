import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether the in-game "The Dasher" tutorial (teaches the 3 moves before the
/// game starts) is enabled. Persisted; **default ON**. Sent to Unity
/// (SceneRouter.SetTutorial) before LoadGame — see the_dasher_game_screen.dart.
final tutorialEnabledProvider =
    StateNotifierProvider<TutorialEnabledNotifier, bool>(
        (ref) => TutorialEnabledNotifier());

class TutorialEnabledNotifier extends StateNotifier<bool> {
  static const _key = 'dasher_tutorial_enabled';

  // Start ON; asynchronously replace with the stored value once prefs load.
  TutorialEnabledNotifier() : super(true) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getBool(_key);
    if (stored != null) state = stored;
  }

  Future<void> set(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}
