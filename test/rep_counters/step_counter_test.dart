import 'package:flutter_test/flutter_test.dart';
import 'package:kinex_app/rep_counters/pose_frame.dart';
import 'package:kinex_app/rep_counters/step_counter.dart';

const _standingHipY = 0.50;
const _standingKneeY = 0.90;
// targetY = midpoint = 0.70

PoseFrame _frame(double kneeY, {double likelihood = 0.9}) {
  final landmarks =
      List<Landmark>.filled(Lm.count, const Landmark(0, 0, 0, 0.1), growable: true);
  landmarks[Lm.rightHip] = Landmark(0, _standingHipY, 0, likelihood);
  landmarks[Lm.rightKnee] = Landmark(0, kneeY, 0, likelihood);
  return PoseFrame(landmarks);
}

/// Knee down (standing baseline, below target).
PoseFrame _down() => _frame(_standingKneeY);

/// Knee raised above the calibrated target.
PoseFrame _up() => _frame(0.50);

void feed(StepCounter c, PoseFrame frame, int times) {
  for (var i = 0; i < times; i++) {
    c.add(frame);
  }
}

StepCounter _calibrated() {
  final c = StepCounter();
  c.calibrate(_down());
  expect(c.isCalibrated, isTrue);
  return c;
}

void main() {
  group('StepCounter', () {
    test('needs calibration and is not calibrated initially', () {
      final c = StepCounter();
      expect(c.needsCalibration, isTrue);
      expect(c.isCalibrated, isFalse);
    });

    test('calibrate requires visible right hip and knee', () {
      final c = StepCounter();
      final landmarks =
          List<Landmark>.filled(Lm.count, const Landmark(0, 0, 0, 0.1), growable: true);
      landmarks[Lm.rightHip] = const Landmark(0, _standingHipY, 0, 0.1);
      landmarks[Lm.rightKnee] = const Landmark(0, _standingKneeY, 0, 0.1);
      c.calibrate(PoseFrame(landmarks));
      expect(c.isCalibrated, isFalse);

      c.calibrate(_down());
      expect(c.isCalibrated, isTrue);
    });

    test('full down -> up -> down cycle counts 1 rep', () {
      final c = _calibrated();

      feed(c, _down(), 3); // settle down
      expect(c.reps, 0);

      feed(c, _up(), 3); // raise knee
      expect(c.reps, 0);

      feed(c, _down(), 3); // lower knee -> rep counted
      expect(c.reps, 1);
    });

    test('partial rep (never raises above target) does not count', () {
      final c = _calibrated();

      feed(c, _down(), 3);
      // Brief move toward up but not enough frames to debounce.
      feed(c, _up(), 1);
      feed(c, _down(), 3);

      expect(c.reps, 0);
    });

    test('partial rep (raises but never lowers again) does not count', () {
      final c = _calibrated();

      feed(c, _down(), 3);
      feed(c, _up(), 3);

      expect(c.reps, 0);
    });

    test('multiple full cycles count multiple reps', () {
      final c = _calibrated();

      feed(c, _down(), 3);
      for (var i = 0; i < 3; i++) {
        feed(c, _up(), 3);
        feed(c, _down(), 3);
      }

      expect(c.reps, 3);
    });

    test('right knee invisible sets guidance "มองไม่เห็นเข่าขวา" and blocks counting', () {
      final c = _calibrated();

      feed(c, _down(), 3);
      feed(c, _up(), 3);

      final landmarks = List<Landmark>.from(_down().landmarks);
      landmarks[Lm.rightKnee] = const Landmark(0, _standingKneeY, 0, 0.1);
      final hidden = PoseFrame(landmarks);

      feed(c, hidden, 3);
      expect(c.guidance, 'มองไม่เห็นเข่าขวา');
      expect(c.reps, 0);

      feed(c, _down(), 3);
      expect(c.guidance, isNull);
      expect(c.reps, 1);
    });

    test('reset clears reps, calibration and guidance', () {
      final c = _calibrated();
      feed(c, _down(), 3);
      feed(c, _up(), 3);
      feed(c, _down(), 3);
      expect(c.reps, 1);

      c.reset();
      expect(c.reps, 0);
      expect(c.guidance, isNull);
      expect(c.isCalibrated, isFalse);
    });
  });
}
