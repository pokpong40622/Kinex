import 'package:flutter_riverpod/flutter_riverpod.dart';

/// In-memory session flags for the home "intro" experience. They default fresh
/// on every app launch (not persisted), so the hardware-guide popup and the
/// assessment spotlight show every time the user enters the app.

/// True while the EMG hardware-install guide still needs to be shown this run.
final homeGuidePendingProvider = StateProvider<bool>((_) => true);

/// True while the home page is dimmed to spotlight the ประเมิน (assessment) card.
final assessmentSpotlightProvider = StateProvider<bool>((_) => false);
