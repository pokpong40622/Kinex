import 'pose_frame.dart';
import 'rep_counter.dart';

/// Counts sit-to-stand reps using torso vertical position (hip or shoulder
/// midpoint Y). Requires a calibration phase to learn the standing/sitting
/// Y range before counting.
class ChairStandCounter implements RepCounter {
  // TUNABLE: minimum standing/sitting Y range (fraction of image height,
  // assuming normalised 0..1 landmark coords) to consider calibration valid.
  static const double _minRange = 0.05;

  // TUNABLE: hysteresis band as a fraction of the calibrated range.
  static const double _hysteresisFraction = 0.10;

  // TUNABLE: consecutive frames required before a phase change is accepted.
  static const int _debounceFrames = 3;

  static const double _likelihoodThreshold = 0.6;

  @override
  int reps = 0;

  @override
  String? guidance;

  @override
  bool get needsCalibration => true;

  @override
  bool get isCalibrated => _calibrated;

  @override
  String get calibrationPrompt => 'นั่งตรงบนเก้าอี้ แล้วลุกขึ้นยืนหนึ่งครั้ง';

  bool _calibrated = false;
  double? _minY; // standing (smaller y = higher on screen)
  double? _maxY; // sitting
  double _threshold = 0;
  double _hysteresis = 0;

  bool _standingSinceCount = false;
  bool _isStanding = false;
  bool _isSitting = false;
  int _standingStreak = 0;
  int _sittingStreak = 0;

  double? _torsoY(PoseFrame frame) {
    if (frame.allVisible([Lm.leftHip, Lm.rightHip], _likelihoodThreshold)) {
      return frame.midY(Lm.leftHip, Lm.rightHip);
    }
    if (frame.allVisible(
        [Lm.leftShoulder, Lm.rightShoulder], _likelihoodThreshold)) {
      return frame.midY(Lm.leftShoulder, Lm.rightShoulder);
    }
    return null;
  }

  @override
  void calibrate(PoseFrame frame) {
    final y = _torsoY(frame);
    if (y == null) return;

    _minY = _minY == null ? y : (y < _minY! ? y : _minY);
    _maxY = _maxY == null ? y : (y > _maxY! ? y : _maxY);

    if (_maxY! - _minY! >= _minRange) {
      _threshold = (_minY! + _maxY!) / 2;
      _hysteresis = (_maxY! - _minY!) * _hysteresisFraction;
      _calibrated = true;
    }
  }

  @override
  void add(PoseFrame frame) {
    final y = _torsoY(frame);
    if (y == null) {
      final missing = frame.firstMissing(
          [Lm.leftHip, Lm.rightHip, Lm.leftShoulder, Lm.rightShoulder],
          _likelihoodThreshold);
      guidance = missing == -1 ? 'มองไม่เห็นร่างกาย' : 'มองไม่เห็น${Lm.thaiName(missing)}';
      return;
    }
    guidance = null;

    if (!_calibrated) return;

    final standingLine = _threshold - _hysteresis;
    final sittingLine = _threshold + _hysteresis;

    if (y < standingLine) {
      _standingStreak++;
      _sittingStreak = 0;
    } else if (y > sittingLine) {
      _sittingStreak++;
      _standingStreak = 0;
    } else {
      _standingStreak = 0;
      _sittingStreak = 0;
    }

    if (!_isStanding && _standingStreak >= _debounceFrames) {
      _isStanding = true;
      _isSitting = false;
      _standingSinceCount = true;
    } else if (!_isSitting && _sittingStreak >= _debounceFrames) {
      _isSitting = true;
      _isStanding = false;
      if (_standingSinceCount) {
        reps++;
        _standingSinceCount = false;
      }
    }
  }

  @override
  void reset() {
    reps = 0;
    guidance = null;
    _calibrated = false;
    _minY = null;
    _maxY = null;
    _threshold = 0;
    _hysteresis = 0;
    _standingSinceCount = false;
    _isStanding = false;
    _isSitting = false;
    _standingStreak = 0;
    _sittingStreak = 0;
  }
}
