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

  group('BmiBand token round-trip', () {
    test('BmiBand tokens round-trip', () {
      for (final b in BmiBand.values) {
        expect(BmiBand.fromToken(b.token), b);
      }
    });
  });
}
