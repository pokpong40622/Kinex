import 'package:shared_preferences/shared_preferences.dart';

class DailyProgress {
  final int points;
  final int goal;

  const DailyProgress({required this.points, required this.goal});

  double get ratio => goal == 0 ? 1 : (points / goal).clamp(0, 1).toDouble();
  bool get isComplete => points >= goal;
}

class DailyProgressStore {
  DailyProgressStore._();

  static const int dailyGoal = 100;
  static const int pointsPerCorrectAnswer = 10;
  static const String _dateKey = 'daily_progress_date';
  static const String _pointsKey = 'daily_progress_points';

  static int pointsForScore(int correctCount) =>
      correctCount * pointsPerCorrectAnswer;

  static Future<DailyProgress> today() async {
    final prefs = await SharedPreferences.getInstance();
    await _resetIfNeeded(prefs);
    return DailyProgress(
      points: prefs.getInt(_pointsKey) ?? 0,
      goal: dailyGoal,
    );
  }

  static Future<DailyProgress> addQuizScore(int correctCount) async {
    final prefs = await SharedPreferences.getInstance();
    await _resetIfNeeded(prefs);
    final current = prefs.getInt(_pointsKey) ?? 0;
    final next = current + pointsForScore(correctCount);
    await prefs.setInt(_pointsKey, next);
    return DailyProgress(points: next, goal: dailyGoal);
  }

  static Future<void> _resetIfNeeded(SharedPreferences prefs) async {
    final todayKey = _todayKey();
    if (prefs.getString(_dateKey) == todayKey) return;
    await prefs.setString(_dateKey, todayKey);
    await prefs.setInt(_pointsKey, 0);
  }

  static String _todayKey() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }
}
