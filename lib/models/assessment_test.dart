// Static catalog of the three SPPB movement tests (balance, gait speed, chair
// stand). Weight, Height and BMI are handled by their own dedicated screens and
// are not in this list. Each test runs through the shared instruction screen and
// then a dedicated run screen (see the router).

enum TestMethod {
  camera, // live ML Kit pose (balance hold / chair-stand rep timing)
  manualStopwatch, // helper-operated in-app stopwatch (gait speed)
}

class AssessmentTest {
  final String id;
  final String thaiName;
  final String thaiComponent;
  final TestMethod method;

  /// Hold/target window in seconds for timed tests (0 if not applicable).
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

/// The three SPPB tests, in administration order (balance → gait → chair stand).
/// IDs match the route :testId path parameter.
const List<AssessmentTest> kMovementTests = [
  AssessmentTest(
    id: 'balance',
    thaiName: 'ประเมินการทรงตัว',
    thaiComponent: 'การทรงตัว (Balance Tests)',
    method: TestMethod.camera,
    durationSeconds: 10,
    equipment: 'พื้นที่โล่งราบ · มีที่จับยึดใกล้ ๆ · มีผู้ดูแลคอยประคองตลอด',
    instructions: [
      'ทำ 3 ท่ายืนต่อเนื่อง โดยพยายามยืนนิ่งท่าละ 10 วินาที',
      'ท่าที่ 1 ยืนเท้าชิดกัน · ท่าที่ 2 ยืนเหลื่อมเท้าครึ่งก้าว · ท่าที่ 3 ยืนต่อส้น-ปลายเท้า',
      'จัดวางเท้าตามภาพในแต่ละท่า แล้วกดเริ่มเพื่อจับเวลา 10 วินาที',
      'ถ้าเสียการทรงตัวหรือต้องขยับเท้า ระบบจะหยุดจับเวลาให้เอง',
    ],
    thresholdText:
        'แต่ละท่ายืนครบ 10 วินาทีได้คะแนน · ท่าต่อส้นเท้าเต็ม 10 วิ = 2 คะแนน (รวมสูงสุด 4 คะแนน)',
  ),
  AssessmentTest(
    id: 'gait_speed',
    thaiName: 'วัดความเร็วในการเดิน 4 เมตร',
    thaiComponent: 'ความเร็วในการเดินทางราบ (Gait Speed)',
    method: TestMethod.manualStopwatch,
    durationSeconds: 0,
    equipment: 'ทางเดินราบ ทำเครื่องหมายจุดเริ่มและระยะ 4 เมตร',
    instructions: [
      'ทำเครื่องหมายจุดเริ่มต้นและจุดสิ้นสุดให้ห่างกัน 4 เมตร',
      'ให้ผู้รับการทดสอบเดินด้วยความเร็วปกติจากจุดเริ่มจนสุดระยะ',
      'ผู้ดูแลกดเริ่มเมื่อก้าวเท้าแรก และกดหยุดเมื่อผ่านเส้น 4 เมตร',
      'ทำ 2 ครั้ง ระบบจะเลือกเวลาที่เร็วที่สุดมาคิดคะแนน',
    ],
    thresholdText:
        'น้อยกว่า 4.82 วิ = 4 · 4.82–6.20 = 3 · 6.21–8.70 = 2 · มากกว่า 8.70 = 1 · เดินไม่ได้ = 0',
  ),
  AssessmentTest(
    id: 'chair_stand',
    thaiName: 'ลุกยืนจากเก้าอี้ 5 ครั้ง',
    thaiComponent: 'ความแข็งแรงของขา (Chair Stand)',
    method: TestMethod.camera,
    durationSeconds: 0,
    equipment: 'เก้าอี้ที่มั่นคง ไม่มีที่วางแขน · มีผู้ดูแลอยู่ใกล้ ๆ',
    instructions: [
      'นั่งกลางเก้าอี้ หลังตรง ไขว้แขนแนบอก',
      'ทดสอบก่อน: ลองลุกขึ้นยืนหนึ่งครั้งโดยไม่ใช้มือ ถ้าทำไม่ได้ให้หยุด (0 คะแนน)',
      'จากนั้นลุกขึ้นยืนจนสุดแล้วนั่งลง ทำให้ครบ 5 ครั้งเร็วที่สุด',
      'ระบบจะจับเวลาตั้งแต่ครั้งแรกจนลุกครบ 5 ครั้ง',
    ],
    thresholdText:
        'ไม่เกิน 11.19 วิ = 4 · 11.20–13.69 = 3 · 13.70–16.69 = 2 · มากกว่า 16.7 = 1 · เกิน 60 วิ/ทำไม่ได้ = 0',
  ),
];

AssessmentTest assessmentTestById(String id) =>
    kMovementTests.firstWhere((t) => t.id == id);
