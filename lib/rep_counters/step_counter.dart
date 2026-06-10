import 'pose_frame.dart';
import 'rep_counter.dart';

/// Counts right-knee raises against a calibrated baseline target height.
///
/// A rep is a full down -> up -> down cycle of the right knee crossing
/// [_targetY] (up = smaller y, since image y grows downward).
class StepCounter implements RepCounter {
  // TUNABLE: hysteresis band (image-coordinate units, e.g. fraction of frame
  // height for normalised landmarks) around the target height.
  static const double _hysteresis = 0.03;

  // TUNABLE: consecutive frames required before a phase change is accepted.
  static const int _debounceFrames = 3;

  static const double _likelihoodThreshold = 0.6;

  static const _required = [Lm.rightHip, Lm.rightKnee];

  @override
  int reps = 0;

  @override
  String? guidance;

  @override
  bool get needsCalibration => true;

  @override
  bool get isCalibrated => _calibrated;

  @override
  String get calibrationPrompt => 'ยืนตรง มองเห็นทั้งตัว';

  bool _calibrated = false;
  double _targetY = 0;

  bool _raisedSinceCount = false;
  bool _isUp = false;
  bool _isDown = false;
  int _upStreak = 0;
  int _downStreak = 0;

  @override
  void calibrate(PoseFrame frame) {
    if (!frame.allVisible(_required, _likelihoodThreshold)) return;
    final hipY = frame[Lm.rightHip].y;
    final kneeY = frame[Lm.rightKnee].y;
    _targetY = (hipY + kneeY) / 2;
    _calibrated = true;
  }

  @override
  void add(PoseFrame frame) {
    final missing = frame.firstMissing(_required, _likelihoodThreshold);
    if (missing != -1) {
      guidance = 'มองไม่เห็นเข่าขวา';
      return;
    }
    guidance = null;

    if (!_calibrated) return;

    final kneeY = frame[Lm.rightKnee].y;
    final upLine = _targetY - _hysteresis;
    final downLine = _targetY + _hysteresis;

    if (kneeY < upLine) {
      _upStreak++;
      _downStreak = 0;
    } else if (kneeY > downLine) {
      _downStreak++;
      _upStreak = 0;
    } else {
      _upStreak = 0;
      _downStreak = 0;
    }

    if (!_isUp && _upStreak >= _debounceFrames) {
      _isUp = true;
      _isDown = false;
      _raisedSinceCount = true;
    } else if (!_isDown && _downStreak >= _debounceFrames) {
      _isDown = true;
      _isUp = false;
      if (_raisedSinceCount) {
        reps++;
        _raisedSinceCount = false;
      }
    }
  }

  @override
  void reset() {
    reps = 0;
    guidance = null;
    _calibrated = false;
    _targetY = 0;
    _raisedSinceCount = false;
    _isUp = false;
    _isDown = false;
    _upStreak = 0;
    _downStreak = 0;
  }
}
