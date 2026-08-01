import '../models/fall_risk.dart';

/// Pure scoring engine for the SPPB (Short Physical Performance Battery) fall-risk
/// assessment.
///
/// This file is the SINGLE SOURCE OF TRUTH for every SPPB threshold. All values
/// come from the reference slides (Balance / Gait Speed / Chair Stand + risk
/// interpretation). Do not duplicate these numbers anywhere else (UI, pages).
///
/// Each of the three domains scores 0–4; the total (0–12) maps to a [FallRisk]
/// band. No Flutter imports — trivially unit-testable.
class SppbScoring {
  SppbScoring._();

  // ---------------------------------------------------------------------------
  // Balance (0–4) — three stances, each held (target 10 s). Gating is handled by
  // the page: a failed stance records 0 seconds for the stances that follow, so
  // simple summation reproduces the flowchart's "skip → 0" behaviour.
  // ---------------------------------------------------------------------------

  /// Side-by-side stand: held ≥10 s → 1, else 0.
  static int sideBySidePoints(double seconds) => seconds >= 10.0 ? 1 : 0;

  /// Semi-tandem stand: held ≥10 s → +1, else +0.
  static int semiTandemPoints(double seconds) => seconds >= 10.0 ? 1 : 0;

  /// Tandem stand: ≥10 s → +2 · 3–9.99 s → +1 · <3 s → +0.
  static int tandemPoints(double seconds) {
    if (seconds >= 10.0) return 2;
    if (seconds >= 3.0) return 1;
    return 0;
  }

  /// Balance domain total (0–4).
  static int balanceTotal({
    required double sideBySideSec,
    required double semiTandemSec,
    required double tandemSec,
  }) =>
      sideBySidePoints(sideBySideSec) +
      semiTandemPoints(semiTandemSec) +
      tandemPoints(tandemSec);

  // ---------------------------------------------------------------------------
  // Gait speed (0–4) — time to walk 4 m at normal pace (best of two).
  //   <4.82 s → 4 · 4.82–6.20 → 3 · 6.21–8.70 → 2 · >8.70 → 1 · Unable → 0
  // ---------------------------------------------------------------------------

  static int gaitPoints(double seconds, {bool unable = false}) {
    if (unable) return 0;
    if (seconds < 4.82) return 4;
    if (seconds <= 6.20) return 3;
    if (seconds <= 8.70) return 2;
    return 1;
  }

  // ---------------------------------------------------------------------------
  // Chair stand (0–4) — time to complete five rises without using the arms.
  //   pre-test unable → 0 (skip) · ≤11.19 s → 4 · 11.20–13.69 → 3 ·
  //   13.70–16.69 → 2 · >16.7 s → 1 · >60 s or unable → 0
  // ---------------------------------------------------------------------------

  static int chairStandPoints(double seconds, {required bool preTestPassed}) {
    if (!preTestPassed) return 0;
    if (seconds > 60.0) return 0;
    if (seconds <= 11.19) return 4;
    if (seconds <= 13.69) return 3;
    if (seconds <= 16.69) return 2;
    return 1;
  }

  // ---------------------------------------------------------------------------
  // Total (0–12) → fall-risk band
  //   0–6 → High · 7–9 → Moderate · 10–12 → Low
  // ---------------------------------------------------------------------------

  static int total({
    required int balance,
    required int gait,
    required int chairStand,
  }) =>
      balance + gait + chairStand;

  /// Map a 0–12 total to its fall-risk band. Uses the standard SPPB cut
  /// (0–6 = High); the slide prints "< 6" for High but leaves 6 undefined, so 6
  /// is bucketed as High here.
  static FallRisk riskBand(int total) {
    if (total <= 6) return FallRisk.high;
    if (total <= 9) return FallRisk.moderate;
    return FallRisk.low;
  }
}
