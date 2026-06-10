import '../models/fitness_level.dart';

/// Pure scoring engine for the elderly physical-fitness assessment.
///
/// This file is the SINGLE SOURCE OF TRUTH for every threshold. All values come
/// directly from the official manual "การประเมินสมรรถภาพทางกายในผู้สูงอายุ".
/// Do not duplicate these numbers anywhere else (UI, counters, etc.).
///
/// Manual page references are noted per function.
class FitnessScoring {
  FitnessScoring._();

  // ---------------------------------------------------------------------------
  // BMI (manual p.17)
  // ---------------------------------------------------------------------------

  /// BMI = weight(kg) / height(m)^2.
  static double computeBmi({
    required double weightKg,
    required double heightMeters,
  }) {
    if (heightMeters <= 0) {
      throw ArgumentError.value(heightMeters, 'heightMeters', 'must be > 0');
    }
    return weightKg / (heightMeters * heightMeters);
  }

  /// Five-band BMI classification.
  ///   < 18.5        → ผอม
  ///   18.5 – 22.9   → น้ำหนักปกติ
  ///   23.0 – 24.9   → น้ำหนักเกิน
  ///   25.0 – 29.9   → โรคอ้วน
  ///   >= 30.0       → โรคอ้วนอันตราย
  static BmiBand bmiBand(double bmi) {
    if (bmi < 18.5) return BmiBand.phom;
    if (bmi < 23.0) return BmiBand.pokati;
    if (bmi < 25.0) return BmiBand.namnakKoen;
    if (bmi < 30.0) return BmiBand.rokOuan;
    return BmiBand.rokOuanAntaray;
  }

  // ---------------------------------------------------------------------------
  // Three-band tests
  // ---------------------------------------------------------------------------

  /// 30-second Arm Curl (manual p.19): >11 ดีมาก / =11 ดี / <11 เสี่ยง.
  static FitnessLevel armCurlLevel(int reps) => _moreIsBetter(reps, good: 11);

  /// 30-second Chair Stand (manual p.20): >8 ดีมาก / =8 ดี / <8 เสี่ยง.
  static FitnessLevel chairStandLevel(int reps) => _moreIsBetter(reps, good: 8);

  /// 2-minute Step (manual p.23): >65 ดีมาก / =65 ดี / <65 เสี่ยง.
  static FitnessLevel stepLevel(int steps) => _moreIsBetter(steps, good: 65);

  /// Timed Up and Go (manual p.18): <12s ดีมาก / =12s ดี / >12s เสี่ยง.
  /// Lower time is better. Exact equality to 12.0 is faithful to the manual;
  /// real stopwatch readings almost always fall strictly above or below.
  static FitnessLevel tugLevel(double seconds) {
    if (seconds < 12.0) return FitnessLevel.dimak;
    if (seconds == 12.0) return FitnessLevel.di;
    return FitnessLevel.siang;
  }

  /// Shared "more is better" rule: value > good → ดีมาก, == good → ดี, < good → เสี่ยง.
  static FitnessLevel _moreIsBetter(int value, {required int good}) {
    if (value > good) return FitnessLevel.dimak;
    if (value == good) return FitnessLevel.di;
    return FitnessLevel.siang;
  }

  // Back Scratch (p.21) and Sit & Reach (p.22) have no numeric threshold — the
  // helper directly observes overlap/touch/none → ดีมาก/ดี/เสี่ยง. That mapping
  // is captured at the manual-entry screen, so there is no function here.

  // ---------------------------------------------------------------------------
  // Overall verdict — KINEX PRODUCT RULE (NOT from the manual)
  // ---------------------------------------------------------------------------

  /// Combines the SIX three-band tests into one overall verdict:
  ///   any เสี่ยง            → เสี่ยง
  ///   all ดีมาก            → ดีมาก
  ///   otherwise            → ดี
  ///
  /// BMI is intentionally excluded — it has its own 5-band scale and does not
  /// drag the overall (an obese-but-fit person is not auto-flagged เสี่ยง).
  /// The manual defines no composite score; this is a labelled Kinex rule.
  static FitnessLevel computeOverall(List<FitnessLevel> testLevels) {
    if (testLevels.isEmpty) {
      throw ArgumentError.value(testLevels, 'testLevels', 'must not be empty');
    }
    if (testLevels.contains(FitnessLevel.siang)) return FitnessLevel.siang;
    if (testLevels.every((l) => l == FitnessLevel.dimak)) {
      return FitnessLevel.dimak;
    }
    return FitnessLevel.di;
  }
}
