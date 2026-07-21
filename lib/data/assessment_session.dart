import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/emg_metrics.dart';
import '../models/person_info.dart';
import '../models/test_results.dart';
import '../state/assessment_profile.dart';

/// In-progress assessment, carried across all screens. In-memory only (a
/// Riverpod Notifier) — loss on OS process death is an accepted v1 limitation.
@immutable
class AssessmentSession {
  final PersonInfo? person;
  final MeasurementResult? height;
  final MeasurementResult? weight;
  final BmiResult? bmi;
  final BalanceResult? balance;
  final GaitResult? gait;
  final ChairStandResult? chairStand;
  final MvcCalibration? mvcCalibration;

  const AssessmentSession({
    this.person,
    this.height,
    this.weight,
    this.bmi,
    this.balance,
    this.gait,
    this.chairStand,
    this.mvcCalibration,
  });

  static const empty = AssessmentSession();

  /// Result for a movement-test id, or null if not done yet.
  Object? resultFor(String testId) => switch (testId) {
        'balance' => balance,
        'gait_speed' => gait,
        'chair_stand' => chairStand,
        _ => null,
      };

  /// All three SPPB tests recorded?
  bool get allMovementTestsComplete =>
      balance != null && gait != null && chairStand != null;

  /// Next incomplete movement-test id (administration order), or null if done.
  String? get nextIncompleteTestId {
    if (balance == null) return 'balance';
    if (gait == null) return 'gait_speed';
    if (chairStand == null) return 'chair_stand';
    return null;
  }

  AssessmentSession copyWith({
    PersonInfo? person,
    MeasurementResult? height,
    MeasurementResult? weight,
    BmiResult? bmi,
    BalanceResult? balance,
    GaitResult? gait,
    ChairStandResult? chairStand,
    MvcCalibration? mvcCalibration,
  }) =>
      AssessmentSession(
        person: person ?? this.person,
        height: height ?? this.height,
        weight: weight ?? this.weight,
        bmi: bmi ?? this.bmi,
        balance: balance ?? this.balance,
        gait: gait ?? this.gait,
        chairStand: chairStand ?? this.chairStand,
        mvcCalibration: mvcCalibration ?? this.mvcCalibration,
      );
}

class AssessmentSessionNotifier extends Notifier<AssessmentSession> {
  @override
  AssessmentSession build() => AssessmentSession.empty;

  void setPerson(PersonInfo p) => state = state.copyWith(person: p);
  void setHeight(MeasurementResult h) => state = state.copyWith(height: h);
  void setWeight(MeasurementResult w) => state = state.copyWith(weight: w);
  void setBmi(BmiResult b) => state = state.copyWith(bmi: b);
  void setBalance(BalanceResult r) => state = state.copyWith(balance: r);
  void setGait(GaitResult r) => state = state.copyWith(gait: r);
  void setChairStand(ChairStandResult r) =>
      state = state.copyWith(chairStand: r);
  void setMvcCalibration(MvcCalibration c) =>
      state = state.copyWith(mvcCalibration: c);

  /// Prefill a fresh session from the last saved profile so a returning user
  /// doesn't re-enter name/age/gender/height/weight. Only fills what's present.
  void seedFrom(SavedProfile p) {
    var s = state;
    if (p.age != null && p.gender != null) {
      s = s.copyWith(
          person: PersonInfo(name: p.name, age: p.age!, gender: p.gender!));
    }
    if (p.heightCm != null) {
      s = s.copyWith(height: MeasurementResult(p.heightCm!, 'cm'));
    }
    if (p.weightKg != null) {
      s = s.copyWith(weight: MeasurementResult(p.weightKg!, 'kg'));
    }
    state = s;
  }

  void reset() => state = AssessmentSession.empty;
}

final assessmentSessionProvider =
    NotifierProvider<AssessmentSessionNotifier, AssessmentSession>(
  AssessmentSessionNotifier.new,
);
