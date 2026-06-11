// Static catalog of the six "movement" tests (the three-band ones that run
// through the instruction → calibrate/manual → live/manual → result template).
// Weight, Height and BMI are handled by their own dedicated screens and are
// not in this list.

enum TestMethod {
  camera, // live ML Kit pose rep counting
  manualStopwatch, // in-app stopwatch (TUG)
  manualChoice, // helper picks ดีมาก/ดี/เสี่ยง (reach tests)
}

class AssessmentTest {
  final String id;
  final String thaiName;
  final String thaiComponent;
  final TestMethod method;

  /// Test window for camera/timed tests, in seconds (0 if not applicable).
  final int durationSeconds;

  final List<String> instructions; // ordered Thai steps
  final String? equipment; // Thai, nullable
  final String thresholdText; // human-readable Thai scoring criteria

  const AssessmentTest({
    required this.id,
    required this.thaiName,
    required this.thaiComponent,
    required this.method,
    required this.durationSeconds,
    required this.instructions,
    required this.equipment,
    required this.thresholdText,
  });
}

/// The six movement tests, in administration order (flexibility → strength →
/// cardio → balance). IDs match the route :testId path parameter.
const List<AssessmentTest> kMovementTests = [
  AssessmentTest(
    id: 'back_scratch',
    thaiName: 'แตะมือด้านหลัง',
    thaiComponent: 'ความยืดหยุ่นของหัวไหล่และแขน',
    method: TestMethod.manualChoice,
    durationSeconds: 0,
    equipment: null,
    instructions: [
      'ยกแขนขวาขึ้นเหนือไหล่ แล้วงอลงไปด้านหลัง ฝ่ามือแนบกลางหลัง',
      'เอาแขนซ้ายอ้อมจากด้านล่างขึ้นไปด้านหลัง พยายามให้ปลายนิ้วทั้งสองข้างแตะกัน',
      'ทำ 2 ครั้ง เลือกครั้งที่ดีที่สุด แล้วสลับข้างทำซ้ำ',
    ],
    thresholdText:
        'ปลายนิ้วทับซ้อนกัน = ดีมาก · แตะกันพอดี = ดี · แตะไม่ถึง = เสี่ยง',
  ),
  AssessmentTest(
    id: 'sit_reach',
    thaiName: 'นั่งเก้าอี้แตะปลายเท้า',
    thaiComponent: 'ความยืดหยุ่นของกล้ามเนื้อหลังและขา',
    method: TestMethod.manualChoice,
    durationSeconds: 0,
    equipment: 'เก้าอี้ที่มั่นคง',
    instructions: [
      'นั่งที่ขอบเก้าอี้ เหยียดขาข้างหนึ่งตรงไปข้างหน้า ส้นเท้าวางพื้น ปลายเท้าชี้ขึ้น',
      'ค่อย ๆ ก้มตัวยื่นมือทั้งสองไปแตะปลายเท้า เข่าตึง',
      'ทำ 2 ครั้ง เลือกครั้งที่ดีที่สุด',
    ],
    thresholdText:
        'ปลายนิ้วเลยปลายเท้า = ดีมาก · แตะถึงปลายเท้า = ดี · แตะไม่ถึง = เสี่ยง',
  ),
  AssessmentTest(
    id: 'arm_curl',
    thaiName: 'งอแขนยกน้ำหนัก 30 วินาที',
    thaiComponent: 'ความแข็งแรงของกล้ามเนื้อแขน',
    method: TestMethod.camera,
    durationSeconds: 30,
    equipment: 'ดัมเบล/ขวดน้ำ (หญิง 2.3 กก. / ชาย 3.6 กก.)',
    instructions: [
      'นั่งตัวตรง ถือน้ำหนักไว้ในมือข้างถนัด แขนเหยียดลงข้างลำตัว',
      'งอข้อศอกยกน้ำหนักขึ้นจนสุด แล้วเหยียดลงจนสุด นับเป็น 1 ครั้ง',
      'ทำให้ได้มากที่สุดภายใน 30 วินาที',
    ],
    thresholdText: 'มากกว่า 11 ครั้ง = ดีมาก · 11 ครั้ง = ดี · น้อยกว่า 11 = เสี่ยง',
  ),
  AssessmentTest(
    id: 'chair_stand',
    thaiName: 'ลุกยืน-นั่งบนเก้าอี้ 30 วินาที',
    thaiComponent: 'ความแข็งแรงของกล้ามเนื้อขา',
    method: TestMethod.camera,
    durationSeconds: 30,
    equipment: 'เก้าอี้ที่มั่นคง ไม่มีที่วางแขน',
    instructions: [
      'นั่งกลางเก้าอี้ หลังตรง ไขว้แขนแนบอก',
      'ลุกขึ้นยืนจนตัวตรง แล้วนั่งลง นับเป็น 1 ครั้ง',
      'ทำให้ได้มากที่สุดภายใน 30 วินาที',
    ],
    thresholdText: 'มากกว่า 8 ครั้ง = ดีมาก · 8 ครั้ง = ดี · น้อยกว่า 8 = เสี่ยง',
  ),
  AssessmentTest(
    id: 'step_test',
    thaiName: 'ยืนยกเข่าขึ้นลง 2 นาที',
    thaiComponent: 'ความอดทนของระบบหัวใจและไหลเวียนเลือด',
    method: TestMethod.camera,
    durationSeconds: 120,
    equipment: null,
    instructions: [
      'ยืนตรง ยกเข่าขึ้นสลับซ้าย-ขวา ให้เข่าสูงระดับกึ่งกลางระหว่างสะโพกกับหัวเข่า',
      'ระบบจะนับเฉพาะเข่าขวาที่ยกถึงระดับที่กำหนด',
      'ก้าวต่อเนื่องให้ได้มากที่สุดภายใน 2 นาที',
    ],
    thresholdText: 'มากกว่า 65 ครั้ง = ดีมาก · 65 ครั้ง = ดี · น้อยกว่า 65 = เสี่ยง',
  ),
  AssessmentTest(
    id: 'tug',
    thaiName: 'ลุก-เดิน-นั่ง ไปกลับ (TUG)',
    thaiComponent: 'การทรงตัวและการเคลื่อนไหว',
    method: TestMethod.camera,
    durationSeconds: 0,
    equipment: 'เก้าอี้มีที่วางแขน · กรวย/จุดหมายห่าง 3 เมตร',
    instructions: [
      'นั่งบนเก้าอี้ หลังพิงพนัก ให้กล้องเห็นร่างกายชัดเจน',
      'ระบบจะเริ่มจับเวลาเมื่อคุณลุกขึ้น และหยุดเมื่อคุณนั่งลง',
      'ลุกขึ้นยืน เดินไปข้างหน้า 3 เมตร อ้อมจุดหมาย เดินกลับมานั่งลง',
    ],
    thresholdText: 'น้อยกว่า 12 วินาที = ดีมาก · 12 วินาที = ดี · มากกว่า 12 = เสี่ยง',
  ),
];

AssessmentTest assessmentTestById(String id) =>
    kMovementTests.firstWhere((t) => t.id == id);
