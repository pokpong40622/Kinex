import 'package:flutter/material.dart';
import '../data/assessment_session.dart';

/// The assessment is presented as a 5-stage journey (a "train line"). The first
/// stage groups น้ำหนัก/ส่วนสูง/BMI; the other four group the six movement tests
/// by fitness component. Used by the roadmap (Intro/Progress) and the slim
/// in-test progress rail.

enum StageStatus { done, current, upcoming }

class AssessmentStage {
  final String title;
  final String subtitle;
  final IconData icon;

  /// Movement-test ids in this stage (empty for the body/BMI stage).
  final List<String> testIds;

  const AssessmentStage({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.testIds,
  });
}

const List<AssessmentStage> kStages = [
  AssessmentStage(
    title: 'ข้อมูลร่างกาย & BMI',
    subtitle: 'น้ำหนัก · ส่วนสูง · BMI',
    icon: Icons.monitor_weight_outlined,
    testIds: [],
  ),
  AssessmentStage(
    title: 'ความยืดหยุ่น',
    subtitle: 'แตะมือด้านหลัง · นั่งแตะปลายเท้า',
    icon: Icons.self_improvement,
    testIds: ['back_scratch', 'sit_reach'],
  ),
  AssessmentStage(
    title: 'ความแข็งแรงของกล้ามเนื้อ',
    subtitle: 'งอแขนยกน้ำหนัก · ลุกยืน-นั่ง',
    icon: Icons.fitness_center,
    testIds: ['arm_curl', 'chair_stand'],
  ),
  AssessmentStage(
    title: 'ความอดทนของหัวใจ',
    subtitle: 'ยกเข่าขึ้นลง 2 นาที',
    icon: Icons.favorite_outline,
    testIds: ['step_test'],
  ),
  AssessmentStage(
    title: 'การทรงตัว',
    subtitle: 'ลุก-เดิน-นั่ง ไปกลับ',
    icon: Icons.directions_walk,
    testIds: ['tug'],
  ),
];

bool stageDone(int i, AssessmentSession s) {
  if (i == 0) return s.bmi != null;
  return kStages[i].testIds.every((id) => s.resultFor(id) != null);
}

/// Index of the first not-yet-complete stage, or kStages.length if all done.
int currentStageIndex(AssessmentSession s) {
  for (var i = 0; i < kStages.length; i++) {
    if (!stageDone(i, s)) return i;
  }
  return kStages.length;
}

StageStatus stageStatus(int i, AssessmentSession s) {
  if (stageDone(i, s)) return StageStatus.done;
  if (i == currentStageIndex(s)) return StageStatus.current;
  return StageStatus.upcoming;
}

/// Which stage a movement test belongs to (for the in-test progress rail).
int stageIndexForTest(String testId) {
  for (var i = 0; i < kStages.length; i++) {
    if (kStages[i].testIds.contains(testId)) return i;
  }
  return 0;
}
