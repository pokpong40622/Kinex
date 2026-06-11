import 'pose_frame.dart';
import 'rep_counter.dart';

/// Counts bicep-curl reps on whichever arm is more reliably tracked.
///
/// A rep is a full extended -> flexed -> extended cycle of the elbow angle,
/// each phase held for [_debounceFrames] consecutive frames to reject jitter.
class ArmCurlCounter implements RepCounter {
  // TUNABLE: elbow angle thresholds (degrees) for extended/flexed states.
  static const double _extendedAngle = 150;
  static const double _flexedAngle = 60;

  // TUNABLE: consecutive frames required before a phase change is accepted
  // (~0.3-0.4s at 10fps).
  static const int _debounceFrames = 3;

  static const double _likelihoodThreshold = 0.6;

  @override
  int reps = 0;

  @override
  String? guidance;

  @override
  bool get needsCalibration => false;

  @override
  bool get isCalibrated => true;

  @override
  String get calibrationPrompt => 'ถือน้ำหนักไว้ แขนเหยียดลง';

  /// Required landmarks (shoulder, elbow, wrist) of the locked-on arm. Null
  /// until the first good frame.
  List<int>? _arm;

  bool _flexedSinceCount = false;

  // Pending-phase debounce counters.
  int _extendedStreak = 0;
  int _flexedStreak = 0;
  bool _isExtended = false;
  bool _isFlexed = false;

  @override
  void calibrate(PoseFrame frame) {
    // No calibration phase for arm curls.
  }

  @override
  void add(PoseFrame frame) {
    _arm ??= _pickArm(frame);
    final arm = _arm!;

    final missing = frame.firstMissing(arm, _likelihoodThreshold);
    if (missing != -1) {
      guidance = 'มองไม่เห็น${Lm.thaiName(missing)}';
      return;
    }
    guidance = null;

    final angle = frame.jointAngle(arm[0], arm[1], arm[2]);

    if (angle > _extendedAngle) {
      _extendedStreak++;
      _flexedStreak = 0;
    } else if (angle < _flexedAngle) {
      _flexedStreak++;
      _extendedStreak = 0;
    } else {
      _extendedStreak = 0;
      _flexedStreak = 0;
    }

    if (!_isExtended && _extendedStreak >= _debounceFrames) {
      _isExtended = true;
      _isFlexed = false;
      if (_flexedSinceCount) {
        reps++;
        _flexedSinceCount = false;
      }
    } else if (!_isFlexed && _flexedStreak >= _debounceFrames) {
      _isFlexed = true;
      _isExtended = false;
      _flexedSinceCount = true;
    }
  }

  /// Picks the arm (shoulder/elbow/wrist indices) with the higher average
  /// landmark likelihood.
  List<int> _pickArm(PoseFrame frame) {
    const left = [Lm.leftShoulder, Lm.leftElbow, Lm.leftWrist];
    const right = [Lm.rightShoulder, Lm.rightElbow, Lm.rightWrist];
    final leftAvg =
        left.map((i) => frame[i].likelihood).reduce((a, b) => a + b) / 3;
    final rightAvg =
        right.map((i) => frame[i].likelihood).reduce((a, b) => a + b) / 3;
    return leftAvg >= rightAvg ? left : right;
  }

  @override
  void reset() {
    reps = 0;
    guidance = null;
    _arm = null;
    _flexedSinceCount = false;
    _extendedStreak = 0;
    _flexedStreak = 0;
    _isExtended = false;
    _isFlexed = false;
  }
}
