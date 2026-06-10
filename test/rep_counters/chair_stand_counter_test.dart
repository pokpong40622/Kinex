import 'package:flutter_test/flutter_test.dart';
import 'package:kinex_app/rep_counters/chair_stand_counter.dart';
import 'package:kinex_app/rep_counters/pose_frame.dart';

const _standingHipY = 0.40;
const _sittingHipY = 0.60;

/// Frame with both hips at [hipY] (high likelihood); shoulders also visible
/// so the fallback path isn't exercised unintentionally.
PoseFrame _frame(double hipY, {double hipLikelihood = 0.9}) {
  final landmarks =
      List<Landmark>.filled(Lm.count, const Landmark(0, 0, 0, 0.1), growable: true);
  landmarks[Lm.leftHip] = Landmark(0, hipY, 0, hipLikelihood);
  landmarks[Lm.rightHip] = Landmark(0, hipY, 0, hipLikelihood);
  landmarks[Lm.leftShoulder] = const Landmark(0, 0.1, 0, 0.9);
  landmarks[Lm.rightShoulder] = const Landmark(0, 0.1, 0, 0.9);
  return PoseFrame(landmarks);
}

PoseFrame _standing() => _frame(_standingHipY);
PoseFrame _sitting() => _frame(_sittingHipY);

void feed(ChairStandCounter c, PoseFrame frame, int times) {
  for (var i = 0; i < times; i++) {
    c.add(frame);
  }
}

ChairStandCounter _calibrated() {
  final c = ChairStandCounter();
  c.calibrate(_standing());
  c.calibrate(_sitting());
  expect(c.isCalibrated, isTrue);
  return c;
}

void main() {
  group('ChairStandCounter', () {
    test('needs calibration and is not calibrated initially', () {
      final c = ChairStandCounter();
      expect(c.needsCalibration, isTrue);
      expect(c.isCalibrated, isFalse);
    });

    test('isCalibrated only after seeing both standing and sitting samples', () {
      final c = ChairStandCounter();
      c.calibrate(_standing());
      expect(c.isCalibrated, isFalse);

      c.calibrate(_sitting());
      expect(c.isCalibrated, isTrue);
    });

    test('full sit -> stand -> sit cycle counts 1 rep', () {
      final c = _calibrated();

      feed(c, _sitting(), 3); // settle sitting
      expect(c.reps, 0);

      feed(c, _standing(), 3); // stand up
      expect(c.reps, 0);

      feed(c, _sitting(), 3); // sit back down -> rep counted
      expect(c.reps, 1);
    });

    test('partial rep (never fully stands) does not count', () {
      final c = _calibrated();

      feed(c, _sitting(), 3);
      // Brief move toward standing but not enough frames to debounce.
      feed(c, _standing(), 1);
      feed(c, _sitting(), 3);

      expect(c.reps, 0);
    });

    test('partial rep (stands but never sits back down) does not count', () {
      final c = _calibrated();

      feed(c, _sitting(), 3);
      feed(c, _standing(), 3);

      expect(c.reps, 0);
    });

    test('multiple full cycles count multiple reps', () {
      final c = _calibrated();

      feed(c, _sitting(), 3);
      for (var i = 0; i < 3; i++) {
        feed(c, _standing(), 3);
        feed(c, _sitting(), 3);
      }

      expect(c.reps, 3);
    });

    test('hips invisible sets guidance and blocks counting', () {
      final c = _calibrated();

      feed(c, _sitting(), 3);
      feed(c, _standing(), 3);

      final landmarks = List<Landmark>.from(_standing().landmarks);
      landmarks[Lm.leftHip] = const Landmark(0, 0, 0, 0.1);
      landmarks[Lm.rightHip] = const Landmark(0, 0, 0, 0.1);
      landmarks[Lm.leftShoulder] = const Landmark(0, 0, 0, 0.1);
      landmarks[Lm.rightShoulder] = const Landmark(0, 0, 0, 0.1);
      final hidden = PoseFrame(landmarks);

      feed(c, hidden, 3);
      expect(c.guidance, isNotNull);
      expect(c.reps, 0);

      feed(c, _sitting(), 3);
      expect(c.guidance, isNull);
      expect(c.reps, 1);
    });

    test('falls back to shoulder midpoint when hips not visible', () {
      final c = ChairStandCounter();

      PoseFrame shoulderFrame(double y) {
        final landmarks = List<Landmark>.filled(
            Lm.count, const Landmark(0, 0, 0, 0.1),
            growable: true);
        landmarks[Lm.leftShoulder] = Landmark(0, y, 0, 0.9);
        landmarks[Lm.rightShoulder] = Landmark(0, y, 0, 0.9);
        return PoseFrame(landmarks);
      }

      c.calibrate(shoulderFrame(_standingHipY));
      c.calibrate(shoulderFrame(_sittingHipY));
      expect(c.isCalibrated, isTrue);

      feed(c, shoulderFrame(_sittingHipY), 3);
      feed(c, shoulderFrame(_standingHipY), 3);
      feed(c, shoulderFrame(_sittingHipY), 3);

      expect(c.reps, 1);
      expect(c.guidance, isNull);
    });

    test('reset clears reps, calibration and guidance', () {
      final c = _calibrated();
      feed(c, _sitting(), 3);
      feed(c, _standing(), 3);
      feed(c, _sitting(), 3);
      expect(c.reps, 1);

      c.reset();
      expect(c.reps, 0);
      expect(c.guidance, isNull);
      expect(c.isCalibrated, isFalse);
    });
  });
}
