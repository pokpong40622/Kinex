// Full-screen embedded Unity "Hang Glider" game (นักร่อน) — a tilt-controlled
// quiz glider. Unlike the other games it uses the tablet's ACCELEROMETER (no
// camera), and it plays in LANDSCAPE, so this screen:
//   1. forces landscape on enter and restores the app's portrait lock on exit,
//   2. does NOT ask for camera permission,
//   3. tells the shared Unity player to load scene id "hangglider".
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_embed_unity/flutter_embed_unity.dart';

class HangGliderGameScreen extends StatefulWidget {
  const HangGliderGameScreen({super.key});

  @override
  State<HangGliderGameScreen> createState() => _HangGliderGameScreenState();
}

class _HangGliderGameScreenState extends State<HangGliderGameScreen> {
  @override
  void initState() {
    super.initState();
    // Landscape for this game only (the app is otherwise portrait-locked).
    SystemChrome.setPreferredOrientations(
        const [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    // Warm case: Unity is already running, so select the scene immediately. Cold
    // boots are covered by the unity_ready handshake below.
    WidgetsBinding.instance.addPostFrameCallback((_) => _selectGame());
  }

  @override
  void dispose() {
    // Restore the app-wide portrait lock (mirrors main.dart).
    SystemChrome.setPreferredOrientations(
        const [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    super.dispose();
  }

  void _selectGame() => sendToUnity('SceneRouter', 'LoadGame', 'hangglider');

  void _onUnityMessage(String data) {
    if (data.contains('unity_ready')) {
      _selectGame();
    } else if (data.contains('"exit"')) {
      if (mounted) context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: EmbedUnity(onMessageFromUnity: _onUnityMessage),
      ),
    );
  }
}
