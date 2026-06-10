// Full-screen embedded Unity MEGA DANCE game.
// Requires CAMERA permission: the game drives the avatar from the live
// MediaPipe pose feed on Android.
import 'package:flutter/material.dart';
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
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (!_checked) {
      body = const Center(
        child: Text('Starting camera…', style: TextStyle(color: Colors.white)),
      );
    } else if (_cameraStatus.isGranted) {
      body = const EmbedUnity(
        onMessageFromUnity: null,
      );
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
