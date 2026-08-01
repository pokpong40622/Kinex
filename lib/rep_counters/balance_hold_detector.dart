import 'dart:math' as math;

import 'pose_frame.dart';

/// Watches a standing pose during a balance hold and flags a loss of balance:
/// the participant steps, sways hard, grabs support, or leaves the frame.
///
/// It does NOT verify the exact foot placement (side-by-side / semi-tandem /
/// tandem) — that is set up by the participant/helper per the on-screen
/// footprint diagram, because a front-facing tablet cannot reliably distinguish
/// those few-centimetre foot differences. What it can do reliably is confirm the
/// body is present and detect when it moves out of the held stance, which is
/// exactly the SPPB fail condition.
///
/// All motion is measured relative to shoulder width (the "body scale") so it is
/// independent of camera resolution and distance.
class BalanceHoldDetector {
  // TUNABLE: hip-midpoint drift, as a fraction of shoulder width, that counts as
  // a step/sway (loss of balance).
  static const double _driftFraction = 0.55;

  // TUNABLE: consecutive frames of drift / lost tracking before we call it.
  static const int _debounceFrames = 4;

  static const double _likelihoodThreshold = 0.5;

  bool _started = false;
  double? _baseX; // baseline hip-mid X
  double? _baseY; // baseline hip-mid Y
  double _scale = 1;
  int _badStreak = 0;

  /// True once a loss of balance has been detected for the current hold.
  bool lost = false;

  /// Thai coaching/repositioning message, or null when tracking is good.
  String? guidance;

  bool get started => _started;

  double? _bodyScale(PoseFrame f) {
    if (f.allVisible([Lm.leftShoulder, Lm.rightShoulder], _likelihoodThreshold)) {
      final dx = f[Lm.leftShoulder].x - f[Lm.rightShoulder].x;
      final dy = f[Lm.leftShoulder].y - f[Lm.rightShoulder].y;
      final d = math.sqrt(dx * dx + dy * dy);
      if (d > 1) return d;
    }
    if (f.allVisible([Lm.leftHip, Lm.rightHip], _likelihoodThreshold)) {
      final dx = f[Lm.leftHip].x - f[Lm.rightHip].x;
      final dy = f[Lm.leftHip].y - f[Lm.rightHip].y;
      final d = math.sqrt(dx * dx + dy * dy);
      if (d > 1) return d;
    }
    return null;
  }

  /// The body must be reliably visible before a hold can start.
  bool ready(PoseFrame frame) {
    final ok = frame.allVisible(
        [Lm.leftHip, Lm.rightHip, Lm.leftShoulder, Lm.rightShoulder],
        _likelihoodThreshold);
    guidance = ok ? null : 'ขยับตำแหน่ง ให้กล้องเห็นลำตัวชัดเจน';
    return ok;
  }

  /// Capture the baseline stance at the moment the hold timer starts.
  void start(PoseFrame frame) {
    final scale = _bodyScale(frame);
    _baseX = frame.midX(Lm.leftHip, Lm.rightHip);
    _baseY = frame.midY(Lm.leftHip, Lm.rightHip);
    _scale = scale ?? 1;
    _started = true;
    lost = false;
    _badStreak = 0;
    guidance = null;
  }

  /// Feed a frame during the hold; sets [lost] once balance is clearly broken.
  void add(PoseFrame frame) {
    if (!_started || lost) return;

    if (!frame.allVisible([Lm.leftHip, Lm.rightHip], _likelihoodThreshold)) {
      _badStreak++;
      guidance = 'มองไม่เห็นลำตัว';
      if (_badStreak >= _debounceFrames) lost = true;
      return;
    }

    final x = frame.midX(Lm.leftHip, Lm.rightHip);
    final y = frame.midY(Lm.leftHip, Lm.rightHip);
    final dx = x - (_baseX ?? x);
    final dy = y - (_baseY ?? y);
    final drift = math.sqrt(dx * dx + dy * dy) / _scale;

    if (drift > _driftFraction) {
      _badStreak++;
      guidance = 'พยายามยืนนิ่ง ๆ';
      if (_badStreak >= _debounceFrames) lost = true;
    } else {
      _badStreak = 0;
      guidance = null;
    }
  }

  void reset() {
    _started = false;
    _baseX = null;
    _baseY = null;
    _scale = 1;
    _badStreak = 0;
    lost = false;
    guidance = null;
  }
}
