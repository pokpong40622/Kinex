/// Classification enums for the elderly physical-fitness assessment.
///
/// Labels are the official Thai categories from the assessment manual
/// "การประเมินสมรรถภาพทางกายในผู้สูงอายุ". Kept free of Flutter imports so the
/// scoring engine and models stay pure and trivially unit-testable. Display
/// concerns (colors) live with the widgets that render these.
library;

/// Three-band fitness classification used by the six movement/flexibility tests.
enum FitnessLevel {
  dimak, // ดีมาก  — very good
  di, //    ดี     — good
  siang; // เสี่ยง — at risk

  String get thaiLabel => switch (this) {
        FitnessLevel.dimak => 'ดีมาก',
        FitnessLevel.di => 'ดี',
        FitnessLevel.siang => 'เสี่ยง',
      };

  /// Stable token for JSON round-tripping.
  String get token => name;

  static FitnessLevel fromToken(String token) =>
      FitnessLevel.values.firstWhere((l) => l.name == token);
}

/// BMI classification — five bands, per the manual (page 17).
/// NOTE: this is its own scale, NOT the three-band [FitnessLevel].
enum BmiBand {
  phom, //           ผอม           — underweight     (< 18.5)
  pokati, //         น้ำหนักปกติ    — normal          (18.5–22.9)
  namnakKoen, //     น้ำหนักเกิน    — overweight      (23.0–24.9)
  rokOuan, //        โรคอ้วน        — obese           (25.0–29.9)
  rokOuanAntaray; // โรคอ้วนอันตราย — dangerous obese (>= 30.0)

  String get thaiLabel => switch (this) {
        BmiBand.phom => 'ผอม',
        BmiBand.pokati => 'น้ำหนักปกติ',
        BmiBand.namnakKoen => 'น้ำหนักเกิน',
        BmiBand.rokOuan => 'โรคอ้วน',
        BmiBand.rokOuanAntaray => 'โรคอ้วนอันตราย',
      };

  String get token => name;

  static BmiBand fromToken(String token) =>
      BmiBand.values.firstWhere((b) => b.name == token);
}
