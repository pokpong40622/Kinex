import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// The four booklet categories (PDF source of truth). Mirrors the Unity
/// ExerciseCategory enum. Each carries a Thai label + accent colour for chips.
enum WorldCategory { stretch, strength, balance, cardio }

extension WorldCategoryX on WorldCategory {
  String get thaiLabel {
    switch (this) {
      case WorldCategory.stretch:
        return 'ยืดเหยียด';
      case WorldCategory.strength:
        return 'กล้ามเนื้อ';
      case WorldCategory.balance:
        return 'การทรงตัว';
      case WorldCategory.cardio:
        return 'คาร์ดิโอ';
    }
  }

  Color get color {
    switch (this) {
      case WorldCategory.stretch:
        return KColors.teal;
      case WorldCategory.strength:
        return KColors.orangeDark;
      case WorldCategory.balance:
        return KColors.blue;
      case WorldCategory.cardio:
        return KColors.pinkDark;
    }
  }
}

/// One exercise as shown in the Flutter overview. Kept in sync (by [id]) with the
/// Unity ExerciseDefinition assets — Unity runs the class, Flutter previews it.
class WorldExerciseDef {
  final String id;
  final String thaiName;
  final String englishName;
  final WorldCategory category;
  final int durationSeconds;
  final bool legsRequired;
  final String instruction;

  const WorldExerciseDef({
    required this.id,
    required this.thaiName,
    required this.englishName,
    required this.category,
    required this.durationSeconds,
    required this.legsRequired,
    required this.instruction,
  });
}

/// A class = an ordered list of exercises.
class WorldRoutineDef {
  final String id;
  final String thaiName;
  final String englishName;
  final String description;
  final List<WorldExerciseDef> exercises;

  const WorldRoutineDef({
    required this.id,
    required this.thaiName,
    required this.englishName,
    required this.description,
    required this.exercises,
  });

  int get totalSeconds =>
      exercises.fold(0, (sum, e) => sum + e.durationSeconds);
  int get exerciseCount => exercises.length;
}

/// Static catalogue. The shipped vertical slice is one "Daily Class"; add more
/// routines / exercises here (and matching Unity assets) to scale.
const List<WorldRoutineDef> worldRoutines = [
  WorldRoutineDef(
    id: 'daily_class',
    thaiName: 'คลาสประจำวัน',
    englishName: 'Daily Class',
    description: 'วอร์มอัพ • คาร์ดิโอ • กล้ามเนื้อ • ทรงตัว • ผ่อนคลาย',
    exercises: [
      WorldExerciseDef(
        id: 'shoulder_reach',
        thaiName: 'ยืดไหล่และสะบัก',
        englishName: 'Shoulder & Scapula Reach',
        category: WorldCategory.stretch,
        durationSeconds: 30,
        legsRequired: false,
        instruction: 'เหยียดแขนขึ้นเหนือศีรษะ ค้างไว้ตามผู้ฝึก',
      ),
      WorldExerciseDef(
        id: 'march',
        thaiName: 'ย่ำเท้าอยู่กับที่',
        englishName: 'March in Place',
        category: WorldCategory.cardio,
        durationSeconds: 40,
        legsRequired: true,
        instruction: 'ย่ำเท้าสลับซ้าย-ขวา แกว่งแขนตามจังหวะ',
      ),
      WorldExerciseDef(
        id: 'lateral_raise',
        thaiName: 'กางแขนออกด้านข้าง',
        englishName: 'Lateral Raise',
        category: WorldCategory.strength,
        durationSeconds: 30,
        legsRequired: false,
        instruction: 'กางแขนสองข้างขึ้นระดับไหล่ แล้วลง',
      ),
      WorldExerciseDef(
        id: 'heel_raise',
        thaiName: 'เขย่งปลายเท้า',
        englishName: 'Heel Raise',
        category: WorldCategory.balance,
        durationSeconds: 30,
        legsRequired: true,
        instruction: 'เขย่งปลายเท้าขึ้น-ลง กางแขนช่วยทรงตัว',
      ),
      WorldExerciseDef(
        id: 'neck_stretch',
        thaiName: 'ยืดคอด้านข้าง',
        englishName: 'Neck Side Stretch',
        category: WorldCategory.stretch,
        durationSeconds: 25,
        legsRequired: false,
        instruction: 'เอียงศีรษะไปด้านข้าง ค้างไว้เบาๆ',
      ),
    ],
  ),
];

WorldRoutineDef? worldRoutineById(String id) {
  for (final r in worldRoutines) {
    if (r.id == id) return r;
  }
  return null;
}
