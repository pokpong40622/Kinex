import 'fitness_level.dart';
import 'person_info.dart';
import 'test_results.dart';

/// A completed assessment, persisted to history. The [overall] verdict is the
/// labelled Kinex rule (see FitnessScoring.computeOverall) over the six
/// three-band tests; BMI is reported separately on its own band.
class AssessmentRecord {
  final String id;
  final DateTime dateTime;
  final PersonInfo person;
  final MeasurementResult weight;
  final MeasurementResult height;
  final BmiResult bmi;
  final BestOfTwoResult backScratch;
  final BestOfTwoResult sitAndReach;
  final RepCountResult armCurl;
  final RepCountResult chairStand;
  final RepCountResult stepTest;
  final TimedResult tug;
  final FitnessLevel overall;

  const AssessmentRecord({
    required this.id,
    required this.dateTime,
    required this.person,
    required this.weight,
    required this.height,
    required this.bmi,
    required this.backScratch,
    required this.sitAndReach,
    required this.armCurl,
    required this.chairStand,
    required this.stepTest,
    required this.tug,
    required this.overall,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'dateTime': dateTime.toIso8601String(),
        'person': person.toJson(),
        'weight': weight.toJson(),
        'height': height.toJson(),
        'bmi': bmi.toJson(),
        'backScratch': backScratch.toJson(),
        'sitAndReach': sitAndReach.toJson(),
        'armCurl': armCurl.toJson(),
        'chairStand': chairStand.toJson(),
        'stepTest': stepTest.toJson(),
        'tug': tug.toJson(),
        'overall': overall.token,
      };

  factory AssessmentRecord.fromJson(Map<String, dynamic> j) => AssessmentRecord(
        id: j['id'] as String,
        dateTime: DateTime.parse(j['dateTime'] as String),
        person: PersonInfo.fromJson(j['person'] as Map<String, dynamic>),
        weight: MeasurementResult.fromJson(j['weight'] as Map<String, dynamic>),
        height: MeasurementResult.fromJson(j['height'] as Map<String, dynamic>),
        bmi: BmiResult.fromJson(j['bmi'] as Map<String, dynamic>),
        backScratch:
            BestOfTwoResult.fromJson(j['backScratch'] as Map<String, dynamic>),
        sitAndReach:
            BestOfTwoResult.fromJson(j['sitAndReach'] as Map<String, dynamic>),
        armCurl: RepCountResult.fromJson(j['armCurl'] as Map<String, dynamic>),
        chairStand:
            RepCountResult.fromJson(j['chairStand'] as Map<String, dynamic>),
        stepTest: RepCountResult.fromJson(j['stepTest'] as Map<String, dynamic>),
        tug: TimedResult.fromJson(j['tug'] as Map<String, dynamic>),
        overall: FitnessLevel.fromToken(j['overall'] as String),
      );
}
