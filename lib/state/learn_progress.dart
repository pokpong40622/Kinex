import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks which "เรียนรู้ท่าฝึก" (learn library) poses the user has already
/// opened at least once. Undiscovered poses render greyed-out/locked in the
/// library until viewed here — see `learn_library_page.dart`.
final learnProgressProvider =
    StateNotifierProvider<LearnProgressNotifier, Set<String>>(
        (ref) => LearnProgressNotifier());

class LearnProgressNotifier extends StateNotifier<Set<String>> {
  static const _key = 'learn_viewed_poses';

  // Start empty; asynchronously replace with the stored value once prefs load.
  LearnProgressNotifier() : super(const {}) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_key);
    if (stored != null) state = stored.toSet();
  }

  bool isViewed(String id) => state.contains(id);

  Future<void> markViewed(String id) async {
    if (state.contains(id)) return;
    state = {...state, id};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, state.toList());
  }
}
