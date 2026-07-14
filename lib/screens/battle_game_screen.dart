// Full-screen embedded Unity Battle Game (ผู้พิทักษ์สวนสมดุล — pose-battle RPG).
//
// flutter_embed_unity runs ONE Unity player shared with the other games, so we
// must tell Unity which scene to show. We message the persistent SceneRouter
// ("battlegame") once the player is ready (and again on every unity_ready,
// which fires on a cold Unity boot).
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_embed_unity/flutter_embed_unity.dart';
import 'package:permission_handler/permission_handler.dart';

class BattleGameScreen extends StatefulWidget {
  const BattleGameScreen({super.key});

  @override
  State<BattleGameScreen> createState() => _BattleGameScreenState();
}

class _BattleGameScreenState extends State<BattleGameScreen> {
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

  void _selectGame() => sendToUnity('SceneRouter', 'LoadGame', 'battlegame');

  void _onUnityMessage(String data) {
    if (data.contains('unity_ready')) {
      _selectGame();
    } else if (data.contains('"exit"')) {
      // Unity back button → return to the Flutter home screen.
      if (mounted) context.go('/home');
    } else if (data.contains('battlegame_result')) {
      debugPrint(data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ผลเกม: บันทึกแล้ว (debug)')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (!_checked) {
      body = const Center(
        child: Text('กำลังเปิดกล้อง…', style: TextStyle(color: Colors.white)),
      );
    } else if (_cameraStatus.isGranted) {
      body = EmbedUnity(onMessageFromUnity: _onUnityMessage);
    } else {
      body = const Center(
        child: Text('ต้องอนุญาตให้ใช้กล้องเพื่อเล่นนะครับ',
            style: TextStyle(color: Colors.white)),
      );
    }

    // Full-screen embedded Unity game (no app bar). Camera permission is required
    // because the battle drives the avatar and every pose-attack from the live
    // MediaPipe pose feed.
    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(child: body),
    );
  }
}
