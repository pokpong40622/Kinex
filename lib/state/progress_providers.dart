import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/world_repository.dart';
import '../models/world_session_record.dart';

// ── helpers ──────────────────────────────────────────────────────────────────

DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

/// Monday of the week containing [d].
DateTime _weekStart(DateTime d) {
  final day = _dateOnly(d);
  return day.subtract(Duration(days: day.weekday - 1));
}

/// Returns sessions dated on a specific calendar day.
List<WorldSessionRecord> _sessionsOnDay(
    List<WorldSessionRecord> all, DateTime day) {
  final target = _dateOnly(day);
  return all
      .where((r) => _dateOnly(r.dateTime) == target)
      .toList();
}

// ── providers ────────────────────────────────────────────────────────────────

/// Consecutive calendar days ending TODAY that have ≥1 session.
/// Returns 0 if no session today.
final dayStreakProvider = Provider<int>((ref) {
  final records = ref.watch(worldHistoryProvider).value ?? const [];
  if (records.isEmpty) return 0;
  final today = _dateOnly(DateTime.now());
  if (_sessionsOnDay(records, today).isEmpty) return 0;
  int streak = 0;
  DateTime check = today;
  while (_sessionsOnDay(records, check).isNotEmpty) {
    streak++;
    check = check.subtract(const Duration(days: 1));
  }
  return streak;
});

/// True if any session was recorded today.
final exercisedTodayProvider = Provider<bool>((ref) {
  final records = ref.watch(worldHistoryProvider).value ?? const [];
  return _sessionsOnDay(records, DateTime.now()).isNotEmpty;
});

/// Total exercise minutes (from durationSeconds) for the current Mon–Sun week.
final weekMinutesProvider = Provider<int>((ref) {
  final records = ref.watch(worldHistoryProvider).value ?? const [];
  if (records.isEmpty) return 0;
  final start = _weekStart(DateTime.now());
  final end = start.add(const Duration(days: 7));
  final secs = records
      .where((r) {
        final d = _dateOnly(r.dateTime);
        return !d.isBefore(start) && d.isBefore(end);
      })
      .fold<double>(0, (sum, r) => sum + r.durationSeconds);
  return (secs / 60).floor();
});

/// Rounded average averagePercent of the last 5 sessions; null if no sessions.
final recentScoreProvider = Provider<int?>((ref) {
  final records = ref.watch(worldHistoryProvider).value ?? const [];
  if (records.isEmpty) return null;
  final slice = records.take(5).toList();
  final avg = slice.fold<double>(0, (s, r) => s + r.averagePercent) / slice.length;
  return avg.round();
});

/// (this-week avg) − (last-week avg); null if either week has no sessions.
final weeklyImprovementProvider = Provider<int?>((ref) {
  final records = ref.watch(worldHistoryProvider).value ?? const [];
  if (records.isEmpty) return null;

  final thisStart = _weekStart(DateTime.now());
  final lastStart = thisStart.subtract(const Duration(days: 7));
  final lastEnd = thisStart;

  List<WorldSessionRecord> inRange(DateTime from, DateTime to) => records
      .where((r) {
        final d = _dateOnly(r.dateTime);
        return !d.isBefore(from) && d.isBefore(to);
      })
      .toList();

  final thisWeek = inRange(thisStart, thisStart.add(const Duration(days: 7)));
  final lastWeek = inRange(lastStart, lastEnd);

  if (thisWeek.isEmpty || lastWeek.isEmpty) return null;

  double avg(List<WorldSessionRecord> l) =>
      l.fold<double>(0, (s, r) => s + r.averagePercent) / l.length;

  return (avg(thisWeek) - avg(lastWeek)).round();
});

/// Length-7 list (index 0 = Mon … 6 = Sun): true if a session exists that day.
final weekDotsProvider = Provider<List<bool>>((ref) {
  final records = ref.watch(worldHistoryProvider).value ?? const [];
  final start = _weekStart(DateTime.now());
  return List.generate(7, (i) {
    final day = start.add(Duration(days: i));
    return _sessionsOnDay(records, day).isNotEmpty;
  });
});
