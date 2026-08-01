// Shared EMG signal chain for the two leg boards: raw → baseline-subtract →
// RMS → %MVC → CCI.
//
// This is a direct port of the reference dashboard Test_Kinex_EMG.py so the
// numbers match what that script plots. Both the live balance page and the
// EMG graph page read from here — keep the maths in this one place.
//
// Two things differ from the app's older EMG code, deliberately:
//  * The boards PUSH all four channels continuously (VL,BF,TA,GCM). There is
//    no START/STOP handshake and no per-channel polling — do not add one.
//  * %MVC is self-calibrating: each channel's RMS is divided by the largest
//    RMS seen since the session began, so no stored MVC calibration is needed.
//  * CCI here is low/high (Python's `cci()`), NOT the 2·min/(a+b) form used by
//    JointBalance.cci elsewhere. The two are different curves.
import 'dart:collection';
import 'dart:math';

import '../models/muscle.dart';

// ── Tuning, mirrored 1:1 from Test_Kinex_EMG.py ──────────────────────────────
const int kEmgChannels = 4;

/// Channel order the firmware sends: 0=VL, 1=BF, 2=TA, 3=GCM.
const List<Muscle> kPadOrder = [Muscle.vl, Muscle.bf, Muscle.ta, Muscle.gcm];
const List<String> kMuscleLabels = ['VL', 'BF', 'TA', 'GCM'];

const double kCalibrationSeconds = 30.0;
const int kRmsWindowSamples = 25;
const double kThresholdFactor = 1.8;
const double kMinRmsThreshold = 8.0;

/// Raw ADC full scale on the ESP32 — the Python plots raw EMG on 0..4095.
const double kAdcMax = 4095;

/// Repaint cap for pages driven by this stream. Samples arrive far faster than
/// any screen needs to update, and repainting per sample rebuilds the page
/// hundreds of times a second.
const Duration kEmgPaintInterval = Duration(milliseconds: 66);

double emgRms(Iterable<double> values) {
  if (values.isEmpty) return 0;
  var sumSq = 0.0;
  var n = 0;
  for (final v in values) {
    sumSq += v * v;
    n++;
  }
  return sqrt(sumSq / n);
}

/// Python's `cci(a, b)` — the weaker muscle as a share of the stronger one.
/// 100% = both equally active (maximum co-contraction), 0% = only one active.
double emgCci(double a, double b) {
  final high = max(a, b);
  final low = min(a, b);
  if (high <= 0) return 0;
  return (low / high) * 100.0;
}

/// Parses one BLE notification into up to [kEmgChannels] raw ADC values.
/// Accepts both formats the Python `parse_emg` handles:
///   "EMG1:512 EMG2:488 EMG3:501 EMG4:497"  (labelled)
///   "512,488,501,497" or "512;488;501;497" (bare, comma or semicolon)
/// Which leg a line belongs to is decided by WHICH BOARD sent it, so there is
/// no leg code in the payload.
List<double> parseEmgLine(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return const [];

  final labelled =
      RegExp(r'EMG\d+\s*:\s*(-?\d+)', caseSensitive: false).allMatches(text);
  if (labelled.isNotEmpty) {
    return labelled
        .take(kEmgChannels)
        .map((m) => double.parse(m.group(1)!))
        .toList();
  }

  final out = <double>[];
  for (final part in text.replaceAll(';', ',').split(',')) {
    final s = part.trim();
    if (s.isEmpty) continue;
    final v = double.tryParse(s);
    if (v == null) return const []; // malformed → drop the whole line
    out.add(v);
    if (out.length == kEmgChannels) break;
  }
  return out;
}

/// One historical frame, used by the graph page's scrolling traces.
class EmgFrame {
  final DateTime t;
  final List<double> raw;
  final List<double> rms;
  final List<double> mvc;
  final double kneeCci;
  final double ankleCci;
  final double stability;
  const EmgFrame({
    required this.t,
    required this.raw,
    required this.rms,
    required this.mvc,
    required this.kneeCci,
    required this.ankleCci,
    required this.stability,
  });
}

/// Per-leg signal chain. Feed it [update] with parsed channel values; read the
/// public fields for display.
class EmgLegMetrics {
  /// How much history to retain for the scrolling plots.
  final int historyLimit;
  EmgLegMetrics({this.historyLimit = 1000});

  DateTime? _calibrationStartedAt;
  final List<List<double>> _calibrationSamples = [];
  bool calibrated = false;

  /// When this leg finished (or was restored from) calibration, or null if it
  /// has never calibrated. Shown to the user as "ปรับเทียบเมื่อ …".
  DateTime? calibratedAt;

  final List<double> baseline = List.filled(kEmgChannels, 0);
  final List<Queue<double>> _windows =
      List.generate(kEmgChannels, (_) => Queue<double>());

