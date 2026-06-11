import 'package:flutter_test/flutter_test.dart';
import 'package:kinex_app/models/fitness_level.dart';
import 'package:kinex_app/services/fitness_scoring.dart';

void main() {
  group('computeBmi', () {
    test('weight 70kg / height 1.75m → 22.8 (manual example p.17)', () {
      final bmi = FitnessScoring.computeBmi(weightKg: 70, heightMeters: 1.75);
      expect(bmi, closeTo(22.86, 0.01));
    });

    test('throws on non-positive height', () {
      expect(() => FitnessScoring.computeBmi(weightKg: 60, heightMeters: 0),
          throwsArgumentError);
    });
  });

  group('bmiBand — every boundary', () {
    test('< 18.5 → ผอม', () {
      expect(FitnessScoring.bmiBand(18.49), BmiBand.phom);
      expect(FitnessScoring.bmiBand(10.0), BmiBand.phom);
    });
    test('18.5–22.9 → น้ำหนักปกติ (lower & upper edges)', () {
      expect(FitnessScoring.bmiBand(18.5), BmiBand.pokati);
      expect(FitnessScoring.bmiBand(22.9), BmiBand.pokati);
      expect(FitnessScoring.bmiBand(22.99), BmiBand.pokati);
    });
    test('23.0–24.9 → น้ำหนักเกิน', () {
      expect(FitnessScoring.bmiBand(23.0), BmiBand.namnakKoen);
      expect(FitnessScoring.bmiBand(24.99), BmiBand.namnakKoen);
    });
    test('25.0–29.9 → โรคอ้วน', () {
      expect(FitnessScoring.bmiBand(25.0), BmiBand.rokOuan);
      expect(FitnessScoring.bmiBand(29.99), BmiBand.rokOuan);
    });
    test('>= 30.0 → โรคอ้วนอันตราย', () {
      expect(FitnessScoring.bmiBand(30.0), BmiBand.rokOuanAntaray);
      expect(FitnessScoring.bmiBand(45.0), BmiBand.rokOuanAntaray);
    });
  });

  group('armCurlLevel — threshold 11', () {
    test('> 11 → ดีมาก', () => expect(FitnessScoring.armCurlLevel(12), FitnessLevel.dimak));
    test('== 11 → ดี', () => expect(FitnessScoring.armCurlLevel(11), FitnessLevel.di));
    test('< 11 → เสี่ยง', () => expect(FitnessScoring.armCurlLevel(10), FitnessLevel.siang));
  });

  group('chairStandLevel — threshold 8', () {
    test('> 8 → ดีมาก', () => expect(FitnessScoring.chairStandLevel(9), FitnessLevel.dimak));
    test('== 8 → ดี', () => expect(FitnessScoring.chairStandLevel(8), FitnessLevel.di));
    test('< 8 → เสี่ยง', () => expect(FitnessScoring.chairStandLevel(7), FitnessLevel.siang));
  });

  group('stepLevel — threshold 65', () {
    test('> 65 → ดีมาก', () => expect(FitnessScoring.stepLevel(66), FitnessLevel.dimak));
    test('== 65 → ดี', () => expect(FitnessScoring.stepLevel(65), FitnessLevel.di));
    test('< 65 → เสี่ยง', () => expect(FitnessScoring.stepLevel(64), FitnessLevel.siang));
  });

  group('tugLevel — threshold 12s (low is good)', () {
    test('< 12 → ดีมาก', () => expect(FitnessScoring.tugLevel(11.9), FitnessLevel.dimak));
    test('== 12 → ดี', () => expect(FitnessScoring.tugLevel(12.0), FitnessLevel.di));
    test('> 12 → เสี่ยง', () => expect(FitnessScoring.tugLevel(12.1), FitnessLevel.siang));
  });

  group('computeOverall — Kinex product rule (6 three-band tests)', () {
    FitnessLevel overall(List<FitnessLevel> l) => FitnessScoring.computeOverall(l);

    test('any เสี่ยง → เสี่ยง', () {
      expect(
        overall([
          FitnessLevel.dimak,
          FitnessLevel.dimak,
          FitnessLevel.di,
          FitnessLevel.dimak,
          FitnessLevel.siang, // one risk drags it down
          FitnessLevel.di,
        ]),
        FitnessLevel.siang,
      );
    });

    test('all ดีมาก → ดีมาก', () {
      expect(
        overall(List.filled(6, FitnessLevel.dimak)),
        FitnessLevel.dimak,
      );
    });

    test('mix of ดีมาก/ดี (no เสี่ยง) → ดี', () {
      expect(
        overall([
          FitnessLevel.dimak,
          FitnessLevel.di,
          FitnessLevel.dimak,
          FitnessLevel.dimak,
          FitnessLevel.di,
          FitnessLevel.dimak,
        ]),
        FitnessLevel.di,
      );
    });

    test('all ดี → ดี', () {
      expect(overall(List.filled(6, FitnessLevel.di)), FitnessLevel.di);
    });

    test('empty list throws', () {
      expect(() => overall([]), throwsArgumentError);
    });
  });

  group('FitnessLevel / BmiBand token round-trip', () {
    test('FitnessLevel tokens round-trip', () {
      for (final l in FitnessLevel.values) {
        expect(FitnessLevel.fromToken(l.token), l);
      }
    });
    test('BmiBand tokens round-trip', () {
      for (final b in BmiBand.values) {
        expect(BmiBand.fromToken(b.token), b);
      }
    });
  });
}
