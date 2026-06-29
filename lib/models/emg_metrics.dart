import 'muscle.dart';

/// The user's Maximum Voluntary Contraction reference: the peak EMG amplitude
/// (µV) recorded while they flex each muscle as hard as they can. This is the
/// 100% denominator for every %MVC reading ("EMGPeak", per PMC11163366).
///
/// This is the value the Info page "MVC value" card stores and the EMG games
/// normalise against. Persisted by EmgRepository.
class MvcCalibration {
  final Map<Muscle, double> peakMicrovolts;
  final DateTime calibratedAt;

  const MvcCalibration({
    required this.peakMicrovolts,
    required this.calibratedAt,
  });

  double? peakFor(Muscle m) => peakMicrovolts[m];

  /// All four muscles have a positive peak recorded.
  bool get isComplete =>
      Muscle.values.every((m) => (peakMicrovolts[m] ?? 0) > 0);

  Map<String, dynamic> toJson() => {
        'calibratedAt': calibratedAt.toIso8601String(),
        'peaks': {
          for (final e in peakMicrovolts.entries) e.key.code: e.value,
        },
      };

  factory MvcCalibration.fromJson(Map<String, dynamic> j) {
    final peaks = <Muscle, double>{};
    final raw = (j['peaks'] as Map).cast<String, dynamic>();
    for (final m in Muscle.values) {
      final v = raw[m.code];
      if (v is num) peaks[m] = v.toDouble();
    }
    return MvcCalibration(
      peakMicrovolts: peaks,
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

/// Co-contraction of one joint's antagonist pair, the basis of the
/// "การทรงตัวของข้อเข่า/ข้อเท้า" balance metric shown to the user.
class JointBalance {
  final BalanceJoint joint;
  final MuscleReading agonist;
  final MuscleReading antagonist;

  const JointBalance({
    required this.joint,
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

/// A full EMG balance snapshot — one [JointBalance] per joint. Built from a
/// recorded task plus the user's [MvcCalibration], or from mock data while the
/// hardware is not connected.
class BalanceReport {
  final List<JointBalance> joints;
  const BalanceReport(this.joints);

  JointBalance forJoint(BalanceJoint j) =>
      joints.firstWhere((x) => x.joint == j);
}
