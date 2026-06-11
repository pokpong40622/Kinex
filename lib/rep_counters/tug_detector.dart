import 'pose_frame.dart';

/// Detects the TUG (Timed Up and Go) start/finish events from a pose stream.
///
/// The screen owns elapsed time via a Stopwatch; this class only signals WHEN
/// the timer should start ([started]) and stop ([finished]).
///
/// State machine:
///   calibrating → waitingToStand → standing ([started]=true) → seated again
///   after min walk time ([finished]=true)
///
/// IMPORTANT: ML Kit landmark coordinates are in IMAGE PIXELS, not a 0..1
/// fraction. Distances therefore depend on resolution and how far the person
/// is from the camera. To stay scale-independent, every threshold below is
/// expressed as a multiple of the person's own TORSO LENGTH (the vertical
/// distance from shoulder-midpoint to hip-midpoint), measured at calibration.
class TugDetector {
  // TUNABLE: how far (in torso-lengths) the torso must rise above seatedY
  // before we call it "standing".
  static const double _standFraction = 0.45;

  // TUNABLE: within how many torso-lengths of seatedY counts as "seated again".
  // Made generous on purpose — the second sit just needs to be detected
  // reliably, not precisely, and the AI is noisy after a walk. The user only
  // has to lower roughly two-thirds of the way back into the chair.
  static const double _sitFraction = 0.32;

  // TUNABLE: consecutive frames required to confirm STANDING (start).
  static const int _debounceFrames = 4;

  // TUNABLE: consecutive frames required to confirm the SECOND SIT (stop).
  // Lower than standing so the finish triggers easily.
  static const int _sitDebounceFrames = 2;

  // TUNABLE: minimum seconds between started and finished (ignore early sits).
  static const double _minWalkSeconds = 2.0;

  // TUNABLE: number of stable frames needed to capture the seated baseline.
  static const int _calibFrames = 8;

  // TUNABLE: max Y spread across calibration frames, as a fraction of torso
  // length, to accept as "stable seated" (rejects mid-movement frames).
  static const double _calibSpreadFraction = 0.18;

  static const double _likelihoodThreshold = 0.6;

  final String calibrationPrompt = 'นั่งบนเก้าอี้ หลังพิงพนัก';

  bool get isCalibrated => _seatedY != null;
  bool started = false;
  bool finished = false;

  String? guidance;

  /// TEMP debug readout of the calibration state, shown on-screen.
  String debug = '';

  double? _seatedY;
  double _torsoLen = 0; // pixels, captured at calibration
  final List<double> _calibSamples = [];

  bool _isStanding = false;
  int _standStreak = 0;
  int _sitStreak = 0;

  DateTime? _startTime;

  /// Vertical torso extent (shoulder-mid → hip-mid) in pixels, or null if the
  /// needed landmarks aren't visible.
  double? _torsoLength(PoseFrame frame) {
    if (!frame.allVisible(
        [Lm.leftShoulder, Lm.rightShoulder, Lm.leftHip, Lm.rightHip],
        _likelihoodThreshold)) {
      return null;
    }
    final shoulderY = frame.midY(Lm.leftShoulder, Lm.rightShoulder);
    final hipY = frame.midY(Lm.leftHip, Lm.rightHip);
    final len = (hipY - shoulderY).abs();
    return len > 1 ? len : null;
  }

  /// Torso reference Y (hip-mid preferred, shoulder-mid fallback) in pixels.
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

