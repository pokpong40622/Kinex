import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Static content for the "เรียนรู้ท่าฝึก" (Learn the exercises) feature.
///
/// Nine senior rehab poses taken from the Kinex physiotherapy booklet:
/// four muscle strength/endurance poses and five balance poses. Pure data —
/// no widgets — so the library and detail screens stay simple and testable.
///
/// The Thai text is transcribed faithfully from the source booklet. Where the
/// booklet gives no rep count (hip abduction/extension), the numbers are shown
/// as gentle guidelines with a "follow your therapist" caution.

enum PoseCategory { strength, balance }

extension PoseCategoryMeta on PoseCategory {
  String get thaiTitle => switch (this) {
        PoseCategory.strength => 'ท่าฝึกความแข็งแรงของกล้ามเนื้อ',
        PoseCategory.balance => 'ท่าฝึกการทรงตัว',
      };

  String get thaiShort => switch (this) {
        PoseCategory.strength => 'ความแข็งแรง',
        PoseCategory.balance => 'การทรงตัว',
      };

  IconData get icon => switch (this) {
        PoseCategory.strength => Icons.fitness_center_rounded,
        PoseCategory.balance => Icons.self_improvement_rounded,
      };

  /// Accent colour for cards/hero of this category.
  Color get color => switch (this) {
        PoseCategory.strength => KColors.deepPurple,
        PoseCategory.balance => KColors.teal,
      };

  Gradient get gradient => switch (this) {
        PoseCategory.strength => LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [KColors.purple, KColors.deepPurple]),
        PoseCategory.balance => KColors.tealGradient,
      };
}

/// One quick-fact chip on a pose (reps / sets / rest / hold …).
class PoseFact {
  final IconData icon;
  final String label;
  const PoseFact(this.icon, this.label);
}

/// One learnable pose.
class LearnPose {
  final String id;
  final String name; // Thai display title
  final String subtitle; // one-line "what/why"
  final PoseCategory category;
  final String target; // muscle group / ability trained
  final IconData icon;
  final String? image; // booklet photo asset (assets/images/learn/<id>.jpg)
  final List<PoseFact> facts; // quick chips (dose)
  final List<String> steps; // numbered how-to
  final List<String> tips; // optional coaching pointers
  final String? breathing; // breathing cue
  final String? caution; // safety note

  const LearnPose({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.category,
    required this.target,
    required this.icon,
    this.image,
    required this.facts,
    required this.steps,
    this.tips = const [],
    this.breathing,
    this.caution,
  });
}

/// Lookup by id (used by the detail route).
LearnPose? poseById(String id) {
  for (final p in poseLibrary) {
    if (p.id == id) return p;
  }
  return null;
}

List<LearnPose> posesIn(PoseCategory c) =>
    poseLibrary.where((p) => p.category == c).toList();

