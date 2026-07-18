// Full-screen embedded Unity "The Dasher" game (3-lane pose-controlled rehab
// game).
//
// flutter_embed_unity runs ONE Unity player shared with the other games, so we
// must tell Unity which scene to show. We message the persistent SceneRouter
// ("thedasher") once the player is ready (and again on every unity_ready,
// which fires on a cold Unity boot).
//
// Tutorial: the 3 how-to graphics now show as a pop-up ON THE START PAGE
// (the_dasher_start_page.dart), not here — so entering this screen goes straight
// into the running game with no overlay.
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_embed_unity/flutter_embed_unity.dart';
import 'package:permission_handler/permission_handler.dart';
import '../data/game_repository.dart';
import '../models/game_session_record.dart';
import '../state/emergency_contact.dart';

/// Native ACTION_CALL bridge (android/.../MainActivity.kt) — used to auto-dial
/// the emergency contact hands-free when Unity reports a fall.
const _phoneChannel = MethodChannel('kinex/phone');

class TheDasherGameScreen extends ConsumerStatefulWidget {
  const TheDasherGameScreen({super.key});

  @override
  ConsumerState<TheDasherGameScreen> createState() =>
      _TheDasherGameScreenState();
}

class _TheDasherGameScreenState extends ConsumerState<TheDasherGameScreen> {
  PermissionStatus _cameraStatus = PermissionStatus.denied;
  bool _checked = false;
  bool _saved = false; // guard: persist a session's result only once

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

  void _selectGame() => sendToUnity('SceneRouter', 'LoadGame', 'thedasher');

  Future<void> _onUnityMessage(String data) async {
    if (data.contains('unity_ready')) {
      _selectGame();
    } else if (data.contains('"exit"')) {
      // Unity back button → return to the Flutter home screen.
      if (mounted) context.go('/home');
    } else if (data.contains('thedasher_result')) {
      if (_saved) return;
      Map<String, dynamic> msg;
      try {
        msg = jsonDecode(data) as Map<String, dynamic>;
      } catch (_) {
        return; // ignore malformed / non-JSON payloads
      }
      _saved = true;
      final record = GameSessionRecord.fromDasher(
        msg,
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        dateTime: DateTime.now(),
      );
      await ref.read(gameRepositoryProvider).add(record);
      ref.invalidate(gameHistoryProvider);
    } else if (data.contains('sos_call')) {
      await _handleSosCall();
    }
  }

  // Unity detected a fall, showed its own popup + 10s countdown, and the user
  // didn't cancel — auto-dial the configured emergency contact hands-free.
  Future<void> _handleSosCall() async {
    final contact = ref.read(emergencyContactProvider);
    if (!contact.isSet) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('ยังไม่ได้ตั้งค่าผู้ติดต่อฉุกเฉิน'),
          content: const Text('กรุณาตั้งค่าเบอร์ผู้ติดต่อฉุกเฉินในหน้าตั้งค่าก่อนใช้งาน'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ตกลง'),
            ),
          ],
        ),
      );
      return;
    }

    final status = await Permission.phone.request();
    if (!mounted) return;
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ต้องอนุญาตให้โทรออกเพื่อใช้ระบบฉุกเฉิน')),
      );
      return;
    }

    try {
      await _phoneChannel.invokeMethod('call', {'number': contact.phone});
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ต้องอนุญาตให้โทรออกเพื่อใช้ระบบฉุกเฉิน')),
      );
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
    // because the game drives lane-switch input from the live MediaPipe pose feed.
    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(child: body),
    );
  }
}

