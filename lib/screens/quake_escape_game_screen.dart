// Full-screen embedded Unity "Quake Escape" game — a balance game where a city
// collapses on a 180s timer (3 hearts). The player stands on the leg opposite
// whichever floor half is highlighted, or goes up on tiptoes when both sides
// collapse. Pose is read by MediaPipe through the tablet camera, so like
// The Dasher this screen:
//   1. requests camera permission before starting,
//   2. plays in PORTRAIT (a balance game, unlike the landscape titles) —
//      locks portraitUp on enter, restores the app-wide portrait lock on exit,
//   3. tells the shared Unity player to load scene id "quakeescape",
//   4. leaves pause entirely to Unity's own in-game pause button.
//
// There is no separate Flutter start page — Unity runs its own countdown once
// the scene loads, so entering this screen goes straight into the running game
// (behind the camera-permission check).
//
// NOTE: the quakeescape_result payload isn't finalised on the Unity side yet.
// Parsing below is deliberately lenient (every field falls back to a default)
// and assumes: `success` (bool — survived the full 180s), `heartsRemaining`
// (0-3), `durationSeconds` (num, seconds survived). Adjust once Unity's actual
// schema is confirmed.
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_embed_unity/flutter_embed_unity.dart';
import 'package:permission_handler/permission_handler.dart';
import '../data/game_repository.dart';
import '../models/daily_quest.dart';
import '../models/game_session_record.dart';
import '../state/quest_providers.dart';

class QuakeEscapeGameScreen extends ConsumerStatefulWidget {
  const QuakeEscapeGameScreen({super.key});

  @override
  ConsumerState<QuakeEscapeGameScreen> createState() =>
      _QuakeEscapeGameScreenState();
}

class _QuakeEscapeGameScreenState
    extends ConsumerState<QuakeEscapeGameScreen> {
  PermissionStatus _cameraStatus = PermissionStatus.denied;
  bool _checked = false;
  bool _saved = false; // guard: persist a session's result only once

  @override
  void initState() {
    super.initState();
    // Portrait balance game — lock to portraitUp only while playing.
    // Portrait, but BOTH ways up: the tablet gets rotated 180° depending on
    // which side the charging cable is on, and pinning portraitUp alone left
    // the game upside down in that orientation.
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
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

  void _selectGame() => sendToUnity('SceneRouter', 'LoadGame', 'quakeescape');

  void _exitGame() {
    sendToUnity('SceneRouter', 'SetPaused', 'false');
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  Future<void> _onUnityMessage(String data) async {
    if (data.contains('unity_ready')) {
      _selectGame();
    } else if (data.contains('"exit"')) {
      _exitGame();
    } else if (data.contains('quakeescape_result')) {
      if (_saved) return;
      Map<String, dynamic> msg;
      try {
        msg = jsonDecode(data) as Map<String, dynamic>;
      } catch (_) {
        return; // ignore malformed / non-JSON payloads
      }
      _saved = true;
      await _saveResult(msg);
    }
  }

  Future<void> _saveResult(Map<String, dynamic> msg) async {
    // Lenient parsing — schema not finalised yet, every field has a fallback.
    final success = msg['success'] as bool? ?? false;
    final heartsRemaining =
        ((msg['heartsRemaining'] as num?)?.toInt() ?? 0).clamp(0, 3);
    final durationSeconds = (msg['durationSeconds'] as num?)?.toDouble() ?? 0;
    final percent =
        success ? 100.0 : (heartsRemaining / 3 * 100).clamp(0, 100).toDouble();

    final record = GameSessionRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      dateTime: DateTime.now(),
      gameId: 'quakeescape',
      gameName: 'QUAKE ESCAPE',
      // No dedicated game_icons/ art yet — reuse the practice-card art
      // (already declared in pubspec.yaml under assets/images/quake_escape/).
      iconAsset: 'assets/images/quake_escape/card.png',
      durationSeconds: durationSeconds,
      scoreLabel: '$heartsRemaining/3',
      percent: percent,
    );
    await ref.read(gameRepositoryProvider).add(record);
    ref.invalidate(gameHistoryProvider);
    await ref.read(dailyQuestsProvider.notifier).bump(QuestId.playGame);
  }

  @override
  void dispose() {
    // Make sure the game isn't left frozen for the next launch.
    sendToUnity('SceneRouter', 'SetPaused', 'false');
    // Restore the app-wide portrait lock (mirrors main.dart).
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (!_checked) {
      body = const Center(
        child: Text('กำลังเปิดกล้อง…', style: TextStyle(color: Colors.white)),
      );
    } else if (_cameraStatus.isGranted) {
      body = Stack(
        fit: StackFit.expand,
        children: [
          EmbedUnity(onMessageFromUnity: _onUnityMessage),
          // Pause is owned by Unity (HUDCanvas/PauseButton + PausePopup); its
          // exit button sends {"type":"exit"}, handled in _onUnityMessage.
        ],
      );
    } else {
      body = const Center(
        child: Text('ต้องอนุญาตให้ใช้กล้องเพื่อเล่นนะครับ',
            style: TextStyle(color: Colors.white)),
      );
    }

    // Full-screen embedded Unity game (no app bar). Camera permission is
    // required because the game reads live balance pose from MediaPipe.
    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(child: body),
    );
  }
}
