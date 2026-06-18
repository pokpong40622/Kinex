// Full-screen embedded Unity MEGA DANCE game.
// Requires CAMERA permission: the game drives the avatar from the live
// MediaPipe pose feed on Android.
//
// flutter_embed_unity runs ONE Unity player shared with Kinex World, so we must
// tell Unity which scene to show. We message the persistent SceneRouter
// ("megadance") once the player is ready (and again on every unity_ready, which
// fires on a cold Unity boot).
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_embed_unity/flutter_embed_unity.dart';
import 'package:permission_handler/permission_handler.dart';

class MegaDanceGameScreen extends StatefulWidget {
  const MegaDanceGameScreen({super.key});

  @override
  State<MegaDanceGameScreen> createState() => _MegaDanceGameScreenState();
}

class _MegaDanceGameScreenState extends State<MegaDanceGameScreen> {
  PermissionStatus _cameraStatus = PermissionStatus.denied;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    setState(() {
      _cameraStatus = status;
      _checked = true;
    });
    // Warm case: Unity is already running, so send immediately (it won't re-emit
    // unity_ready). Cold case: this may be too early and is a no-op — the
    // unity_ready handshake below covers it.
    if (status.isGranted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _selectGame());
    }
  }

  void _selectGame() => sendToUnity('SceneRouter', 'LoadGame', 'megadance');

  void _onUnityMessage(String data) {
    if (data.contains('unity_ready')) {
      _selectGame();
    } else if (data.contains('"exit"')) {
      // Unity back button → return to the Flutter home screen.
      if (mounted) context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (!_checked) {
      body = const Center(
        child: Text('Starting camera…', style: TextStyle(color: Colors.white)),
      );
    } else if (_cameraStatus.isGranted) {
      body = EmbedUnity(onMessageFromUnity: _onUnityMessage);
    } else {
      body = const Center(
        child: Text('Camera permission needed to play',
            style: TextStyle(color: Colors.white)),
      );
    }

    // Full-screen embedded Unity game (no app bar). Camera permission is required
    // because MEGA DANCE drives the avatar from the live MediaPipe pose feed.
    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(child: body),
    );
  }
}
