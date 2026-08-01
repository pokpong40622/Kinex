/// Which leg a reading belongs to. Pads sit at the same position on both legs,
/// so every muscle is measured once per side.
enum LegSide {
  left('ซ้าย', 'L'),
  right('ขวา', 'R');

  final String thaiName;
  final String code;
  const LegSide(this.thaiName, this.code);
}

/// The two leg joints Kinex assesses for balance (การทรงตัว). Each is driven by
/// an antagonist muscle pair the EMG hardware measures.
enum BalanceJoint {
  knee('การทรงตัวของข้อเข่า', 'Knee'),
  ankle('การทรงตัวของข้อเท้า', 'Ankle');

  final String thaiName;
  final String englishName;
  const BalanceJoint(this.thaiName, this.englishName);
}

/// The four leg muscles the Kinex EMG pads read. Grouped into two antagonist
/// pairs (one per [BalanceJoint]): the agonist extends/dorsiflexes, the
/// antagonist flexes/plantarflexes.
enum Muscle {
  vl('VL', 'Vastus Lateralis', 'ต้นขาด้านนอก', BalanceJoint.knee, true),
  bf('BF', 'Biceps Femoris', 'ต้นขาด้านหลัง', BalanceJoint.knee, false),
  ta('TA', 'Tibialis Anterior', 'หน้าแข้ง', BalanceJoint.ankle, true),
  gcm('GCM', 'Gastrocnemius', 'น่อง', BalanceJoint.ankle, false);

  /// Short pad label shown in the hardware guide / advanced view.
  final String code;
  /// Anatomical name (advanced view).
  final String latinName;
  /// Friendly Thai name (normal view / instructions).
  final String thaiName;
  /// Which joint this muscle acts on.
  final BalanceJoint joint;
  /// Agonist (extensor/dorsiflexor) vs antagonist (flexor/plantarflexor).
  final bool isAgonist;

  const Muscle(
      this.code, this.latinName, this.thaiName, this.joint, this.isAgonist);

  /// Muscles acting on [j], agonist first.
  static List<Muscle> forJoint(BalanceJoint j) =>
      Muscle.values.where((m) => m.joint == j).toList()
        ..sort((a, b) => (b.isAgonist ? 1 : 0) - (a.isAgonist ? 1 : 0));

  static Muscle? byCode(String code) {
    for (final m in Muscle.values) {
      if (m.code == code) return m;
    }
    return null;
  }
}
