import 'package:flutter_riverpod/flutter_riverpod.dart';

enum GameState { idle, playing, paused, result }

class GameStateNotifier extends StateNotifier<GameState> {
  GameStateNotifier() : super(GameState.idle);

  void start() => state = GameState.playing;
  void pause() => state = GameState.paused;
  void resume() => state = GameState.playing;
  void finish() => state = GameState.result;
  void reset() => state = GameState.idle;
}

final gameStateProvider =
    StateNotifierProvider<GameStateNotifier, GameState>(
  (ref) => GameStateNotifier(),
);
