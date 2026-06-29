import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/muscle.dart';
import '../models/emg_metrics.dart';

/// Local persistence for the user's MVC calibration (the four EMGPeak values).
/// One record — only the latest calibration matters. Stored as a JSON string in
/// shared_preferences, mirroring [AssessmentRepository].
class EmgRepository {
  static const _key = 'kinex_mvc_calibration';

  Future<MvcCalibration?> loadCalibration() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    return MvcCalibration.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveCalibration(MvcCalibration c) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(c.toJson()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

final emgRepositoryProvider = Provider<EmgRepository>((ref) => EmgRepository());

/// The stored MVC calibration, or null if the user has not calibrated yet.
/// Invalidate after saving to refresh the Info page.
final mvcCalibrationProvider = FutureProvider<MvcCalibration?>((ref) async {
  return ref.watch(emgRepositoryProvider).loadCalibration();
});

/// MOCK balance snapshot. The EMG hardware is not connected yet, so the Info
/// page and games read these plausible fixed %MVC values. When the sensors
/// stream in, replace this provider's body with a live computation from RMS +
/// the user's [MvcCalibration] — nothing else needs to change.
final mockBalanceReportProvider = Provider<BalanceReport>((ref) {
  MuscleReading r(Muscle m, double mean, double pct) =>
      MuscleReading(muscle: m, meanMicrovolts: mean, percentMvc: pct);
  return BalanceReport([
    JointBalance(
      joint: BalanceJoint.knee,
      agonist: r(Muscle.vl, 96, 32), // quad
      antagonist: r(Muscle.bf, 70, 27), // hamstring
    ),
    JointBalance(
      joint: BalanceJoint.ankle,
      agonist: r(Muscle.ta, 84, 41), // shin
      antagonist: r(Muscle.gcm, 122, 36), // calf
    ),
  ]);
});
