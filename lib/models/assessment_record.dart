import 'fall_risk.dart';
import 'person_info.dart';
import 'test_results.dart';

/// A completed SPPB assessment, persisted to history. [totalScore] is the 0–12
/// SPPB total (balance + gait + chair stand); [risk] is its fall-risk band. BMI
/// is reported separately on its own band and does not feed the total.
class AssessmentRecord {
  /// Bumped when the persisted shape changes. Records written by the old Senior
  /// Fitness Test build have no (or a lower) version and are skipped on load.
  static const int currentSchemaVersion = 2;

  final String id;
  final DateTime dateTime;
  final PersonInfo person;
  final MeasurementResult weight;
  final MeasurementResult height;
  final BmiResult bmi;
  final BalanceResult balance;
  final GaitResult gait;
  final ChairStandResult chairStand;
  final int totalScore;
  final FallRisk risk;

  const AssessmentRecord({
    required this.id,
    required this.dateTime,
    required this.person,
    required this.weight,
    required this.height,
    required this.bmi,
    required this.balance,
    required this.gait,
    required this.chairStand,
    required this.totalScore,
    required this.risk,
  });

  Map<String, dynamic> toJson() => {
        'schemaVersion': currentSchemaVersion,
        'id': id,
        'dateTime': dateTime.toIso8601String(),
        'person': person.toJson(),
        'weight': weight.toJson(),
        'height': height.toJson(),
        'bmi': bmi.toJson(),
        'balance': balance.toJson(),
        'gait': gait.toJson(),
        'chairStand': chairStand.toJson(),
        'totalScore': totalScore,
        'risk': risk.token,
      };

  factory AssessmentRecord.fromJson(Map<String, dynamic> j) => AssessmentRecord(
        id: j['id'] as String,
        dateTime: DateTime.parse(j['dateTime'] as String),
        person: PersonInfo.fromJson(j['person'] as Map<String, dynamic>),
        weight: MeasurementResult.fromJson(j['weight'] as Map<String, dynamic>),
        height: MeasurementResult.fromJson(j['height'] as Map<String, dynamic>),
        bmi: BmiResult.fromJson(j['bmi'] as Map<String, dynamic>),
        balance: BalanceResult.fromJson(j['balance'] as Map<String, dynamic>),
        gait: GaitResult.fromJson(j['gait'] as Map<String, dynamic>),
        chairStand:
            ChairStandResult.fromJson(j['chairStand'] as Map<String, dynamic>),
        totalScore: j['totalScore'] as int,
        risk: FallRisk.fromToken(j['risk'] as String),
      );

  /// Parse a stored record, or null if it is an incompatible legacy shape
  /// (e.g. a Senior Fitness Test record from before the SPPB switch). Lets the
  /// repository silently drop old entries instead of crashing.
  static AssessmentRecord? tryFromJson(Map<String, dynamic> j) {
    final version = j['schemaVersion'] as int? ?? 1;
    if (version < currentSchemaVersion) return null;
    try {
      return AssessmentRecord.fromJson(j);
    } catch (_) {
      return null;
    }
  }
}
