import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Index of the active accent colour set (see KColors.accentSets). The user
/// picks it from the shop "ธีมสี" section; persisted so it survives restarts.
/// app.dart applies it to KColors on startup and whenever it changes.
final accentSetProvider =
    StateNotifierProvider<AccentSetNotifier, int>((ref) => AccentSetNotifier());

class AccentSetNotifier extends StateNotifier<int> {
  static const _key = 'accent_set';

  AccentSetNotifier() : super(0) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getInt(_key) ?? 0;
  }

  Future<void> select(int i) async {
    if (i == state) return;
    state = i;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, i);
  }
}
