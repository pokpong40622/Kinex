// "Quick tour" demo: one self-contained screen that runs 3 poses of THE
// DASHER, auto-advances to 2 poses of QUAKE ESCAPE, then shows a result page.
// It exists so the owner can show a judge what the platform is in ~2 minutes
// without touching a menu. Entry point: the `_DemoTourCard` on Home.
//
// Step state is a simple enum owned by this one screen (no provider, no
// service, no new architecture layer) — the whole run is one route. Both
// games are the existing embedded Unity player, scripted via the existing
// SceneRouter channel with a small demo contract:
//   sendToUnity('SceneRouter', 'SetDemo', '3');        // pose count, 3 or 2
//   sendToUnity('SceneRouter', 'LoadGame', 'thedasher'); // then 'quakeescape'
// Unity replies on the normal message channel:
//   {"type":"demo_pose","game":"thedasher","index":0,"ok":true}
//   {"type":"demo_done","game":"thedasher","completed":2,"total":3}
//
// Robustness (this gets shown to judges):
//  - every step has a visible way out (exit / retry / secondary button),
//  - an inactivity watchdog (_watchdogDuration) fires if no demo_pose /
//    demo_done arrives for a while, forcing the run forward with the
//    remaining poses in that game marked skipped — a stalled or not-yet-
//    finished Unity build can never strand the user mid-demo,
//  - camera permission denial shows a clear message + a way back, never a
//    black screen,
//  - message parsing is deliberately lenient (try/catch around jsonDecode,
//    every field defaulted), matching quake_escape_game_screen.dart.
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_embed_unity/flutter_embed_unity.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';

enum _Step { intro, permissionDenied, dasher, handoff, quake, result }

class _PoseOutcome {
  final String name;
  final String hint;
  bool ok = false;
  bool recorded = false;
  _PoseOutcome(this.name, this.hint);
}

class QuickDemoScreen extends StatefulWidget {
  const QuickDemoScreen({super.key});

  @override
  State<QuickDemoScreen> createState() => _QuickDemoScreenState();
}

class _QuickDemoScreenState extends State<QuickDemoScreen> {
  // Pure stall guard, NOT pacing. Unity's demo beats are self-paced: each one
  // waits up to ~10 s for the player's body to appear, then gives ~25 s to
  // actually do the pose, then settles. So a legitimate single beat can run
  // ~37 s and the old 12 s watchdog was firing mid-pose every time — that is
  // what made the tour "not wait for me and move on randomly". This only fires
  // when Unity has genuinely gone silent.
  static const _watchdogDuration = Duration(seconds: 75);

  // Unity silent for this long, while a game is running, is long enough to
  // tell the user something is wrong and point them at the skip button —
  // well before the watchdog gives up on the game entirely.
  static const _stallHintAfter = Duration(seconds: 20);

  static const _handoffSeconds = 3;

  _Step _step = _Step.intro;
  bool _unityMounted = false;
  bool _dasherStarted = false;

  int _dasherIdx = 0; // current pose within Dasher, 0..2
  int _quakeIdx = 0; // current pose within Quake, 0..1
  int _countdown = _handoffSeconds;

  Timer? _watchdog;
  Timer? _handoffTimer;

  // Stall hint: set when Unity has been silent for _stallHintAfter while a
  // game is on screen. Cleared by every message and by each step change.
  Timer? _stallTimer;
  bool _stalled = false;

  final List<_PoseOutcome> _poses = [
    _PoseOutcome('ก้าวหลบอุกกาบาต', 'ก้าวเท้าไปด้านข้างเพื่อหลบ'),
    _PoseOutcome('ก้าวเก็บสมบัติ', 'ก้าวเท้าไปเก็บของที่ปรากฏ'),
    _PoseOutcome('เตะห่วง', 'ยกขาเตะห่วงให้ผ่าน'),
    _PoseOutcome('ยืนขาเดียว', 'ยกขาข้างที่พื้นถล่ม ค้างไว้สักครู่'),
    _PoseOutcome('เขย่งปลายเท้า', 'เขย่งปลายเท้าขึ้นค้างไว้'),
  ];