/// The full ordered library — 4 strength, then 5 balance.
const List<LearnPose> poseLibrary = [
  // ── STRENGTH ───────────────────────────────────────────────────────────────
  LearnPose(
    id: 'sit_to_stand',
    name: 'ลุกยืนจากเก้าอี้',
    subtitle: 'เสริมแรงต้นขาด้วยการลุก–นั่ง',
    category: PoseCategory.strength,
    target: 'กล้ามเนื้อต้นขาด้านหน้า',
    icon: Icons.chair_rounded,
    image: 'assets/images/learn/sit_to_stand.jpg',
    facts: [
      PoseFact(Icons.repeat_rounded, '15 ครั้ง = 1 เซต'),
      PoseFact(Icons.layers_rounded, '3 เซต'),
      PoseFact(Icons.timer_outlined, 'พักระหว่างเซต 1 นาที'),
    ],
    steps: [
      'นั่งบนเก้าอี้ เอามือทั้งสองข้างประสานไว้บริเวณหน้าอก',
      'ออกแรงลุกขึ้นยืนให้ลำตัวตรง',
      'ค่อย ๆ นั่งลงบนเก้าอี้อย่างควบคุม',
      'ทำซ้ำ โดยระวังไม่ให้เข่าเลยปลายเท้าทั้งสองข้าง',
    ],
    breathing: 'หายใจออกขณะออกแรงลุกขึ้น หายใจเข้าขณะผ่อนแรงนั่งลง',
    caution: 'ใช้เก้าอี้ที่มั่นคง ไม่มีล้อ และมีคนอยู่ใกล้ ๆ',
  ),
  LearnPose(
    id: 'seated_knee_lift',
    name: 'ยกขาสลับ (ท่านั่ง)',
    subtitle: 'บริหารต้นขาด้วยการยกเข่าจากท่านั่ง',
    category: PoseCategory.strength,
    target: 'กล้ามเนื้อต้นขาด้านหน้า',
    icon: Icons.airline_seat_recline_extra_rounded,
    image: 'assets/images/learn/seated_knee_lift.jpg',
    facts: [
      PoseFact(Icons.repeat_rounded, 'สลับซ้าย–ขวา 20 ครั้ง = 1 เซต'),
      PoseFact(Icons.layers_rounded, '3 เซต'),
      PoseFact(Icons.timer_outlined, 'พักระหว่างเซต 1 นาที'),
    ],
    steps: [
      'นั่งบนเก้าอี้ มือทั้งสองข้างจับขอบเก้าอี้ไว้',
      'ออกแรงยกขาขึ้นมาให้พ้นพื้น',
      'วางขาลง แล้วสลับทำอีกข้าง',
    ],
    breathing: 'หายใจออกขณะออกแรง หายใจเข้าขณะผ่อนแรง',
    caution: 'ใช้เก้าอี้ที่มั่นคง ไม่มีล้อ',
  ),
  LearnPose(
    id: 'hip_abduction',
    name: 'กางสะโพกออกด้านข้าง (ท่ายืน)',
    subtitle: 'เสริมกล้ามเนื้อสะโพกด้านข้าง ช่วยการทรงตัว',
    category: PoseCategory.strength,
    target: 'กล้ามเนื้อกางสะโพก',
    icon: Icons.accessibility_new_rounded,
    image: 'assets/images/learn/hip_abduction.jpg',
    facts: [
      PoseFact(Icons.slow_motion_video_rounded, 'ทำช้า ๆ ควบคุม'),
      PoseFact(Icons.repeat_rounded, '10–15 ครั้ง/ข้าง'),
      PoseFact(Icons.layers_rounded, '2–3 เซต'),
    ],
    steps: [
      'ยืนตรง จับราวหรือพนักเก้าอี้ที่มั่นคงไว้',
      'กางขาออกไปด้านข้างช้า ๆ โดยให้ลำตัวตั้งตรง',
      'ค่อย ๆ เอาขากลับสู่ท่าเริ่ม แล้วสลับข้าง',
    ],
    tips: [
      'เพิ่มความหนักได้โดยใส่ตุ้มน้ำหนักที่ข้อเท้า (แบบมีแรงต้าน)',
    ],
    caution: 'ปรับจำนวนครั้งและน้ำหนักตามคำแนะนำของนักกายภาพบำบัด',
  ),
  LearnPose(
    id: 'hip_extension',
    name: 'เหยียดสะโพกไปด้านหลัง (ท่ายืน)',
    subtitle: 'เสริมกล้ามเนื้อสะโพกด้านหลังและก้น',
    category: PoseCategory.strength,
    target: 'กล้ามเนื้อเหยียดสะโพก',
    icon: Icons.directions_run_rounded,
    image: 'assets/images/learn/hip_extension.jpg',
    facts: [
      PoseFact(Icons.slow_motion_video_rounded, 'ทำช้า ๆ ควบคุม'),
      PoseFact(Icons.repeat_rounded, '10–15 ครั้ง/ข้าง'),
      PoseFact(Icons.layers_rounded, '2–3 เซต'),
    ],
    steps: [
      'ยืนตรง จับราวหรือพนักเก้าอี้ที่มั่นคงไว้',
      'เหยียดขาไปด้านหลังช้า ๆ โดยลำตัวตั้งตรง ไม่แอ่นหลัง',
      'ค่อย ๆ เอาขากลับสู่ท่าเริ่ม แล้วสลับข้าง',
    ],
    tips: [
      'เพิ่มความหนักได้โดยใส่ตุ้มน้ำหนักที่ข้อเท้า (แบบมีแรงต้าน)',
    ],
    caution: 'ปรับจำนวนครั้งและน้ำหนักตามคำแนะนำของนักกายภาพบำบัด',
  ),

  // ── BALANCE ────────────────────────────────────────────────────────────────
  LearnPose(
    id: 'narrow_base_stand',
    name: 'ยืนฐานแคบ (ส้นเท้า–เขย่งปลายเท้า)',
    subtitle: 'ฝึกทรงตัวบนฐานแคบด้วยส้นเท้าและปลายเท้า',
    category: PoseCategory.balance,
    target: 'การทรงตัว',
    icon: Icons.straighten_rounded,
    image: 'assets/images/learn/narrow_base_stand.jpg',
    facts: [
      PoseFact(Icons.vertical_align_bottom_rounded, 'ยืนลงน้ำหนักบนส้นเท้า'),
      PoseFact(Icons.vertical_align_top_rounded, 'ยืนเขย่งปลายเท้า'),
      PoseFact(Icons.timer_outlined, 'ค้างเท่าที่ทรงตัวได้'),
    ],
    steps: [
      'ยืนบนฐานแคบ ฝึกยืนลงน้ำหนักบนส้นเท้า',
      'จากนั้นฝึกยืนเขย่งขึ้นบนปลายเท้า',
      'ระยะแรกใช้มือช่วยประคอง เมื่อทำได้ดีขึ้นค่อย ๆ ลดการประคองลง',
    ],
    tips: [
      'หากยังปล่อยมือไม่ได้ ให้ใช้มือช่วยประคองน้อยที่สุดเท่าที่จะทรงตัวได้',
    ],
    caution: 'ยืนใกล้ราวจับหรือผนัง เพื่อจับได้ทันหากเสียการทรงตัว',
  ),
  LearnPose(
    id: 'tandem_stand',
    name: 'ยืนต่อเท้า',
    subtitle: 'ฝึกทรงตัวโดยวางเท้าต่อกันเป็นเส้นตรง',
    category: PoseCategory.balance,
    target: 'การทรงตัว',
    icon: Icons.timeline_rounded,
    image: 'assets/images/learn/tandem_stand.jpg',
    facts: [
      PoseFact(Icons.straighten_rounded, 'วางเท้าต่อกันเต็มฝ่าเท้า'),
      PoseFact(Icons.crop_portrait_rounded, 'ฐานแคบ'),
      PoseFact(Icons.timer_outlined, 'ค้างเท่าที่ทรงตัวได้'),
    ],
    steps: [
      'ยืนฐานแคบ วางเท้าหนึ่งไว้ข้างหน้าต่อกับอีกเท้าเต็มฝ่าเท้า',
      'พยายามทรงตัวให้นิ่ง',
      'ระยะแรกใช้มือช่วยประคอง เมื่อทำได้ดีขึ้นค่อย ๆ ลดการประคองลง',
    ],
    caution: 'ยืนใกล้ราวจับหรือผนัง เพื่อจับได้ทันหากเสียการทรงตัว',
  ),
  LearnPose(
    id: 'single_leg_balance',
    name: 'ยืนทรงตัวขาเดียว',
    subtitle: 'ยืนขาเดียว พร้อมปรับท่าแขน 3 ระดับ',
    category: PoseCategory.balance,
    target: 'การทรงตัว',
    icon: Icons.self_improvement_rounded,
    image: 'assets/images/learn/single_leg_balance.jpg',
    facts: [
      PoseFact(Icons.timer_rounded, 'ค้างไว้ 10 วินาที'),
      PoseFact(Icons.swap_horiz_rounded, 'สลับข้าง'),
      PoseFact(Icons.air_rounded, 'ไม่กลั้นหายใจ'),
    ],
    steps: [
      'ระดับ 1: งอขาซ้ายขึ้น กางแขนให้ขนานกับพื้น คงค้างไว้ 10 วินาที แล้วสลับข้าง',
      'ระดับ 2: งอขาขึ้น เอามือวางซ้อนกันไว้บริเวณหน้าอก คงค้างไว้ 10 วินาที สลับข้าง',
      'ระดับ 3: งอขาขึ้น เอามือประสานไว้ที่หน้าอก คงค้างไว้ 10 วินาที สลับข้าง',
    ],
    tips: [
      'เริ่มจากระดับ 1 ก่อน เมื่อทรงตัวได้มั่นคงจึงเลื่อนไประดับที่ยากขึ้น',
    ],
    breathing: 'ไม่กลั้นหายใจขณะปฏิบัติ',
    caution: 'ยืนใกล้ราวจับ เผื่อจับพยุงเมื่อเสียการทรงตัว',
  ),
  LearnPose(
    id: 'tandem_walk',
    name: 'เดินต่อเท้า',
    subtitle: 'เดินต่อเท้าเป็นเส้นตรงเหมือนเดินบนเชือก',
    category: PoseCategory.balance,
    target: 'การทรงตัว',
    icon: Icons.directions_walk_rounded,
    image: 'assets/images/learn/tandem_walk.jpg',
    facts: [
      PoseFact(Icons.repeat_rounded, 'เดิน 10 ก้าว ไป–กลับ = 1 รอบ'),
      PoseFact(Icons.layers_rounded, '5 รอบ'),
      PoseFact(Icons.timer_outlined, 'พักรอบละ 30 วินาที'),
    ],
    steps: [
      'เริ่มจากเท้าซ้ายอยู่ด้านหน้า เท้าขวาอยู่ด้านหลัง กางแขนออกให้ขนานกับพื้น',
      'วางส้นเท้าซ้ายให้ชิดกับปลายเท้าขวา',
      'เดินไปข้างหน้าโดยวางส้นเท้าชิดปลายเท้าอีกข้างสลับกันไป เหมือนการเดินเท้าต่อเท้า',
    ],
    breathing: 'ไม่กลั้นหายใจขณะปฏิบัติ',
    caution: 'เดินในทางที่โล่ง ใกล้ราวจับหรือผนัง',
  ),
  LearnPose(
    id: 'side_walk',
    name: 'เดินไปด้านข้าง',
    subtitle: 'ฝึกทรงตัวด้วยการก้าวเดินไปด้านข้าง',
    category: PoseCategory.balance,
    target: 'การทรงตัว',
    icon: Icons.swap_horiz_rounded,
    image: 'assets/images/learn/side_walk.jpg',
    facts: [
      PoseFact(Icons.arrow_forward_rounded, 'ก้าวข้างแล้วชิดเท้า'),
      PoseFact(Icons.swap_horiz_rounded, 'ทำสลับสองข้าง'),
      PoseFact(Icons.trending_down_rounded, 'ค่อย ๆ ลดการประคอง'),
    ],
    steps: [
      'ยืนตรง กางแขนเล็กน้อยเพื่อช่วยทรงตัว',
      'ก้าวเท้าไปด้านข้างหนึ่งก้าว แล้วชิดอีกเท้าตามมา',
      'ระยะแรกใช้มือช่วยประคอง เมื่อทำได้ดีขึ้นค่อย ๆ ลดการประคองลง',
    ],
    tips: [
      'หากยังปล่อยมือไม่ได้ ให้ใช้มือช่วยประคองน้อยที่สุดเท่าที่จะทรงตัวได้',
    ],
    caution: 'ก้าวไปด้านข้างใกล้ราวจับหรือผนัง',
  ),
];
