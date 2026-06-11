import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Persists only for the lifetime of the app session (no shared_preferences
/// needed — the toggle is on the intro screen each time).
class RecordingEnabledNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
  void set(bool value) => state = value;
}

final recordingEnabledProvider =
    NotifierProvider<RecordingEnabledNotifier, bool>(
  RecordingEnabledNotifier.new,
);
