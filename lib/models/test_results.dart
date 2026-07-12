import 'fitness_level.dart';

/// Per-test result value objects for the SPPB assessment. Each carries the raw
/// measurement plus its SPPB point score (0–4), and JSON round-trips.

/// Weight / Height — raw value only, no classification.
class MeasurementResult {
  final double value;
  final String unit; // 'kg' | 'cm'
  const MeasurementResult(this.value, this.unit);

  Map<String, dynamic> toJson() => {'value': value, 'unit': unit};
  factory MeasurementResult.fromJson(Map<String, dynamic> j) =>
      MeasurementResult((j['value'] as num).toDouble(), j['unit'] as String);
}

/// BMI — value + 5-band classification. Reported on its own scale, separate
/// from the SPPB fall-risk score.
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

/// Balance test — seconds held for each of the three stances + domain points (0–4).
/// A stance skipped by SPPB gating is stored as 0 seconds.
class BalanceResult {
  final double sideBySideSec;
  final double semiTandemSec;
  final double tandemSec;
  final int points;
  const BalanceResult({
    required this.sideBySideSec,
    required this.semiTandemSec,
    required this.tandemSec,
    required this.points,
  });

  Map<String, dynamic> toJson() => {
        'sideBySideSec': sideBySideSec,
        'semiTandemSec': semiTandemSec,
        'tandemSec': tandemSec,
        'points': points,
      };
  factory BalanceResult.fromJson(Map<String, dynamic> j) => BalanceResult(
        sideBySideSec: (j['sideBySideSec'] as num).toDouble(),
        semiTandemSec: (j['semiTandemSec'] as num).toDouble(),
        tandemSec: (j['tandemSec'] as num).toDouble(),
        points: j['points'] as int,
      );
}

/// Gait speed test — best 4 m walk time (seconds) + points (0–4). [unable] marks
/// a participant who could not walk it (0 points).
class GaitResult {
  final double seconds;
  final bool unable;
  final int points;
  const GaitResult(
      {required this.seconds, required this.unable, required this.points});

  Map<String, dynamic> toJson() =>
      {'seconds': seconds, 'unable': unable, 'points': points};
  factory GaitResult.fromJson(Map<String, dynamic> j) => GaitResult(
        seconds: (j['seconds'] as num).toDouble(),
        unable: j['unable'] as bool? ?? false,
        points: j['points'] as int,
      );
}

/// Chair stand test — time (seconds) to complete five rises + points (0–4).
/// [preTestPassed] is false when the participant could not stand once unaided
/// (scores 0, five-rep timing skipped).
class ChairStandResult {
  final bool preTestPassed;
  final double seconds;
  final int points;
  const ChairStandResult(
      {required this.preTestPassed,
      required this.seconds,
      required this.points});

  Map<String, dynamic> toJson() =>
      {'preTestPassed': preTestPassed, 'seconds': seconds, 'points': points};
  factory ChairStandResult.fromJson(Map<String, dynamic> j) => ChairStandResult(
        preTestPassed: j['preTestPassed'] as bool? ?? true,
        seconds: (j['seconds'] as num).toDouble(),
        points: j['points'] as int,
      );
}
