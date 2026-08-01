// Full-screen embedded Unity "Hang Glider" game (นักร่อน) — a tilt-controlled
// quiz glider. Unlike the other games it uses the tablet's ACCELEROMETER (no
// camera), and it plays in LANDSCAPE, so this screen:
//   1. forces landscape on enter and restores the app's portrait lock on exit,
//   2. does NOT ask for camera permission,
//   3. tells the shared Unity player to load scene id "hangglider",
//   4. overlays an in-game pause button (pause / resume / home).
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_embed_unity/flutter_embed_unity.dart';
import '../ble/ble_service.dart';
import '../data/game_repository.dart';
import '../models/daily_quest.dart';
import '../models/game_session_record.dart';
import '../state/quest_providers.dart';

class HangGliderGameScreen extends ConsumerStatefulWidget {
  const HangGliderGameScreen({super.key});

  @override
  ConsumerState<HangGliderGameScreen> createState() =>
      _HangGliderGameScreenState();
}

class _HangGliderGameScreenState extends ConsumerState<HangGliderGameScreen> {
  bool _paused = false;
  bool _saved = false; // guard: persist a session's result only once

  BleController? _handCtl;
  StreamSubscription<String>? _handSub;

  @override
  void initState() {
    super.initState();
    // Landscape for this game only (the app is otherwise portrait-locked).
    SystemChrome.setPreferredOrientations(
        const [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    // Warm case: Unity is already running, so select the scene immediately. Cold
    // boots are covered by the unity_ready handshake below.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _selectGame();
      _startHandStream();
    });
  }

  void _startHandStream() {
    if (ref.read(handBleProvider).status != BleStatus.connected) return;
    final ctl = ref.read(handBleProvider.notifier);
    _handCtl = ctl;
    _handSub = ctl.incoming.listen(_onTiltLine);
    ctl.send('STREAM:ON');
  }

  // TILT:<x>,<y>,<z> — forward the pitch (y, middle value) to Unity as the
  // glider's steering input. Fires at 30 Hz, so no setState here.
  void _onTiltLine(String line) {
    if (!line.startsWith('TILT:')) return;
    final parts = line.substring(5).split(',');
    if (parts.length != 3) return;
    final vals = <double>[];
    for (final p in parts) {
      final v = double.tryParse(p.trim());
      if (v == null) return; // malformed → drop the whole sample
      vals.add(v);
    }
    final y = vals[1];
    sendToUnity('SceneRouter', 'SetHandTilt', y.toStringAsFixed(1));
  }

  @override
  void dispose() {
    // Make sure the game isn't left frozen for the next launch.
    sendToUnity('SceneRouter', 'SetPaused', 'false');
    _handCtl?.send('STREAM:OFF');
    _handSub?.cancel();
    // Restore the app-wide portrait lock (mirrors main.dart).
    SystemChrome.setPreferredOrientations(
        const [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    super.dispose();
  }

  void _selectGame() => sendToUnity('SceneRouter', 'LoadGame', 'hangglider');

  void _setPaused(bool value) {
    sendToUnity('SceneRouter', 'SetPaused', value ? 'true' : 'false');
    setState(() => _paused = value);
  }

  void _goHome() {
    sendToUnity('SceneRouter', 'SetPaused', 'false');
    if (mounted) context.go('/home');
  }

  Future<void> _onUnityMessage(String data) async {
    if (data.contains('unity_ready')) {
      _selectGame();
    } else if (data.contains('"exit"')) {
      _goHome();
    } else if (data.contains('hangglider_result')) {
      if (_saved) return;
      Map<String, dynamic> msg;
      try {
        msg = jsonDecode(data) as Map<String, dynamic>;
      } catch (_) {
        return; // ignore malformed / non-JSON payloads
      }
      _saved = true;
      final record = GameSessionRecord.fromHangGlider(
        msg,
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        dateTime: DateTime.now(),
      );
      await ref.read(gameRepositoryProvider).add(record);
      ref.invalidate(gameHistoryProvider);
      await ref.read(dailyQuestsProvider.notifier).bump(QuestId.playGame);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          EmbedUnity(onMessageFromUnity: _onUnityMessage),
          // Pause button — top-right, always locked in place while playing.
          if (!_paused)
            Positioned(
              top: 16,
              right: 16,
              child: SafeArea(
                child: _RoundIconButton(
                  icon: Icons.pause_rounded,
                  onTap: () => _setPaused(true),
                ),
              ),
            ),
          // Paused panel — dim + resume / home.
          if (_paused) _PausePanel(onResume: () => _setPaused(false), onHome: _goHome),
        ],
      ),
    );
  }
}

/// Small translucent round button used for the top-right pause control.
class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}

/// Full-screen dim shown when the game is paused, with Resume and Home actions.
class _PausePanel extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onHome;
  const _PausePanel({required this.onResume, required this.onHome});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.6),
        alignment: Alignment.center,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('หยุดชั่วคราว',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF223A5E))),
              const SizedBox(height: 20),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PauseAction(
                    icon: Icons.play_arrow_rounded,
                    label: 'เล่นต่อ',
                    color: const Color(0xFF2E8BD6),
                    onTap: onResume,
                  ),
                  const SizedBox(width: 16),
                  _PauseAction(
                    icon: Icons.home_rounded,
                    label: 'หน้าหลัก',
                    color: const Color(0xFF7A8699),
                    onTap: onHome,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PauseAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _PauseAction(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 30),
            const SizedBox(height: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
