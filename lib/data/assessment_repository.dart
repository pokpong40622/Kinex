import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/assessment_record.dart';

/// Local persistence for completed assessments, as a JSON string list in
/// shared_preferences. Records are small; a flat list is sufficient for v1.
class AssessmentRepository {
  static const _key = 'kinex_assessment_records';

  Future<List<AssessmentRecord>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? const [];
    final records = raw
        .map((s) =>
            AssessmentRecord.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
    records.sort((a, b) => b.dateTime.compareTo(a.dateTime)); // newest first
    return records;
  }

  Future<void> add(AssessmentRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? <String>[];
    raw.add(jsonEncode(record.toJson()));
    await prefs.setStringList(_key, raw);
  }

  Future<void> delete(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? <String>[];
    raw.removeWhere((s) =>
        (jsonDecode(s) as Map<String, dynamic>)['id'] == id);
    await prefs.setStringList(_key, raw);
  }
}

final assessmentRepositoryProvider =
    Provider<AssessmentRepository>((ref) => AssessmentRepository());

/// History list, newest first. Invalidate after saving/deleting to refresh.
final assessmentHistoryProvider =
    FutureProvider<List<AssessmentRecord>>((ref) async {
  return ref.watch(assessmentRepositoryProvider).load();
});
