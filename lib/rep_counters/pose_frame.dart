import 'dart:math' as math;

/// BlazePose 33-landmark indices. These match ML Kit's `PoseLandmarkType`
/// ordinal values, so a `Pose` converts to a [PoseFrame] by index.
class Lm {
  Lm._();
  static const int nose = 0;
  static const int leftShoulder = 11;
  static const int rightShoulder = 12;
  static const int leftElbow = 13;
  static const int rightElbow = 14;
  static const int leftWrist = 15;
  static const int rightWrist = 16;
  static const int leftHip = 23;
  static const int rightHip = 24;
  static const int leftKnee = 25;
  static const int rightKnee = 26;
  static const int leftAnkle = 27;
  static const int rightAnkle = 28;

  static const int count = 33;

  /// Thai body-part name for repositioning guidance.
  static String thaiName(int index) => switch (index) {
        nose => 'ใบหน้า',
        leftShoulder || rightShoulder => 'หัวไหล่',
        leftElbow || rightElbow => 'ข้อศอก',
        leftWrist || rightWrist => 'ข้อมือ',
        leftHip || rightHip => 'สะโพก',
        leftKnee => 'เข่าซ้าย',
        rightKnee => 'เข่าขวา',
        leftAnkle || rightAnkle => 'ข้อเท้า',
        _ => 'ร่างกาย',
      };
}

class Landmark {
  final double x;
  final double y;
  final double z;
  final double likelihood; // 0..1 (ML Kit inFrameLikelihood)
  const Landmark(this.x, this.y, this.z, this.likelihood);
}

/// One frame of pose landmarks in image coordinates. Pure (no ML Kit import)
/// so rep counters can be unit-tested with synthetic frames.
class PoseFrame {
  /// Length [Lm.count] (33). Missing landmarks should have likelihood 0.
  final List<Landmark> landmarks;
  const PoseFrame(this.landmarks);

  Landmark operator [](int i) => landmarks[i];

  bool visible(int i, [double t = 0.6]) => landmarks[i].likelihood >= t;

  bool allVisible(List<int> idx, [double t = 0.6]) =>
      idx.every((i) => visible(i, t));

  /// First index in [idx] that is NOT visible, or -1 if all visible.
  int firstMissing(List<int> idx, [double t = 0.6]) {
    for (final i in idx) {
      if (!visible(i, t)) return i;
    }
    return -1;
  }

  /// Interior joint angle at vertex [b] (degrees) for points a-b-c.
  double jointAngle(int a, int b, int c) {
    final ax = landmarks[a].x - landmarks[b].x;
    final ay = landmarks[a].y - landmarks[b].y;
    final cx = landmarks[c].x - landmarks[b].x;
    final cy = landmarks[c].y - landmarks[b].y;
    final magA = math.sqrt(ax * ax + ay * ay);
    final magC = math.sqrt(cx * cx + cy * cy);
    if (magA == 0 || magC == 0) return 0;
    final cos = ((ax * cx + ay * cy) / (magA * magC)).clamp(-1.0, 1.0);
    return math.acos(cos) * 180 / math.pi;
  }

  double midX(int a, int b) => (landmarks[a].x + landmarks[b].x) / 2;
  double midY(int a, int b) => (landmarks[a].y + landmarks[b].y) / 2;
}