  @override
  void initState() {
    super.initState();
    // Both demo games are portrait — but BOTH ways up, since the tablet is
    // rotated 180° depending on which side the charging cable is on.
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void dispose() {
    _watchdog?.cancel();
    _stallTimer?.cancel();
    _handoffTimer?.cancel();
    if (_unityMounted) sendToUnity('SceneRouter', 'SetPaused', 'false');
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  // ── flow control ─────────────────────────────────────────────────────

  Future<void> _startTour() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    if (status.isGranted) {
      setState(() {
        _step = _Step.dasher;
        _unityMounted = true;
      });
      // Warm case (Unity already running from an earlier screen this
      // session): send immediately. Cold case: covered by the unity_ready
      // handshake in _onUnityMessage. _tryStartDasher guards against both
      // firing.
      WidgetsBinding.instance.addPostFrameCallback((_) => _tryStartDasher());
      _resetWatchdog();
    } else {
      setState(() => _step = _Step.permissionDenied);
    }
  }

  void _tryStartDasher() {
    if (_dasherStarted) return;
    _dasherStarted = true;
    sendToUnity('SceneRouter', 'SetDemo', '3');
    sendToUnity('SceneRouter', 'LoadGame', 'thedasher');
  }

  /// Called on entering a game and on every message from Unity: the run is
  /// alive, so restart both the stall hint and the give-up watchdog.
  void _resetWatchdog() {
    _watchdog?.cancel();
    _watchdog = Timer(_watchdogDuration, _onWatchdogFired);
    _stallTimer?.cancel();
    if (_stalled && mounted) setState(() => _stalled = false);
    _stallTimer = Timer(_stallHintAfter, () {
      if (mounted) setState(() => _stalled = true);
    });
  }

  void _stopWatchdog() {
    _watchdog?.cancel();
    _stallTimer?.cancel();
    _stalled = false;
  }

  void _onWatchdogFired() {
    if (!mounted) return;
    if (_step == _Step.dasher) {
      _advanceAfterGame('thedasher');
    } else if (_step == _Step.quake) {
      _advanceAfterGame('quakeescape');
    }
  }

  void _record(int globalIndex, bool ok) {
    if (globalIndex < 0 || globalIndex >= _poses.length) return;
    final pose = _poses[globalIndex];
    if (pose.recorded) return;
    pose.recorded = true;
    pose.ok = ok;
  }

  void _onUnityMessage(String data) {
    if (data.contains('unity_ready')) {
      _tryStartDasher();
      return;
    }
    if (data.contains('"exit"')) {
      _exit();
      return;
    }
    Map<String, dynamic> msg;
    try {
      msg = jsonDecode(data) as Map<String, dynamic>;
    } catch (_) {
      return; // ignore malformed / non-JSON payloads
    }
    final type = msg['type'] as String?;
    if (type == 'demo_pose') {
      _handlePose(msg);
    } else if (type == 'demo_done') {
      _advanceAfterGame(msg['game'] as String? ?? '');
    } else if (_step == _Step.dasher || _step == _Step.quake) {
      // Any other traffic still proves Unity is alive, so it should hold the
      // stall hint and the watchdog off.
      _resetWatchdog();
    }
  }

  void _handlePose(Map<String, dynamic> msg) {
    final game = msg['game'] as String? ?? '';
    final index = (msg['index'] as num?)?.toInt() ?? -1;
    final ok = msg['ok'] as bool? ?? false;
    if (index < 0) return;
    final base = game == 'thedasher' ? 0 : 3;
    _record(base + index, ok);
    if (!mounted) return;
    setState(() {
      if (game == 'thedasher') {
        _dasherIdx = (index + 1).clamp(0, 2);
      } else if (game == 'quakeescape') {
        _quakeIdx = (index + 1).clamp(0, 1);
      }
    });
    _resetWatchdog();
  }

  /// Marks any not-yet-reported poses in [game] as skipped and moves the run
  /// forward. This is the single place a real `demo_done` message and the
  /// inactivity watchdog both land, so a stalled game can never strand the
  /// user — either one reaches the same outcome.
  void _advanceAfterGame(String game) {
    _stopWatchdog();
    if (game == 'thedasher' && _step == _Step.dasher) {
      for (var i = 0; i < 3; i++) {
        _record(i, false);
      }
      setState(() => _step = _Step.handoff);
      _startHandoffCountdown();
    } else if (game == 'quakeescape' && _step == _Step.quake) {
      for (var i = 0; i < 2; i++) {
        _record(3 + i, false);
      }
      setState(() => _step = _Step.result);
    }
  }

  /// Skips the REST OF THIS GAME, not one pose. Unity owns the beat sequence
  /// and the demo contract has no "skip one beat" message, so a per-pose skip
  /// here would only desync Flutter's counter from Unity's — Unity would keep
  /// waiting on the beat the user thought they had skipped. Leaving the game
  /// is something Flutter can actually do, so that is what the button does.
  void _skipCurrentGame() {
    if (_step == _Step.dasher) {
      _advanceAfterGame('thedasher');
    } else if (_step == _Step.quake) {
      _advanceAfterGame('quakeescape');
    }
  }

  void _startHandoffCountdown() {
    _countdown = _handoffSeconds;
    _handoffTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _countdown--);
      if (_countdown <= 0) {
        t.cancel();
        _goToQuake();
      }
    });
  }

  void _goToQuake() {
    _handoffTimer?.cancel();
    setState(() => _step = _Step.quake);
    sendToUnity('SceneRouter', 'SetDemo', '2');
    sendToUnity('SceneRouter', 'LoadGame', 'quakeescape');
    _resetWatchdog();
  }

  void _exit() {
    sendToUnity('SceneRouter', 'SetPaused', 'false');
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  // ── build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_unityMounted)
              EmbedUnity(onMessageFromUnity: _onUnityMessage),
            switch (_step) {
              _Step.intro => _IntroView(onStart: _startTour, onExit: _exit),
              _Step.permissionDenied =>
                _PermissionDeniedView(onRetry: _startTour, onExit: _exit),
              _Step.dasher => _GameOverlay(
                  gameTitle: 'THE DASHER',
                  overallIndex: _dasherIdx,
                  poseNumber: _dasherIdx + 1,
                  pose: _poses[_dasherIdx],
                  onSkip: _skipCurrentGame,
                  onExit: _exit,
                  poses: _poses,
                  stalled: _stalled,
                ),
              _Step.handoff => _HandoffView(
                  countdown: _countdown,
                  onSkipWait: _goToQuake,
                  poses: _poses,
                ),
              _Step.quake => _GameOverlay(
                  gameTitle: 'QUAKE ESCAPE',
                  overallIndex: 3 + _quakeIdx,
                  poseNumber: _quakeIdx + 1,
                  pose: _poses[3 + _quakeIdx],
                  onSkip: _skipCurrentGame,
                  onExit: _exit,
                  poses: _poses,
                  stalled: _stalled,
                ),
              _Step.result => _ResultView(poses: _poses, onExit: _exit),
            },
          ],
        ),
      ),
    );
  }
}

