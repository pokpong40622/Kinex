import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// One exercise's average score within a session (0..100).
class WorldExerciseScore {
  final String id;
  final String name;
  final double score;

  const WorldExerciseScore(
      {required this.id, required this.name, required this.score});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'score': score};

  factory WorldExerciseScore.fromJson(Map<String, dynamic> j) =>
      WorldExerciseScore(
        id: j['id'] as String? ?? '',
        name: j['name'] as String? ?? '',
        score: (j['score'] as num?)?.toDouble() ?? 0,
      );
}

/// A completed Kinex World class, persisted to history. Built from the Unity
/// results payload (`WorldSessionResult` JSON) plus a local id + timestamp.
class WorldSessionRecord {
  final String id;
  final DateTime dateTime;
  final String routineId;
  final String routineName;
  final double averagePercent; // 0..100 — the headline metric
  final double durationSeconds;
  final List<WorldExerciseScore> exercises;

  const WorldSessionRecord({
    required this.id,
    required this.dateTime,
    required this.routineId,
    required this.routineName,
    required this.averagePercent,
    required this.durationSeconds,
    required this.exercises,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'dateTime': dateTime.toIso8601String(),
        'routineId': routineId,
        'routineName': routineName,
        'averagePercent': averagePercent,
        'durationSeconds': durationSeconds,
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };

  factory WorldSessionRecord.fromJson(Map<String, dynamic> j) =>
      WorldSessionRecord(
        id: j['id'] as String,
        dateTime: DateTime.parse(j['dateTime'] as String),
        routineId: j['routineId'] as String? ?? '',
        routineName: j['routineName'] as String? ?? '',
        averagePercent: (j['averagePercent'] as num?)?.toDouble() ?? 0,
        durationSeconds: (j['durationSeconds'] as num?)?.toDouble() ?? 0,
        exercises: ((j['exercises'] as List?) ?? const [])
            .map((e) =>
                WorldExerciseScore.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  /// Build a record from the raw Unity `WorldSessionResult` JSON, stamping a
  /// local id + time and a human routine name.
  factory WorldSessionRecord.fromUnity(
    Map<String, dynamic> j, {
    required String id,
    required DateTime dateTime,
    required String routineName,
  }) =>
      WorldSessionRecord(
        id: id,
        dateTime: dateTime,
        routineId: j['routineId'] as String? ?? '',
        routineName: routineName,
        averagePercent: (j['averagePercent'] as num?)?.toDouble() ?? 0,
        durationSeconds: (j['durationSeconds'] as num?)?.toDouble() ?? 0,
        exercises: ((j['exercises'] as List?) ?? const [])
            .map((e) =>
                WorldExerciseScore.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  /// Lowest-scoring exercise — used for the "focus next time" tip.
  WorldExerciseScore? get weakest {
    if (exercises.isEmpty) return null;
    return exercises.reduce((a, b) => a.score <= b.score ? a : b);
  }
}

/// Qualitative band for an average performance %, mirroring the assessment
/// FitnessLevel badge idea but in the World tone (encouraging, never failing).
class WorldBand {
  final String thaiLabel;
  final Color color;
  const WorldBand(this.thaiLabel, this.color);

  static WorldBand of(double avg) {
    if (avg >= 85) return const WorldBand('ยอดเยี่ยม', KColors.greenDark);
    if (avg >= 70) return const WorldBand('ดีมาก', KColors.purple);
    if (avg >= 50) return const WorldBand('ดี', KColors.blue);
    return const WorldBand('สู้ๆ นะ', KColors.orangeDark);
  }
}
