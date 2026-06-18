import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/world_session_record.dart';

/// Local persistence for completed Kinex World classes, as a JSON string list in
/// shared_preferences. Mirrors AssessmentRepository — a flat list is enough.
class WorldRepository {
  static const _key = 'kinex_world_records';

  Future<List<WorldSessionRecord>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? const [];
    final records = raw
        .map((s) =>
            WorldSessionRecord.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
    records.sort((a, b) => b.dateTime.compareTo(a.dateTime)); // newest first
    return records;
  }

  Future<void> add(WorldSessionRecord record) async {
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

  Future<WorldSessionRecord?> byId(String id) async {
    final all = await load();
    for (final r in all) {
      if (r.id == id) return r;
    }
    return null;
  }
}

final worldRepositoryProvider =
    Provider<WorldRepository>((ref) => WorldRepository());

/// History list, newest first. Invalidate after saving/deleting to refresh.
final worldHistoryProvider =
    FutureProvider<List<WorldSessionRecord>>((ref) async {
  return ref.watch(worldRepositoryProvider).load();
});