// ── Intro (screen 2) ───────────────────────────────────────────────────────

class _IntroView extends StatelessWidget {
  final VoidCallback onStart;
  final VoidCallback onExit;
  const _IntroView({required this.onStart, required this.onExit});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Container(
      color: KColors.appBg,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: r(24), vertical: r(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: onExit,
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      children: [
                        Icon(Icons.arrow_back_ios_new_rounded,
                            size: r(15), color: KColors.navyText),
                        SizedBox(width: r(4)),
                        Text('ออก',
                            style: thaiSans(
                                size: r(14),
                                weight: FontWeight.w600,
                                color: KColors.navyText)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text('ลองเล่น',
                      style: thaiSans(
                          size: r(13),
                          weight: FontWeight.w700,
                          color: KColors.navyText.withAlpha(140))),
                ],
              ),
              SizedBox(height: r(24)),
              Icon(Icons.sports_esports_rounded,
                  size: r(60), color: KColors.demoTourInk),
              SizedBox(height: r(14)),
              Text('คุณจะได้ลอง 5 ท่า',
                  textAlign: TextAlign.center,
                  style: thaiSans(
                      size: r(21),
                      weight: FontWeight.w800,
                      color: KColors.navyText)),
              SizedBox(height: r(22)),
              const _IntroRow(
                icon: Icons.directions_run_rounded,
                title: 'THE DASHER',
                subtitle: 'ก้าวหลบ · ก้าวเก็บ · เตะห่วง',
                count: '3',
              ),
              const _IntroRow(
                icon: Icons.location_city_rounded,
                title: 'QUAKE ESCAPE',
                subtitle: 'ยืนขาเดียว · เขย่งปลายเท้า',
                count: '2',
              ),
              const _IntroRow(
                icon: Icons.bar_chart_rounded,
                title: 'ดูผลสรุป',
                subtitle: 'รู้ผลทันที',
                count: '—',
              ),
              const Spacer(),
              Text('ยืนห่างจอประมาณ 2 เมตร ให้เห็นทั้งตัว',
                  textAlign: TextAlign.center,
                  style: thaiSans(
                      size: r(13),
                      weight: FontWeight.w600,
                      color: KColors.navyText.withAlpha(150))),
              SizedBox(height: r(14)),
              GestureDetector(
                onTap: onStart,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: r(52),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: KColors.demoTourGradient,
                    borderRadius: BorderRadius.circular(r(26)),
                  ),
                  child: Text('เริ่มเลย',
                      style: thaiSans(
                          size: r(17),
                          weight: FontWeight.w800,
                          color: Colors.white)),
                ),
              ),
              SizedBox(height: r(8)),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntroRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String count;
  const _IntroRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: r(9)),
      child: Row(
        children: [
          Icon(icon, size: r(22), color: KColors.demoTourInk),
          SizedBox(width: r(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: thaiSans(
                        size: r(15),
                        weight: FontWeight.w800,
                        color: KColors.navyText)),
                Text(subtitle,
                    style: thaiSans(
                        size: r(12),
                        weight: FontWeight.w500,
                        color: KColors.navyText.withAlpha(140))),
              ],
            ),
          ),
          Text(count,
              style: montserrat(
                  size: r(15),
                  weight: FontWeight.w800,
                  color: KColors.navyText.withAlpha(160))),
        ],
      ),
    );
  }
}

