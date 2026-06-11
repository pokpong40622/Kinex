import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/person_info.dart';
import '../models/test_results.dart';

/// In-progress assessment, carried across all screens. In-memory only (a
/// Riverpod Notifier) — loss on OS process death is an accepted v1 limitation.
@immutable
class AssessmentSession {
  final PersonInfo? person;
  final MeasurementResult? height;
  final MeasurementResult? weight;
  final BmiResult? bmi;
  final BestOfTwoResult? backScratch;
  final BestOfTwoResult? sitAndReach;
  final RepCountResult? armCurl;
  final RepCountResult? chairStand;
  final RepCountResult? stepTest;
  final TimedResult? tug;

  const AssessmentSession({
    this.person,
    this.height,
    this.weight,
    this.bmi,
    this.backScratch,
    this.sitAndReach,
    this.armCurl,
    this.chairStand,
    this.stepTest,
    this.tug,
  });

  static const empty = AssessmentSession();

  /// Result for a movement-test id, or null if not done yet.
  Object? resultFor(String testId) => switch (testId) {
        'back_scratch' => backScratch,
        'sit_reach' => sitAndReach,
        'arm_curl' => armCurl,
        'chair_stand' => chairStand,
        'step_test' => stepTest,
        'tug' => tug,
        _ => null,
      };

  /// All six three-band tests recorded?
  bool get allMovementTestsComplete =>
      backScratch != null &&
      sitAndReach != null &&
      armCurl != null &&
      chairStand != null &&
      stepTest != null &&
      tug != null;

  /// Next incomplete movement-test id (administration order), or null if done.
  String? get nextIncompleteTestId {
    if (backScratch == null) return 'back_scratch';
    if (sitAndReach == null) return 'sit_reach';
    if (armCurl == null) return 'arm_curl';
    if (chairStand == null) return 'chair_stand';
    if (stepTest == null) return 'step_test';
    if (tug == null) return 'tug';
    return null;
  }

  AssessmentSession copyWith({
    PersonInfo? person,
    MeasurementResult? height,
    MeasurementResult? weight,
    BmiResult? bmi,
    BestOfTwoResult? backScratch,
    BestOfTwoResult? sitAndReach,
    RepCountResult? armCurl,
    RepCountResult? chairStand,
    RepCountResult? stepTest,
    TimedResult? tug,
  }) =>
      AssessmentSession(
        person: person ?? this.person,
        height: height ?? this.height,
        weight: weight ?? this.weight,
        bmi: bmi ?? this.bmi,
        backScratch: backScratch ?? this.backScratch,
        sitAndReach: sitAndReach ?? this.sitAndReach,
        armCurl: armCurl ?? this.armCurl,
        chairStand: chairStand ?? this.chairStand,
        stepTest: stepTest ?? this.stepTest,
        tug: tug ?? this.tug,
      );
}

class AssessmentSessionNotifier extends Notifier<AssessmentSession> {
  @override
  AssessmentSession build() => AssessmentSession.empty;

  void setPerson(PersonInfo p) => state = state.copyWith(person: p);
  void setHeight(MeasurementResult h) => state = state.copyWith(height: h);
  void setWeight(MeasurementResult w) => state = state.copyWith(weight: w);
  void setBmi(BmiResult b) => state = state.copyWith(bmi: b);
  void setBackScratch(BestOfTwoResult r) =>
      state = state.copyWith(backScratch: r);
  void setSitAndReach(BestOfTwoResult r) =>
      state = state.copyWith(sitAndReach: r);
  void setArmCurl(RepCountResult r) => state = state.copyWith(armCurl: r);
  void setChairStand(RepCountResult r) => state = state.copyWith(chairStand: r);
  void setStepTest(RepCountResult r) => state = state.copyWith(stepTest: r);
  void setTug(TimedResult r) => state = state.copyWith(tug: r);

  /// Store a movement-test result by id (used by the generic per-test flow).
  void setMovementResult(String testId, Object result) {
    switch (testId) {
      case 'back_scratch':
        setBackScratch(result as BestOfTwoResult);
      case 'sit_reach':
        setSitAndReach(result as BestOfTwoResult);
      case 'arm_curl':
        setArmCurl(result as RepCountResult);
      case 'chair_stand':
        setChairStand(result as RepCountResult);
      case 'step_test':
        setStepTest(result as RepCountResult);
      case 'tug':
        setTug(result as TimedResult);
    }
  }

  void reset() => state = AssessmentSession.empty;
}

final assessmentSessionProvider =
    NotifierProvider<AssessmentSessionNotifier, AssessmentSession>(
  AssessmentSessionNotifier.new,
);
