import 'pose_frame.dart';

/// Live rep/step counter over a pose stream. Concrete implementations: arm
/// curl, chair stand, 2-minute step. The Live Assessment screen drives this
/// generically:
///
///   1. If [needsCalibration], show [calibrationPrompt] and feed frames to
///      [calibrate] until [isCalibrated] (or a calibration timeout).
///   2. Start the test timer and feed every frame to [add]; display [reps].
///   3. Show [guidance] (Thai reposition hint) whenever it is non-null.
///
/// Implementations gate on landmark likelihood, use hysteresis + debounce to
/// reject partial reps, and must never count while [guidance] is active.
abstract class RepCounter {
  /// Valid reps counted so far.
  int get reps;

  /// Thai repositioning message when the required body parts aren't reliably
  /// visible (e.g. 'มองไม่เห็นเข่าขวา'), or null when tracking is good.
  String? get guidance;

  /// Whether a baseline capture is required before counting can begin.
  bool get needsCalibration;

  /// True once enough calibration frames have been captured.
  bool get isCalibrated;

  /// Thai instruction shown during the calibration phase.
  String get calibrationPrompt;

  /// Feed a frame during the calibration phase (no-op if not needed).
  void calibrate(PoseFrame frame);

  /// Feed a frame during the counting phase; updates [reps] and [guidance].
  void add(PoseFrame frame);

  /// Reset all state (reps, calibration, internal phase).
  void reset();
}
