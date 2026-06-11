import 'package:flutter_test/flutter_test.dart';
import 'package:kinex_app/rep_counters/tug_detector.dart';
import 'package:kinex_app/rep_counters/pose_frame.dart';

// Normalised Y coords: smaller = higher on screen = standing.
const double _seatedHipY = 0.60;
const double _standHipY = 0.38; // > 0.12 below seatedY

PoseFrame _frame(double hipY, {double likelihood = 0.9}) {
  final lm = List<Landmark>.filled(Lm.count, const Landmark(0, 0, 0, 0.1));
  lm[Lm.leftHip] = Landmark(0, hipY, 0, likelihood);
  lm[Lm.rightHip] = Landmark(0, hipY, 0, likelihood);
  lm[Lm.leftShoulder] = const Landmark(0, 0.2, 0, 0.9);
  lm[Lm.rightShoulder] = const Landmark(0, 0.2, 0, 0.9);
  return PoseFrame(List<Landmark>.from(lm));
}

PoseFrame _invisible() {
  return PoseFrame(
      List<Landmark>.filled(Lm.count, const Landmark(0, 0, 0, 0.1)));
}

/// Feed [frame] to calibrate() [n] times.
void feedCalib(TugDetector d, PoseFrame frame, int n) {
  for (var i = 0; i < n; i++) {
    d.calibrate(frame);
  }
}

/// Feed [frame] to add() [n] times.
void feedAdd(TugDetector d, PoseFrame frame, int n) {
  for (var i = 0; i < n; i++) {
    d.add(frame);
  }
}

TugDetector _calibrated() {
  final d = TugDetector();
  feedCalib(d, _frame(_seatedHipY), 10);
  expect(d.isCalibrated, isTrue);
  return d;
}

void main() {
  group('TugDetector — calibration', () {
    test('not calibrated initially', () {
      final d = TugDetector();
      expect(d.isCalibrated, isFalse);
    });

    test('calibrates after enough stable seated frames', () {
      final d = _calibrated();
      expect(d.isCalibrated, isTrue);
    });

    test('sets guidance when landmarks invisible during calibration', () {
      final d = TugDetector();
      d.calibrate(_invisible());
      expect(d.guidance, isNotNull);
    });

    test('resets calibration samples on visibility loss', () {
      final d = TugDetector();
      // Feed a few frames then go invisible — should NOT calibrate.
      feedCalib(d, _frame(_seatedHipY), 5);
      feedCalib(d, _invisible(), 1);
      feedCalib(d, _frame(_seatedHipY), 5);
      // 5 valid after reset — still needs more to reach _calibFrames.
      expect(d.isCalibrated, isFalse);
    });
  });

  group('TugDetector — start detection', () {
    test('started becomes true after standing for debounce frames', () {
      final d = _calibrated();
      feedAdd(d, _frame(_standHipY), 4);
      expect(d.started, isTrue);
    });

    test('brief stand (< debounce) does not trigger started', () {
      final d = _calibrated();
      feedAdd(d, _frame(_standHipY), 2);
      expect(d.started, isFalse);
    });

    test('started is false initially', () {
      final d = _calibrated();
      expect(d.started, isFalse);
    });
  });

  group('TugDetector — finish detection', () {
    test('sitting back AFTER 2s marks finished', () async {
      final d = _calibrated();
      feedAdd(d, _frame(_standHipY), 4); // stand → started
      expect(d.started, isTrue);

      // Simulate time passing by waiting slightly over 2 seconds.
      await Future<void>.delayed(const Duration(milliseconds: 2100));

      feedAdd(d, _frame(_seatedHipY), 4); // sit → finished
      expect(d.finished, isTrue);
    });

    test('sitting back BEFORE 2s does NOT mark finished', () {
      final d = _calibrated();
      feedAdd(d, _frame(_standHipY), 4); // stand → started

      // No delay — immediately sit back.
      feedAdd(d, _frame(_seatedHipY), 4);
      expect(d.finished, isFalse);
    });

    test('finished stays false if person never stands', () {
      final d = _calibrated();
      feedAdd(d, _frame(_seatedHipY), 20);
      expect(d.finished, isFalse);
    });
  });

  group('TugDetector — guidance', () {
    test('guidance set when hips and shoulders invisible during add', () {
      final d = _calibrated();
      d.add(_invisible());
      expect(d.guidance, isNotNull);
    });

    test('guidance cleared when person visible again', () {
      final d = _calibrated();
      d.add(_invisible());
      d.add(_frame(_seatedHipY));
      expect(d.guidance, isNull);
    });
  });

  group('TugDetector — reset', () {
    test('reset clears all state', () async {
      final d = _calibrated();
      feedAdd(d, _frame(_standHipY), 4);
      await Future<void>.delayed(const Duration(milliseconds: 2100));
      feedAdd(d, _frame(_seatedHipY), 4);
      expect(d.finished, isTrue);

      d.reset();
      expect(d.started, isFalse);
      expect(d.finished, isFalse);
      expect(d.isCalibrated, isFalse);
      expect(d.guidance, isNull);
    });
  });

  group('TugDetector — shoulder fallback', () {
    test('uses shoulder midpoint when hips not visible', () {
      final d = TugDetector();
      // Calibrate with shoulder-only frames.
      final shoulderSeated = () {
        final lm =
            List<Landmark>.filled(Lm.count, const Landmark(0, 0, 0, 0.1));
        lm[Lm.leftShoulder] = const Landmark(0, 0.60, 0, 0.9);
        lm[Lm.rightShoulder] = const Landmark(0, 0.60, 0, 0.9);
        return PoseFrame(List<Landmark>.from(lm));
      }();

      final shoulderStand = () {
        final lm =
            List<Landmark>.filled(Lm.count, const Landmark(0, 0, 0, 0.1));
        lm[Lm.leftShoulder] = const Landmark(0, 0.38, 0, 0.9);
        lm[Lm.rightShoulder] = const Landmark(0, 0.38, 0, 0.9);
        return PoseFrame(List<Landmark>.from(lm));
      }();

      feedCalib(d, shoulderSeated, 10);
      expect(d.isCalibrated, isTrue);

      feedAdd(d, shoulderStand, 4);
      expect(d.started, isTrue);
    });
  });
}