// ── Camera permission denied ────────────────────────────────────────────────

class _PermissionDeniedView extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onExit;
  const _PermissionDeniedView({required this.onRetry, required this.onExit});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Container(
      color: KColors.appBg,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: r(28)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.videocam_off_rounded,
                  size: r(56), color: KColors.orangeDark),
              SizedBox(height: r(16)),
              Text('ต้องอนุญาตให้ใช้กล้องเพื่อเล่นทดลองนะครับ',
                  textAlign: TextAlign.center,
                  style: thaiSans(
                      size: r(16),
                      weight: FontWeight.w700,
                      color: KColors.navyText)),
              SizedBox(height: r(24)),
              GestureDetector(
                onTap: onRetry,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: double.infinity,
                  height: r(50),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: KColors.demoTourGradient,
                    borderRadius: BorderRadius.circular(r(25)),
                  ),
                  child: Text('ลองอีกครั้ง',
                      style: thaiSans(
                          size: r(16),
                          weight: FontWeight.w800,
                          color: Colors.white)),
                ),
              ),
              SizedBox(height: r(12)),
              GestureDetector(
                onTap: onExit,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: double.infinity,
                  height: r(50),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: KColors.hairline, width: 1),
                    borderRadius: BorderRadius.circular(r(25)),
                  ),
                  child: Text('กลับหน้าหลัก',
                      style: thaiSans(
                          size: r(15),
                          weight: FontWeight.w700,
                          color: KColors.navyText)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Game overlay (screens 3 & 5 — identical chrome for both games) ─────────

class _GameOverlay extends StatelessWidget {
  final String gameTitle;
  final int overallIndex; // 0-based across all 5 poses
  final int poseNumber; // 1-based within this game
  final _PoseOutcome pose;
  final VoidCallback onSkip;
  final VoidCallback onExit;
  final List<_PoseOutcome> poses;

  /// Unity has gone quiet for a while — surface it instead of leaving the user
  /// holding a pose that nothing is listening to.
  final bool stalled;

  const _GameOverlay({
    required this.gameTitle,
    required this.overallIndex,
    required this.poseNumber,
    required this.pose,
    required this.onSkip,
    required this.onExit,
    required this.poses,
    required this.stalled,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Column(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black87, Colors.transparent],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.only(bottom: r(12)),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: onExit,
                        icon:
                            const Icon(Icons.close_rounded, color: Colors.white),
                      ),
                      Text(gameTitle,
                          style: thaiSans(
                              size: r(15),
                              weight: FontWeight.w800,
                              color: Colors.white)),
                      const Spacer(),
                      Text('${overallIndex + 1} / 5',
                          style: montserrat(
                              size: r(14),
                              weight: FontWeight.w700,
                              color: Colors.white70)),
                      SizedBox(width: r(16)),
                    ],
                  ),
                  SizedBox(height: r(6)),
                  _ProgressDots(poses: poses, currentIndex: overallIndex),
                ],
              ),
            ),
          ),
        ),
        const Spacer(),
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black87, Colors.transparent],
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(r(20), r(24), r(20), r(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('ท่าที่ $poseNumber',
                      style: thaiSans(
                          size: r(12),
                          weight: FontWeight.w700,
                          color: Colors.white60)),
                  SizedBox(height: r(2)),
                  Text(pose.name,
                      style: thaiSans(
                          size: r(20),
                          weight: FontWeight.w800,
                          color: Colors.white)),
                  SizedBox(height: r(4)),
                  Text(pose.hint,
                      style: thaiSans(
                          size: r(13),
                          weight: FontWeight.w500,
                          color: Colors.white70)),
                  SizedBox(height: r(10)),
                  Text(
                      stalled
                          ? 'ยังไม่ได้รับสัญญาณจากเกม — ข้ามได้เลยครับ'
                          : 'ยืนให้เห็นทั้งตัว แล้วทำท่าค้างไว้ ไม่ต้องรีบ',
                      style: thaiSans(
                          size: r(12),
                          weight: FontWeight.w600,
                          color: stalled ? KColors.orange : Colors.white54)),
                  SizedBox(height: r(12)),
                  GestureDetector(
                    onTap: onSkip,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      height: r(44),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: stalled ? KColors.orange : Colors.white54,
                            width: 1),
                        borderRadius: BorderRadius.circular(r(22)),
                      ),
                      child: Text('ข้ามเกมนี้',
                          style: thaiSans(
                              size: r(14),
                              weight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Shared 5-dot progress row — used on the dark video overlay (both games) and
/// on the light hand-off screen (`light: true`), so progress reads as one
/// continuous run across both games.
class _ProgressDots extends StatelessWidget {
  final List<_PoseOutcome> poses;
  final int currentIndex;
  final bool light;
  const _ProgressDots({
    required this.poses,
    required this.currentIndex,
    this.light = false,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final upcoming = light ? KColors.hairline : Colors.white24;
    final current = light ? KColors.blue : Colors.white;
    final skipped = light ? Colors.grey.shade400 : Colors.white38;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(poses.length, (i) {
        final p = poses[i];
        final Color color;
        if (p.recorded && p.ok) {
          color = KColors.teal;
        } else if (i == currentIndex) {
          color = current;
        } else if (p.recorded) {
          color = skipped;
        } else {
          color = upcoming;
        }
        return Container(
          margin: EdgeInsets.symmetric(horizontal: r(3)),
          width: r(7),
          height: r(7),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        );
      }),
    );
  }
}

// ── Hand-off (screen 4) ─────────────────────────────────────────────────────

class _HandoffView extends StatelessWidget {
  final int countdown;
  final VoidCallback onSkipWait;
  final List<_PoseOutcome> poses;
  const _HandoffView({
    required this.countdown,
    required this.onSkipWait,
    required this.poses,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Container(
      color: KColors.appBg,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: r(28), vertical: r(12)),
          child: Column(
            children: [
              _ProgressDots(poses: poses, currentIndex: 3, light: true),
              const Spacer(),
              Text('เยี่ยมมาก!',
                  style: thaiSans(
                      size: r(22),
                      weight: FontWeight.w800,
                      color: KColors.navyText)),
              SizedBox(height: r(6)),
              Text('จบ THE DASHER แล้ว',
                  style: thaiSans(
                      size: r(14),
                      weight: FontWeight.w600,
                      color: KColors.navyText.withAlpha(160))),
              SizedBox(height: r(20)),
              Text('$countdown',
                  style: montserrat(
                      size: r(56),
                      weight: FontWeight.w800,
                      color: KColors.demoTourInk)),
              SizedBox(height: r(6)),
              Text('ต่อไป',
                  style: thaiSans(
                      size: r(12),
                      weight: FontWeight.w700,
                      color: KColors.navyText.withAlpha(140))),
              Text('QUAKE ESCAPE',
                  style: thaiSans(
                      size: r(16),
                      weight: FontWeight.w800,
                      color: KColors.navyText)),
              const Spacer(),
              GestureDetector(
                onTap: onSkipWait,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: double.infinity,
                  height: r(48),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: KColors.hairline, width: 1),
                    borderRadius: BorderRadius.circular(r(24)),
                  ),
                  child: Text('ไปเลย',
                      style: thaiSans(
                          size: r(15),
                          weight: FontWeight.w700,
                          color: KColors.navyText)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Result (screen 6) ───────────────────────────────────────────────────────

class _ResultView extends StatelessWidget {
  final List<_PoseOutcome> poses;
  final VoidCallback onExit;
  const _ResultView({required this.poses, required this.onExit});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final okCount = poses.where((p) => p.ok).length;
    return Container(
      color: KColors.appBg,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: r(24), vertical: r(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('ผลสรุป',
                  textAlign: TextAlign.center,
                  style: thaiSans(
                      size: r(14),
                      weight: FontWeight.w700,
                      color: KColors.navyText.withAlpha(150))),
              SizedBox(height: r(10)),
              Text('$okCount/5',
                  textAlign: TextAlign.center,
                  style: montserrat(
                      size: r(40),
                      weight: FontWeight.w800,
                      color: KColors.teal)),
              Text('ทำได้สำเร็จ',
                  textAlign: TextAlign.center,
                  style: thaiSans(
                      size: r(13),
                      weight: FontWeight.w600,
                      color: KColors.navyText.withAlpha(140))),
              SizedBox(height: r(16)),
              Expanded(
                child: ListView.separated(
                  itemCount: poses.length,
                  separatorBuilder: (_, _) =>
                      Divider(height: 1, color: KColors.hairline),
                  itemBuilder: (context, i) {
                    final p = poses[i];
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: r(10)),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(p.name,
                                style: thaiSans(
                                    size: r(14),
                                    weight: FontWeight.w600,
                                    color: KColors.navyText)),
                          ),
                          if (p.ok)
                            Text('✓',
                                style: thaiSans(
                                    size: r(16),
                                    weight: FontWeight.w800,
                                    color: KColors.teal))
                          else
                            Text('ข้าม',
                                style: thaiSans(
                                    size: r(13),
                                    weight: FontWeight.w600,
                                    color: KColors.navyText.withAlpha(120))),
                        ],
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: r(8)),
              // The tour ends on the Info page — that is where a real session's
              // results live, so finishing there shows the judge/user the actual
              // reporting side of the platform rather than dumping them home.
              GestureDetector(
                onTap: () => context.go('/info'),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: r(50),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: KColors.demoTourGradient,
                    borderRadius: BorderRadius.circular(r(25)),
                  ),
                  child: Text('ดูผลการเล่น',
                      style: thaiSans(
                          size: r(16),
                          weight: FontWeight.w800,
                          color: Colors.white)),
                ),
              ),
              SizedBox(height: r(10)),
              GestureDetector(
                onTap: onExit,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: r(48),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: KColors.hairline, width: 1),
                    borderRadius: BorderRadius.circular(r(24)),
                  ),
                  child: Text('กลับหน้าหลัก',
                      style: thaiSans(
                          size: r(15),
                          weight: FontWeight.w700,
                          color: KColors.navyText)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