  final List<double> rmsValues = List.filled(kEmgChannels, 0);
  final List<double> rmsPeak = List.filled(kEmgChannels, 1);
  final List<double> threshold = List.filled(kEmgChannels, kMinRmsThreshold);
  final List<double> mvc = List.filled(kEmgChannels, 0);
  final List<bool> active = List.filled(kEmgChannels, false);
  final List<double> raw = List.filled(kEmgChannels, 0);

  double kneeCci = 0;
  double ankleCci = 0;

  /// Python keeps this as (knee + ankle) / 2.
  double stability = 0;
  bool isContracting = false;

  final Queue<EmgFrame> history = Queue<EmgFrame>();

  /// Seconds of rest calibration still to go, or null once calibrated.
  double? get calibrationRemaining {
    if (calibrated) return null;
    final started = _calibrationStartedAt;
    if (started == null) return kCalibrationSeconds;
    final elapsed = DateTime.now().difference(started).inMilliseconds / 1000.0;
    return max(0, kCalibrationSeconds - elapsed);
  }

  void reset() {
    _calibrationStartedAt = null;
    _calibrationSamples.clear();
    calibrated = false;
    calibratedAt = null;
    for (var i = 0; i < kEmgChannels; i++) {
      baseline[i] = 0;
      _windows[i].clear();
      rmsValues[i] = 0;
      rmsPeak[i] = 1;
      threshold[i] = kMinRmsThreshold;
      mvc[i] = 0;
      active[i] = false;
      raw[i] = 0;
    }
    kneeCci = 0;
    ankleCci = 0;
    stability = 0;
    isContracting = false;
    history.clear();
  }

  /// Clears this leg's calibration and restarts its 30 s at-rest window. Used
  /// by the per-leg "recalibrate" buttons — identical to [reset] today, kept
  /// as a separate name so call sites read as intent (redo calibration) rather
  /// than a generic reset.
  void beginRecalibration() => reset();

  /// Restores previously-persisted coefficients (see `emg_session.dart`) so
  /// this leg goes straight to live numbers instead of re-running the 30 s
  /// at-rest window. [rmsPeak] should be the LATEST running peak that was
  /// saved, not just the value captured at calibration time — %MVC is
  /// relative to it, and it only ever grows as the user contracts harder, so
  /// restoring a stale seed would make %MVC read too high after a restart.
  void restoreCalibration({
    required List<double> baseline,
    required List<double> rmsPeak,
    required List<double> threshold,
    required DateTime calibratedAt,
  }) {
    for (var i = 0; i < kEmgChannels; i++) {
      this.baseline[i] = baseline[i];
      this.rmsPeak[i] = rmsPeak[i];
      this.threshold[i] = threshold[i];
    }
    this.calibratedAt = calibratedAt;
    calibrated = true;
  }

  void update(List<double> values) {
    if (values.length < kEmgChannels) return;
    final v = values.sublist(0, kEmgChannels);
    for (var i = 0; i < kEmgChannels; i++) {
      raw[i] = v[i];
    }

    if (!calibrated) {
      _calibrationStartedAt ??= DateTime.now();
      _calibrationSamples.add(v);
      if ((calibrationRemaining ?? 0) <= 0) _finishCalibration();
      return;
    }

    for (var i = 0; i < kEmgChannels; i++) {
      final adjusted = v[i] - baseline[i];
      final w = _windows[i];
      w.addLast(adjusted);
      while (w.length > kRmsWindowSamples) {
        w.removeFirst();
      }
      rmsValues[i] = emgRms(w);
      // Running peak — the strongest contraction so far becomes 100 %MVC.
      rmsPeak[i] = max(max(rmsPeak[i], rmsValues[i]), 1);
      mvc[i] = min(rmsValues[i] / rmsPeak[i] * 100.0, 100.0);
      active[i] = rmsValues[i] >= threshold[i];
    }

    isContracting = active[2] || active[3]; // TA or GCM
    kneeCci = emgCci(mvc[0], mvc[1]); // VL vs BF
    ankleCci = emgCci(mvc[2], mvc[3]); // TA vs GCM
    stability = (kneeCci + ankleCci) / 2.0;

    history.addLast(EmgFrame(
      t: DateTime.now(),
      raw: List.of(raw),
      rms: List.of(rmsValues),
      mvc: List.of(mvc),
      kneeCci: kneeCci,
      ankleCci: ankleCci,
      stability: stability,
    ));
    while (history.length > historyLimit) {
      history.removeFirst();
    }
  }

  void _finishCalibration() {
    if (_calibrationSamples.isEmpty) return;
    for (var c = 0; c < kEmgChannels; c++) {
      final column = _calibrationSamples.map((s) => s[c]).toList();
      final mean = column.reduce((a, b) => a + b) / column.length;
      baseline[c] = mean;
      final restRms = emgRms(column.map((x) => x - mean));
      rmsPeak[c] = max(restRms, 1);
      threshold[c] = max(restRms * kThresholdFactor, kMinRmsThreshold);
    }
    calibrated = true;
    calibratedAt = DateTime.now();
    _calibrationSamples.clear();
  }
}
