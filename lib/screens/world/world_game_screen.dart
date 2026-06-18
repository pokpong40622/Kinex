// Full-screen embedded Unity KINEX WORLD class.
// Requires CAMERA permission: the class scores the player from the live
// MediaPipe pose feed on Android. Receives the results payload from Unity via
// onMessageFromUnity, persists it, and routes to the results screen.
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_embed_unity/flutter_embed_unity.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../data/world_repository.dart';
import '../../models/world_routine.dart';
import '../../models/world_session_record.dart';

class WorldGameScreen extends ConsumerStatefulWidget {
  final String routineId;
  const WorldGameScreen({super.key, required this.routineId});

  @override
  ConsumerState<WorldGameScreen> createState() => _WorldGameScreenState();
}

class _WorldGameScreenState extends ConsumerState<WorldGameScreen> {
  PermissionStatus _cameraStatus = PermissionStatus.denied;
  bool _checked = false;
  bool _handled = false; // guard against double navigation

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
    // Tell the shared Unity player to show Kinex World. Warm case sends now; cold
    // boot is covered by the unity_ready handshake in _onUnityMessage.
    if (status.isGranted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _selectGame());
    }
  }

  void _selectGame() => sendToUnity('SceneRouter', 'LoadGame', 'world');

  /// Messages from Unity (flutter_embed_unity sends a String). The class emits a
  /// JSON `WorldSessionResult` on finish and an exit signal on the in-game exit.
  Future<void> _onUnityMessage(String data) async {
    Map<String, dynamic> msg;
    try {
      msg = jsonDecode(data) as Map<String, dynamic>;
    } catch (_) {
      return; // ignore non-JSON chatter
    }
    final type = msg['type'] as String?;

    if (type == 'unity_ready') {
      _selectGame(); // cold Unity boot finished — (re)assert our scene choice
      return;
    }

    if (type == 'exit') {
      if (mounted) context.go('/home');
      return;
    }

    if (type == 'world_result') {
      if (_handled) return;
      _handled = true;
      final routine = worldRoutineById(widget.routineId);
      final record = WorldSessionRecord.fromUnity(
        msg,
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        dateTime: DateTime.now(),
        routineName: routine?.thaiName ?? widget.routineId,
      );
      await ref.read(worldRepositoryProvider).add(record);
      ref.invalidate(worldHistoryProvider);
      if (mounted) context.go('/world/result', extra: record);
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
        child: Text('ต้องอนุญาตกล้องเพื่อเริ่มคลาส',
            style: TextStyle(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(child: body),
    );
  }
}
