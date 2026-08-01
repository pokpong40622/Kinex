import 'package:flutter_test/flutter_test.dart';
import 'package:kinex_app/models/fall_risk.dart';
import 'package:kinex_app/services/sppb_scoring.dart';

void main() {
  group('balance stances', () {
    test('side-by-side: ≥10s → 1, else 0', () {
      expect(SppbScoring.sideBySidePoints(10.0), 1);
      expect(SppbScoring.sideBySidePoints(9.99), 0);
      expect(SppbScoring.sideBySidePoints(0), 0);
    });
    test('semi-tandem: ≥10s → 1, else 0', () {
      expect(SppbScoring.semiTandemPoints(10.0), 1);
      expect(SppbScoring.semiTandemPoints(9.99), 0);
    });
    test('tandem: ≥10 → 2 · 3–9.99 → 1 · <3 → 0', () {
      expect(SppbScoring.tandemPoints(10.0), 2);
      expect(SppbScoring.tandemPoints(9.99), 1);
      expect(SppbScoring.tandemPoints(3.0), 1);
      expect(SppbScoring.tandemPoints(2.99), 0);
    });
    test('balanceTotal sums stances (gated stances stored as 0s)', () {
      // full pass
      expect(
          SppbScoring.balanceTotal(
              sideBySideSec: 10, semiTandemSec: 10, tandemSec: 10),
          4);
      // failed side-by-side → the rest are recorded as 0s → total 0
      expect(
          SppbScoring.balanceTotal(
              sideBySideSec: 5, semiTandemSec: 0, tandemSec: 0),
          0);
      // pass first two, tandem 3–9.99 → 1+1+1 = 3
      expect(
          SppbScoring.balanceTotal(
              sideBySideSec: 10, semiTandemSec: 10, tandemSec: 5),
          3);
    });
  });

  group('gait points — 4m walk (lower is better)', () {
    test('boundaries', () {
      expect(SppbScoring.gaitPoints(4.81), 4);
      expect(SppbScoring.gaitPoints(4.82), 3); // 4.82–6.20 → 3
      expect(SppbScoring.gaitPoints(6.20), 3);
      expect(SppbScoring.gaitPoints(6.21), 2); // 6.21–8.70 → 2
      expect(SppbScoring.gaitPoints(8.70), 2);
      expect(SppbScoring.gaitPoints(8.71), 1); // >8.70 → 1
      expect(SppbScoring.gaitPoints(20.0), 1);
    });
    test('unable → 0', () {
      expect(SppbScoring.gaitPoints(3.0, unable: true), 0);
    });
  });

  group('chair-stand points — time for 5 rises (lower is better)', () {
    test('boundaries', () {
      expect(SppbScoring.chairStandPoints(11.19, preTestPassed: true), 4);
      expect(SppbScoring.chairStandPoints(11.20, preTestPassed: true), 3);
      expect(SppbScoring.chairStandPoints(13.69, preTestPassed: true), 3);
      expect(SppbScoring.chairStandPoints(13.70, preTestPassed: true), 2);
      expect(SppbScoring.chairStandPoints(16.69, preTestPassed: true), 2);
      expect(SppbScoring.chairStandPoints(16.70, preTestPassed: true), 1);
      expect(SppbScoring.chairStandPoints(60.0, preTestPassed: true), 1);
      expect(SppbScoring.chairStandPoints(60.01, preTestPassed: true), 0);
    });
    test('pre-test failed → 0 regardless of time', () {
      expect(SppbScoring.chairStandPoints(5.0, preTestPassed: false), 0);
    });
  });

  group('total → fall-risk band', () {
    test('total sums the three domains', () {
      expect(SppbScoring.total(balance: 4, gait: 4, chairStand: 4), 12);
      expect(SppbScoring.total(balance: 1, gait: 2, chairStand: 3), 6);
    });
    test('band cuts: 0–6 High · 7–9 Moderate · 10–12 Low', () {
      expect(SppbScoring.riskBand(0), FallRisk.high);
      expect(SppbScoring.riskBand(6), FallRisk.high);
      expect(SppbScoring.riskBand(7), FallRisk.moderate);
      expect(SppbScoring.riskBand(9), FallRisk.moderate);
      expect(SppbScoring.riskBand(10), FallRisk.low);
      expect(SppbScoring.riskBand(12), FallRisk.low);
    });
  });

  group('FallRisk token round-trip', () {
    test('tokens round-trip', () {
      for (final r in FallRisk.values) {
        expect(FallRisk.fromToken(r.token), r);
      }
    });
  });
}
