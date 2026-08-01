import 'package:flutter_riverpod/flutter_riverpod.dart';

/// In-memory session flags for the home "intro" experience. They default fresh
/// on every app launch (not persisted), so the hardware-guide popup and the
/// assessment spotlight show every time the user enters the app.

/// True while the EMG hardware-install guide still needs to be shown this run.
final homeGuidePendingProvider = StateProvider<bool>((_) => true);

/// True while the home page is dimmed to spotlight the ประเมิน (assessment) card.
final assessmentSpotlightProvider = StateProvider<bool>((_) => false);

/// True while the BLE connect-device landing still needs to be shown this run.
/// Once shown (or skipped), set to false so returning users are never interrupted.
final deviceConnectPendingProvider = StateProvider<bool>((_) => true);

/// True when the user skipped (or dismissed) the EMG hardware-install guide this
/// run. Drives the home reminder banner directly, so the warning shows even if a
/// stale calibration is still saved from a previous run. Cleared on finish.
final emgInstallSkippedProvider = StateProvider<bool>((_) => false);
