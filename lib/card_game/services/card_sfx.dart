import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fire-and-forget answer/next sound effects for the card game. Best-effort
/// — if playback fails (no audio focus, muted device, etc.) the game stays
/// fully usable, same spirit as [TtsService].
class CardSfx {
  final AudioPlayer _player = AudioPlayer();

  Future<void> _play(String fileName) async {
    try {
      await _player.stop();
      await _player.play(AssetSource('audio/card_game/$fileName'));
    } catch (_) {
      // ignore — audio is best-effort
    }
  }

  Future<void> correct() => _play('correct.wav');
  Future<void> wrong() => _play('wrong.wav');
  Future<void> next() => _play('next.wav');

  void dispose() => _player.dispose();
}

final cardSfxProvider = Provider<CardSfx>((ref) {
  final sfx = CardSfx();
  ref.onDispose(sfx.dispose);
  return sfx;
});
