import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether the Thai TTS narrator (card-game intro/question lines, learning
/// posture names) speaks aloud. Persisted; **default ON**. Toggled from the
/// settings page; every narrator `speak()` call site must check this before
/// calling [TtsService.speak].
final ttsNarratorEnabledProvider =
    StateNotifierProvider<TtsNarratorEnabledNotifier, bool>(
      (ref) => TtsNarratorEnabledNotifier(),
    );

class TtsNarratorEnabledNotifier extends StateNotifier<bool> {
  static const _key = 'tts_narrator_enabled';

  // Start ON; asynchronously replace with the stored value once prefs load.
  TtsNarratorEnabledNotifier() : super(true) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getBool(_key);
    if (stored != null) state = stored;
  }

  Future<void> set(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}
