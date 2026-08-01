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
  // Per-leg mock %MVC: the right leg is given slightly different values so the
  // L/R display is visibly distinct before real EMG arrives.
  MuscleReading r(Muscle m, double mean, double pct) =>
      MuscleReading(muscle: m, meanMicrovolts: mean, percentMvc: pct);
  JointBalance knee(LegSide s, double dv) => JointBalance(
        joint: BalanceJoint.knee,
        side: s,
        agonist: r(Muscle.vl, 96 + dv, 32 + dv), // quad
        antagonist: r(Muscle.bf, 70 + dv, 27 + dv), // hamstring
      );
  JointBalance ankle(LegSide s, double dv) => JointBalance(
        joint: BalanceJoint.ankle,
        side: s,
        agonist: r(Muscle.ta, 84 + dv, 41 + dv), // shin
        antagonist: r(Muscle.gcm, 122 + dv, 36 + dv), // calf
      );
  return BalanceReport([
    knee(LegSide.left, 0),
    knee(LegSide.right, 6),
    ankle(LegSide.left, 0),
    ankle(LegSide.right, -1),
  ]);
});

/// The balance snapshot the Info page reads. Derived from the user's captured
/// MVC calibration (%MVC = EMGMean ÷ EMGPeak; CCI per antagonist pair, per leg)
/// once they have calibrated in the hardware guide; falls back to
/// [mockBalanceReportProvider] before any calibration exists.
final balanceReportProvider = Provider<BalanceReport>((ref) {
  final cal = ref.watch(mvcCalibrationProvider).value;
  if (cal == null || !cal.isComplete) return ref.watch(mockBalanceReportProvider);

  MuscleReading reading(Muscle m, LegSide side) {
    final s = cal.sampleFor(m, side);
    return MuscleReading(
      muscle: m,
      meanMicrovolts: s?.meanMicrovolts ?? 0,
      percentMvc: s?.percentMvc ?? 0,
    );
  }

  JointBalance joint(BalanceJoint j, LegSide side) {
    final pair = Muscle.forJoint(j); // agonist first
    return JointBalance(
      joint: j,
      side: side,
      agonist: reading(pair[0], side),
      antagonist: reading(pair[1], side),
    );
  }

  return BalanceReport([
    joint(BalanceJoint.knee, LegSide.left),
    joint(BalanceJoint.knee, LegSide.right),
    joint(BalanceJoint.ankle, LegSide.left),
    joint(BalanceJoint.ankle, LegSide.right),
  ]);
});