  /// Feed frames during the calibration phase. Collects stable seated Y
  /// samples; [isCalibrated] becomes true once enough are accumulated.
  void calibrate(PoseFrame frame) {
    if (_seatedY != null) return; // already calibrated

    final y = _torsoY(frame);
    final len = _torsoLength(frame);

    if (y == null || len == null) {
      guidance = 'มองไม่เห็นตัว';
      _calibSamples.clear(); // restart on visibility loss
      debug = 'NO BODY  '
          'LHip=${frame[Lm.leftHip].likelihood.toStringAsFixed(2)} '
          'RHip=${frame[Lm.rightHip].likelihood.toStringAsFixed(2)} '
          'LSh=${frame[Lm.leftShoulder].likelihood.toStringAsFixed(2)} '
          'RSh=${frame[Lm.rightShoulder].likelihood.toStringAsFixed(2)}';
      return;
    }
    guidance = null;
    _calibSamples.add(y);
    _torsoLen = len; // keep the latest measured torso length

    final maxSpread = len * _calibSpreadFraction;
    double spread = 0;
    if (_calibSamples.length >= _calibFrames) {
      final minY = _calibSamples.reduce((a, b) => a < b ? a : b);
      final maxY = _calibSamples.reduce((a, b) => a > b ? a : b);
      spread = maxY - minY;
      if (spread <= maxSpread) {
        // Stable seated baseline captured.
        _seatedY = _calibSamples.reduce((a, b) => a + b) / _calibSamples.length;
      } else {
        // Person was moving; discard oldest half and keep collecting.
        _calibSamples.removeRange(0, _calibSamples.length ~/ 2);
      }
    }

    debug = 'y=${y.toStringAsFixed(0)}  torso=${len.toStringAsFixed(0)}px\n'
        'samples=${_calibSamples.length}/$_calibFrames  '
        'spread=${spread.toStringAsFixed(1)} (need<=${maxSpread.toStringAsFixed(1)})';
  }

  /// Feed frames after the user pressed 'เริ่ม'. Updates [started] and
  /// [finished].
  void add(PoseFrame frame) {
    if (finished) return;

    final y = _torsoY(frame);
    if (y == null) {
      // The user is out of the camera's view — expected during the 3 m walk.
      // CRUCIAL: keep all state (started, streaks, _startTime) untouched and
      // just wait, so the test resumes seamlessly when they walk back in.
      guidance = started
          ? 'เดินกลับเข้ามาในกล้อง แล้วนั่งลงเพื่อจบการทดสอบ'
          : 'มองไม่เห็นตัว';
      // Don't let a stale standing-streak survive a long absence; require the
      // sit to be re-confirmed from fresh frames after they return.
      _standStreak = 0;
      return;
    }
    guidance = null;

    final seated = _seatedY;
    if (seated == null) return;

    final standMargin = _torsoLen * _standFraction;
    final sitMargin = _torsoLen * _sitFraction;

    // Standing: torso Y is significantly higher (smaller y value).
    final standThreshold = seated - standMargin;
    // Seated again: torso Y is back near the baseline.
    final sitThreshold = seated - sitMargin;

    if (y < standThreshold) {
      _standStreak++;
      _sitStreak = 0;
    } else if (y > sitThreshold) {
      _sitStreak++;
      _standStreak = 0;
    } else {
      _standStreak = 0;
      _sitStreak = 0;
    }

    debug = 'y=${y.toStringAsFixed(0)} seat=${seated.toStringAsFixed(0)} '
        'standAt<${standThreshold.toStringAsFixed(0)} '
        'standing=$_isStanding\n'
        'standStreak=$_standStreak sitStreak=$_sitStreak';

    if (!started && !_isStanding && _standStreak >= _debounceFrames) {
      _isStanding = true;
      started = true;
      _startTime = DateTime.now();
    }

    if (started && _isStanding && _sitStreak >= _sitDebounceFrames) {
      final elapsed = _startTime == null
          ? _minWalkSeconds + 1
          : DateTime.now().difference(_startTime!).inMilliseconds / 1000.0;
      if (elapsed >= _minWalkSeconds) {
        finished = true;
      }
      // If too early (< _minWalkSeconds), ignore this sit — keep waiting.
      // Reset sit streak so it doesn't immediately re-trigger on next frame.
      _sitStreak = 0;
    }
  }

  void reset() {
    started = false;
    finished = false;
    guidance = null;
    _seatedY = null;
    _torsoLen = 0;
    _calibSamples.clear();
    _isStanding = false;
    _standStreak = 0;
    _sitStreak = 0;
    _startTime = null;
  }
}
