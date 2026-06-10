import 'fitness_level.dart';

/// Per-test result value objects. Each carries the raw measurement plus (where
/// applicable) its [FitnessLevel] classification, and JSON round-trips.

/// Weight / Height — raw value only, no classification.
class MeasurementResult {
  final double value;
  final String unit; // 'kg' | 'cm'
  const MeasurementResult(this.value, this.unit);

  Map<String, dynamic> toJson() => {'value': value, 'unit': unit};
  factory MeasurementResult.fromJson(Map<String, dynamic> j) =>
      MeasurementResult((j['value'] as num).toDouble(), j['unit'] as String);
}

/// BMI — value + 5-band classification.
class BmiResult {
  final double value;
  final BmiBand band;
  const BmiResult(this.value, this.band);

  Map<String, dynamic> toJson() => {'value': value, 'band': band.token};
  factory BmiResult.fromJson(Map<String, dynamic> j) => BmiResult(
        (j['value'] as num).toDouble(),
        BmiBand.fromToken(j['band'] as String),
      );
}

/// Back Scratch / Sit & Reach — helper directly observes the level.
class BestOfTwoResult {
  final FitnessLevel level;
  const BestOfTwoResult(this.level);

  Map<String, dynamic> toJson() => {'level': level.token};
  factory BestOfTwoResult.fromJson(Map<String, dynamic> j) =>
      BestOfTwoResult(FitnessLevel.fromToken(j['level'] as String));
}

/// Arm Curl / Chair Stand / 2-min Step — rep count + level.
class RepCountResult {
  final int reps;
  final FitnessLevel level;
  const RepCountResult(this.reps, this.level);

  Map<String, dynamic> toJson() => {'reps': reps, 'level': level.token};
  factory RepCountResult.fromJson(Map<String, dynamic> j) => RepCountResult(
        j['reps'] as int,
        FitnessLevel.fromToken(j['level'] as String),
      );
}

/// TUG — elapsed seconds + level.
class TimedResult {
  final double seconds;
  final FitnessLevel level;
  const TimedResult(this.seconds, this.level);

  Map<String, dynamic> toJson() => {'seconds': seconds, 'level': level.token};
  factory TimedResult.fromJson(Map<String, dynamic> j) => TimedResult(
        (j['seconds'] as num).toDouble(),
        FitnessLevel.fromToken(j['level'] as String),
      );
}
