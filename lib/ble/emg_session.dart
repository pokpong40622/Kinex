// Single app-level EMG calibration session, shared by every EMG page so that
// leaving/re-entering a page (or switching between the live-balance and graph
// pages) does NOT restart a leg's 30 s at-rest calibration, and both pages
// always see the same baseline/RMS-peak/threshold numbers.
//
// Persistence: once a leg finishes calibration, its coefficients are saved to
// shared_preferences (mirroring EmgRepository's pattern for MvcCalibration) so
// an app restart restores straight to live numbers instead of another 30 s
// wait. `rmsPeak` is a RUNNING maximum — it keeps growing as the user
// contracts harder, and %MVC is relative to it — so this session re-saves it
// periodically, not just once at calibration time, so %MVC stays comparable
// across app restarts.
import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/muscle.dart';
import 'emg_pipeline.dart';

const _kPrefsKeyPrefix = 'kinex_emg_calibration_';
const _kAutosaveInterval = Duration(seconds: 5);

/// One leg's persisted calibration coefficients.
class _StoredCalibration {
  final List<double> baseline;
  final List<double> rmsPeak;
  final List<double> threshold;
  final DateTime calibratedAt;

  const _StoredCalibration({
    required this.baseline,
    required this.rmsPeak,
    required this.threshold,
    required this.calibratedAt,
  });

  Map<String, dynamic> toJson() => {
        'baseline': baseline,
        'rmsPeak': rmsPeak,
        'threshold': threshold,
        'calibratedAt': calibratedAt.toIso8601String(),
      };

  factory _StoredCalibration.fromJson(Map<String, dynamic> j) =>
      _StoredCalibration(
        baseline:
            (j['baseline'] as List).map((e) => (e as num).toDouble()).toList(),
        rmsPeak:
            (j['rmsPeak'] as List).map((e) => (e as num).toDouble()).toList(),
        threshold:
            (j['threshold'] as List).map((e) => (e as num).toDouble()).toList(),
        calibratedAt: DateTime.parse(j['calibratedAt'] as String),
      );
}

/// Owns one [EmgLegMetrics] per leg for the whole app. Pages read [legs] and
/// attach/detach their own BLE listeners as before; this session only owns
/// the metrics objects, their persistence, and per-leg recalibration.
class EmgSession {
  final Map<LegSide, EmgLegMetrics> legs = {
    for (final leg in LegSide.values) leg: EmgLegMetrics(),
  };

  Timer? _autosave;

  EmgSession() {
    _restore();
    _autosave = Timer.periodic(_kAutosaveInterval, (_) => _persistAll());
  }

  void dispose() => _autosave?.cancel();

  String _keyFor(LegSide leg) => '$_kPrefsKeyPrefix${leg.code}';

  /// Legs the user has deliberately started recalibrating. [_restore] runs
  /// asynchronously at construction, and the session is built lazily the first
  /// time a page reads the provider — i.e. while the user is already looking at
  /// an EMG screen. Without this guard, pressing "ปรับเทียบใหม่" before the
  /// SharedPreferences round-trip completes would let the restore land on top
  /// of the fresh window and silently reinstate the old coefficients.
  final Set<LegSide> _skipRestore = {};

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    for (final leg in LegSide.values) {
      if (_skipRestore.contains(leg)) continue;
      final raw = prefs.getString(_keyFor(leg));
      if (raw == null) continue;
      final stored =
          _StoredCalibration.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      legs[leg]!.restoreCalibration(
        baseline: stored.baseline,
        rmsPeak: stored.rmsPeak,
        threshold: stored.threshold,
        calibratedAt: stored.calibratedAt,
      );
    }
  }

  Future<void> _persistOne(LegSide leg) async {
    final m = legs[leg]!;
    final at = m.calibratedAt;
    if (!m.calibrated || at == null) return;
    final stored = _StoredCalibration(
      baseline: List.of(m.baseline),
      rmsPeak: List.of(m.rmsPeak),
      threshold: List.of(m.threshold),
      calibratedAt: at,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFor(leg), jsonEncode(stored.toJson()));
  }

  Future<void> _persistAll() async {
    for (final leg in LegSide.values) {
      await _persistOne(leg);
    }
  }

  /// Clears ONLY [leg]'s stored calibration and restarts its 30 s at-rest
  /// window; the other leg is left untouched and stays live.
  Future<void> recalibrate(LegSide leg) async {
    _skipRestore.add(leg); // beat a still-in-flight _restore(); see the field
    legs[leg]!.beginRecalibration();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFor(leg));
  }
}

final emgSessionProvider = Provider<EmgSession>((ref) {
  final session = EmgSession();
  ref.onDispose(session.dispose);
  return session;
});
