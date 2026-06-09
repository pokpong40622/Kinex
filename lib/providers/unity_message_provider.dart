import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _unityMessageController = StreamController<String>.broadcast();

final unityMessageStreamProvider = StreamProvider<String>((ref) {
  ref.onDispose(_unityMessageController.close);
  return _unityMessageController.stream;
});

// Stage 2: replace with real UnityWidgetController
final unityControllerProvider = StateProvider<Object?>((ref) => null);

void sendToUnity(String gameObject, String method, String message) {
  // Stage 2: wire to real flutter_embed_unity controller
}
