import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Index of the selected "The Dasher" difficulty: 0=ง่าย (easy), 1=ปกติ
/// (normal), 2=ยาก (hard). Persisted so it survives restarts. Sent to Unity
/// (SceneRouter.SetDifficulty) before LoadGame — see the_dasher_game_screen.dart.
final dasherDifficultyProvider =
    StateNotifierProvider<DasherDifficultyNotifier, int>(
        (ref) => DasherDifficultyNotifier());

class DasherDifficultyNotifier extends StateNotifier<int> {
  static const _key = 'dasher_difficulty';

  DasherDifficultyNotifier() : super(1) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getInt(_key) ?? 1;
  }

  Future<void> select(int i) async {
    if (i == state) return;
    state = i;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, i);
  }
}
