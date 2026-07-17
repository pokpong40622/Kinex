// Full-screen embedded Unity "Hang Glider" game (นักร่อน) — a tilt-controlled
// quiz glider. Unlike the other games it uses the tablet's ACCELEROMETER (no
// camera), and it plays in LANDSCAPE, so this screen:
//   1. forces landscape on enter and restores the app's portrait lock on exit,
//   2. does NOT ask for camera permission,
//   3. tells the shared Unity player to load scene id "hangglider",
//   4. overlays an in-game pause button (pause / resume / home).
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
  bool _paused = false;

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
    // Make sure the game isn't left frozen for the next launch.
    sendToUnity('SceneRouter', 'SetPaused', 'false');
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

  void _onUnityMessage(String data) {
    if (data.contains('unity_ready')) {
      _selectGame();
    } else if (data.contains('"exit"')) {
      _goHome();
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
