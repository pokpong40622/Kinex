import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/person_info.dart';

/// Last-used person profile, persisted across assessments so a returning senior
/// doesn't re-type name / age / gender / height / weight every time (these rarely
/// change). Only the stable identity + body metrics are kept — never test results.
/// Loaded once at startup (see app.dart) and rewritten when an assessment is saved.
class SavedProfile {
  final String? name;
  final int? age;
  final Gender? gender;
  final double? heightCm;
  final double? weightKg;

  const SavedProfile({
    this.name,
    this.age,
    this.gender,
    this.heightCm,
    this.weightKg,
  });

  static const empty = SavedProfile();

  bool get hasAny =>
      age != null ||
      heightCm != null ||
      weightKg != null ||
      (name != null && name!.isNotEmpty);

  Map<String, dynamic> toJson() => {
        'name': name,
        'age': age,
        'gender': gender?.token,
        'heightCm': heightCm,
        'weightKg': weightKg,
      };

  factory SavedProfile.fromJson(Map<String, dynamic> j) => SavedProfile(
        name: j['name'] as String?,
        age: j['age'] as int?,
        gender: j['gender'] == null ? null : Gender.fromToken(j['gender'] as String),
        heightCm: (j['heightCm'] as num?)?.toDouble(),
        weightKg: (j['weightKg'] as num?)?.toDouble(),
      );
}

class SavedProfileNotifier extends StateNotifier<SavedProfile> {
  static const _key = 'assessment_profile';

  SavedProfileNotifier() : super(SavedProfile.empty) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    try {
      state = SavedProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // ignore a corrupt/old record — falls back to empty
    }
  }

  Future<void> save({
    String? name,
    int? age,
    Gender? gender,
    double? heightCm,
    double? weightKg,
  }) async {
    state = SavedProfile(
      name: name,
      age: age,
      gender: gender,
      heightCm: heightCm,
      weightKg: weightKg,
    );
    await _persist();
  }

  /// Merge in only the supplied fields, keeping existing values for the rest.
  /// Used by the login page so setting name/age/gender never wipes a previously
  /// saved height/weight (and vice-versa). A null/empty field is left untouched.
  Future<void> patch({
    String? name,
    int? age,
    Gender? gender,
    double? heightCm,
    double? weightKg,
  }) async {
    state = SavedProfile(
      name: (name != null && name.isNotEmpty) ? name : state.name,
      age: age ?? state.age,
      gender: gender ?? state.gender,
      heightCm: heightCm ?? state.heightCm,
      weightKg: weightKg ?? state.weightKg,
    );
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.toJson()));
  }
}

final savedProfileProvider =
    StateNotifierProvider<SavedProfileNotifier, SavedProfile>(
  (ref) => SavedProfileNotifier(),
);
