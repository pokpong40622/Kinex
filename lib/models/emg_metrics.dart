import 'muscle.dart';

/// One EMG capture for a single muscle on a single leg: the peak (EMGPeak, the
/// 100% MVC reference) and mean (EMGMean) amplitude over the lift test, in µV.
class EmgSample {
  final double peakMicrovolts; // EMGPeak
  final double meanMicrovolts; // EMGMean

  const EmgSample({required this.peakMicrovolts, required this.meanMicrovolts});

  /// EMGMean ÷ EMGPeak × 100, or null if no peak.
  double? get percentMvc => peakMicrovolts > 0
      ? (meanMicrovolts / peakMicrovolts * 100).clamp(0, 100).toDouble()
      : null;

  Map<String, dynamic> toJson() =>
      {'peak': peakMicrovolts, 'mean': meanMicrovolts};

  factory EmgSample.fromJson(Map<String, dynamic> j) => EmgSample(
        peakMicrovolts: (j['peak'] as num).toDouble(),
        meanMicrovolts: (j['mean'] as num).toDouble(),
      );
}

/// The user's Maximum Voluntary Contraction reference — one [EmgSample] per
/// muscle PER LEG (the pad sits at the same spot on both legs, so each muscle is
/// measured for the left and the right side). Captured in the EMG hardware guide
/// and persisted by EmgRepository.
class MvcCalibration {
  /// muscle → (side → sample).
  final Map<Muscle, Map<LegSide, EmgSample>> samples;
  final DateTime calibratedAt;

  const MvcCalibration({required this.samples, required this.calibratedAt});

  EmgSample? sampleFor(Muscle m, LegSide side) => samples[m]?[side];

  /// Every muscle has a positive peak on BOTH legs.
  bool get isComplete => Muscle.values.every((m) =>
      LegSide.values.every((s) => (samples[m]?[s]?.peakMicrovolts ?? 0) > 0));

  Map<String, dynamic> toJson() => {
        'calibratedAt': calibratedAt.toIso8601String(),
        'samples': {
          for (final m in samples.keys)
            m.code: {
              for (final e in samples[m]!.entries) e.key.code: e.value.toJson(),
            },
        },
      };

  factory MvcCalibration.fromJson(Map<String, dynamic> j) {
    final out = <Muscle, Map<LegSide, EmgSample>>{};
    final raw = (j['samples'] as Map?)?.cast<String, dynamic>() ?? const {};
    for (final m in Muscle.values) {
      final sideRaw = (raw[m.code] as Map?)?.cast<String, dynamic>();
      if (sideRaw == null) continue;
      final sideMap = <LegSide, EmgSample>{};
      for (final s in LegSide.values) {
        final sv = sideRaw[s.code];
        if (sv is Map) {
          sideMap[s] = EmgSample.fromJson(sv.cast<String, dynamic>());
        }
      }
      if (sideMap.isNotEmpty) out[m] = sideMap;
    }
    return MvcCalibration(
      samples: out,
      calibratedAt: DateTime.parse(j['calibratedAt'] as String),
    );
  }
}

/// One muscle's activation during a task. [meanMicrovolts] is the mean/RMS
/// amplitude (EMGMean); [percentMvc] is EMGMean / EMGPeak × 100.
class MuscleReading {
  final Muscle muscle;
  final double meanMicrovolts;
  final double percentMvc; // 0..100

  const MuscleReading({
    required this.muscle,
    required this.meanMicrovolts,
    required this.percentMvc,
  });
}

/// Co-contraction of one joint's antagonist pair on one leg, the basis of the
/// "การทรงตัวของข้อเข่า/ข้อเท้า" balance metric shown to the user.
class JointBalance {
  final BalanceJoint joint;
  final LegSide side;
  final MuscleReading agonist;
  final MuscleReading antagonist;

  const JointBalance({
    required this.joint,
    required this.side,
    required this.agonist,
    required this.antagonist,
  });

  /// Co-Contraction Index (ดัชนีการหดตัวร่วม), %. A simplified, display-friendly
  /// index over the pair's %MVC: 100% = both muscles equally active (maximum
  /// co-working / joint stiffening), 0% = only one side active. The live device
  /// can swap this for a clinical formula (Rudolph/Falconer) without touching UI.
  ///   CCI = 2 · min(a, b) / (a + b) · 100
  double get cci {
    final a = agonist.percentMvc;
    final b = antagonist.percentMvc;
    final sum = a + b;
    if (sum <= 0) return 0;
    final lo = a < b ? a : b;
    return (2 * lo / sum) * 100;
  }
}

/// A full EMG balance snapshot — one [JointBalance] per joint PER LEG (4 total).
/// Built from the user's [MvcCalibration], or from mock data while the hardware
/// is not connected.
class BalanceReport {
  final List<JointBalance> joints;
  const BalanceReport(this.joints);

  JointBalance forJoint(BalanceJoint j, LegSide side) =>
      joints.firstWhere((x) => x.joint == j && x.side == side);
}
