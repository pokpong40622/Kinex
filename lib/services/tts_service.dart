import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Thin Thai text-to-speech wrapper. Degrades silently if the device has no
/// Thai voice — the UI must remain fully usable without audio.
class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _ready = false;
  bool _available = true;

  Future<void> _ensureInit() async {
    if (_ready) return;
    _ready = true;
    try {
      await _tts.setLanguage('th-TH');
      await _tts.setSpeechRate(0.45); // slower for elderly
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
    } catch (_) {
      _available = false;
    }
  }

  Future<void> speak(String text) async {
    await _ensureInit();
    if (!_available) return;
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {
      // ignore — audio is best-effort
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}

final ttsServiceProvider = Provider<TtsService>((ref) {
  final tts = TtsService();
  ref.onDispose(tts.stop);
  return tts;
});
