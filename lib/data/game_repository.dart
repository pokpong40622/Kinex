import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_session_record.dart';

/// Local persistence for completed arcade-game sessions (The Dasher + Hang
/// Glider), as a JSON string list in shared_preferences. Mirrors
/// WorldRepository — a flat list is enough. Kinex World keeps its own store.
class GameRepository {
  static const _key = 'kinex_game_records';

  Future<List<GameSessionRecord>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? const [];
    final records = raw
        .map((s) =>
            GameSessionRecord.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
    records.sort((a, b) => b.dateTime.compareTo(a.dateTime)); // newest first
    return records;
  }

  Future<void> add(GameSessionRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? <String>[];
    raw.add(jsonEncode(record.toJson()));
    await prefs.setStringList(_key, raw);
  }

  Future<void> delete(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? <String>[];
    raw.removeWhere(
        (s) => (jsonDecode(s) as Map<String, dynamic>)['id'] == id);
    await prefs.setStringList(_key, raw);
  }

  Future<GameSessionRecord?> byId(String id) async {
    final all = await load();
    for (final r in all) {
      if (r.id == id) return r;
    }
    return null;
  }
}

final gameRepositoryProvider =
    Provider<GameRepository>((ref) => GameRepository());

/// History list, newest first. Invalidate after saving/deleting to refresh.
final gameHistoryProvider =
    FutureProvider<List<GameSessionRecord>>((ref) async {
  return ref.watch(gameRepositoryProvider).load();
});
