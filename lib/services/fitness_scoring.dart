import '../models/fitness_level.dart';

/// BMI scoring for the assessment's body-info intake stage.
///
/// The movement tests are scored by the SPPB engine (see [SppbScoring]); BMI is
/// reported on its own 5-band scale and does not feed the fall-risk total. No
/// Flutter imports — trivially unit-testable.
class FitnessScoring {
  FitnessScoring._();

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

  /// Five-band BMI classification (manual p.17).
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
}
