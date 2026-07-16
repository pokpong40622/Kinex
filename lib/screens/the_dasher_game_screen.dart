// Full-screen embedded Unity "The Dasher" game (3-lane pose-controlled rehab
// game).
//
// flutter_embed_unity runs ONE Unity player shared with the other games, so we
// must tell Unity which scene to show. We message the persistent SceneRouter
// ("thedasher") once the player is ready (and again on every unity_ready,
// which fires on a cold Unity boot).
//
// Tutorial: the 3 how-to graphics show as a pop-up overlay ON TOP of the game
// when you first enter (normal game flow), instead of on a separate page before
// the start screen. Dismissing the overlay reveals the running game.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_embed_unity/flutter_embed_unity.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';

class TheDasherGameScreen extends StatefulWidget {
  const TheDasherGameScreen({super.key});

  @override
  State<TheDasherGameScreen> createState() => _TheDasherGameScreenState();
}

class _TheDasherGameScreenState extends State<TheDasherGameScreen> {
  PermissionStatus _cameraStatus = PermissionStatus.denied;
  bool _checked = false;
  bool _showTutorial = true;

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

  void _onUnityMessage(String data) {
    if (data.contains('unity_ready')) {
      _selectGame();
    } else if (data.contains('"exit"')) {
      // Unity back button → return to the Flutter home screen.
      if (mounted) context.go('/home');
    } else if (data.contains('thedasher_result')) {
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
    // because the game drives lane-switch input from the live MediaPipe pose feed.
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SizedBox.expand(child: body),
          if (_checked && _cameraStatus.isGranted && _showTutorial)
            _TutorialOverlay(
              onDone: () => setState(() => _showTutorial = false),
            ),
        ],
      ),
    );
  }
}

/// Tutorial pop-up shown over the running game on first entry: a 3-page carousel
/// of the how-to graphics with next / start controls. Dismisses to reveal the
/// game underneath.
class _TutorialOverlay extends StatefulWidget {
  final VoidCallback onDone;
  const _TutorialOverlay({required this.onDone});

  @override
  State<_TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<_TutorialOverlay> {
  final _controller = PageController();
  int _page = 0;

  static const _images = [
    'assets/images/the_dasher/intro_move.png',
    'assets/images/the_dasher/intro_treasure.png',
    'assets/images/the_dasher/intro_kick.png',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page == _images.length - 1) {
      widget.onDone();
    } else {
      _controller.animateToPage(
        _page + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _images.length - 1;

    return Container(
      color: Colors.black.withValues(alpha: 0.72),
      child: SafeArea(
        child: Column(
          children: [
            // Skip in the top-right — jump straight into the game.
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.all(context.r(12)),
                child: TextButton(
                  onPressed: widget.onDone,
                  child: Text('ข้าม',
                      style: thaiSans(
                          size: context.r(15),
                          weight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _images.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, index) => Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: context.r(24), vertical: context.r(12)),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: EdgeInsets.all(context.r(18)),
                    child: Image.asset(_images[index], fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: context.r(24), vertical: context.r(20)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: List.generate(
                      _images.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: EdgeInsets.symmetric(horizontal: context.r(4)),
                        width: i == _page ? context.r(22) : context.r(8),
                        height: context.r(8),
                        decoration: BoxDecoration(
                          color: i == _page
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(context.r(6)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(context.r(24), 0, context.r(24),
                  context.r(24)),
              child: SizedBox(
                width: double.infinity,
                child: _StartButton(
                  label: isLast ? 'เริ่มเล่น' : 'ถัดไป',
                  icon: isLast
                      ? Icons.play_arrow_rounded
                      : Icons.arrow_forward_rounded,
                  onTap: _next,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _StartButton(
      {required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: context.r(56),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: KColors.deepPurple,
          borderRadius: BorderRadius.circular(context.r(28)),
          boxShadow: [
            BoxShadow(
              color: KColors.deepPurple.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: thaiSans(
                    size: context.r(17),
                    weight: FontWeight.w800,
                    color: Colors.white)),
            SizedBox(width: context.r(8)),
            Icon(icon, color: Colors.white, size: context.r(24)),
          ],
        ),
      ),
    );
  }
}
