/// Fall-risk classification for the SPPB (Short Physical Performance Battery).
///
/// The SPPB sums three 0–4 domain scores (balance + gait speed + chair stand)
/// into a 0–12 total; the total maps to one of three fall-risk bands. Labels are
/// the Thai categories from the reference slide "การแปลผลคะแนนและความเสี่ยงในการหกล้ม".
///
/// Kept free of Flutter imports so the scoring engine and models stay pure and
/// trivially unit-testable. Colours live with the widgets that render these.
library;

enum FallRisk {
  high, //     ความเสี่ยงสูงมาก — total 0–6
  moderate, // ความเสี่ยงปานกลาง — total 7–9
  low; //      ความเสี่ยงต่ำ    — total 10–12

  /// Short Thai label (e.g. for a badge/pill).
  String get thaiLabel => switch (this) {
        FallRisk.high => 'ความเสี่ยงสูงมาก',
        FallRisk.moderate => 'ความเสี่ยงปานกลาง',
        FallRisk.low => 'ความเสี่ยงต่ำ',
      };

  /// Compact Thai label for small pills (history list, home).
  String get thaiShort => switch (this) {
        FallRisk.high => 'เสี่ยงสูง',
        FallRisk.moderate => 'เสี่ยงปานกลาง',
        FallRisk.low => 'เสี่ยงต่ำ',
      };

  /// The 0–12 score range for this band, as shown on the interpretation cards.
  String get scoreRange => switch (this) {
        FallRisk.high => '0 – 6',
        FallRisk.moderate => '7 – 9',
        FallRisk.low => '10 – 12',
      };

  /// English label shown alongside the Thai (matches the slide).
  String get englishLabel => switch (this) {
        FallRisk.high => 'High Risk',
        FallRisk.moderate => 'Moderate Risk',
        FallRisk.low => 'Low Risk',
      };

  /// One-line plain-language meaning (from the slide).
  String get thaiDescription => switch (this) {
        FallRisk.high => 'มีความเสี่ยงในการเกิดการหกล้มซ้ำ ๆ สูง',
        FallRisk.moderate =>
          'เริ่มมีความบกพร่องทางกายภาพระดับปานกลาง เริ่มมีความเสี่ยงต่อการหกล้มซ้ำที่สูงขึ้น',
        FallRisk.low => 'สมรรถภาพทางกายอยู่ในเกณฑ์ดี ความเสี่ยงต่อการหกล้มต่ำ',
      };

  /// Stable token for JSON round-tripping.
  String get token => name;

  static FallRisk fromToken(String token) =>
      FallRisk.values.firstWhere((r) => r.name == token);
}
