import 'package:flutter_test/flutter_test.dart';
import 'package:kinex_app/rep_counters/arm_curl_counter.dart';
import 'package:kinex_app/rep_counters/pose_frame.dart';

/// Pure extended pose: right shoulder-elbow-wrist colinear (angle = 180deg).
/// All other landmarks are low-likelihood so the right arm is locked on.
PoseFrame _extended() {
  final landmarks =
      List<Landmark>.filled(Lm.count, const Landmark(0, 0, 0, 0.1), growable: true);
  landmarks[Lm.rightShoulder] = const Landmark(0, 0, 0, 1);
  landmarks[Lm.rightElbow] = const Landmark(0, 1, 0, 1);
  landmarks[Lm.rightWrist] = const Landmark(0, 2, 0, 1);
  return PoseFrame(landmarks);
}

/// Pure flexed pose: wrist folded back next to the shoulder (angle ~0deg).
PoseFrame _flexed() {
  final landmarks =
      List<Landmark>.filled(Lm.count, const Landmark(0, 0, 0, 0.1), growable: true);
  landmarks[Lm.rightShoulder] = const Landmark(0, 0, 0, 1);
  landmarks[Lm.rightElbow] = const Landmark(0, 1, 0, 1);
  landmarks[Lm.rightWrist] = const Landmark(0, 0.01, 0, 1);
  return PoseFrame(landmarks);
}

void feed(ArmCurlCounter c, PoseFrame frame, int times) {
  for (var i = 0; i < times; i++) {
    c.add(frame);
  }
}

void main() {
  group('ArmCurlCounter', () {
    test('starts at 0 reps with no calibration needed', () {
      final c = ArmCurlCounter();
      expect(c.reps, 0);
      expect(c.needsCalibration, isFalse);
      expect(c.isCalibrated, isTrue);
    });

    test('full extended -> flexed -> extended cycle counts 1 rep', () {
      final c = ArmCurlCounter();

      feed(c, _extended(), 3); // settle extended
      expect(c.reps, 0);

      feed(c, _flexed(), 3); // go to flexed
      expect(c.reps, 0);

      feed(c, _extended(), 3); // back to extended -> rep counted
      expect(c.reps, 1);
    });

    test('partial rep (never reaches flexed) does not count', () {
      final c = ArmCurlCounter();

      feed(c, _extended(), 3);
      // Briefly move toward flexed but not enough frames to debounce.
      feed(c, _flexed(), 1);
      feed(c, _extended(), 3);

      expect(c.reps, 0);
    });

    test('partial rep (never returns to extended) does not count', () {
      final c = ArmCurlCounter();

      feed(c, _extended(), 3);
      feed(c, _flexed(), 3);

      expect(c.reps, 0);
    });

    test('multiple full cycles count multiple reps', () {
      final c = ArmCurlCounter();

      feed(c, _extended(), 3);
      for (var i = 0; i < 3; i++) {
        feed(c, _flexed(), 3);
        feed(c, _extended(), 3);
      }

      expect(c.reps, 3);
    });

    test('low-likelihood required landmark sets guidance and blocks counting', () {
      final c = ArmCurlCounter();

      feed(c, _extended(), 3);
      feed(c, _flexed(), 3);

      // Lock-on arm now invisible.
      final landmarks = List<Landmark>.from(_extended().landmarks);
      landmarks[Lm.rightWrist] = const Landmark(0, 2, 0, 0.1);
      final hidden = PoseFrame(landmarks);

      feed(c, hidden, 3);
      expect(c.guidance, isNotNull);
      expect(c.reps, 0); // state frozen, no rep counted while hidden

      feed(c, _extended(), 3);
      expect(c.guidance, isNull);
      expect(c.reps, 1);
    });

    test('reset clears reps and guidance', () {
      final c = ArmCurlCounter();
      feed(c, _extended(), 3);
      feed(c, _flexed(), 3);
      feed(c, _extended(), 3);
      expect(c.reps, 1);

      c.reset();
      expect(c.reps, 0);
      expect(c.guidance, isNull);
    });
  });
}
