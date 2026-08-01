// Live camera practice ("โค้ชสด") for ONE learn-library pose: hip_abduction —
// กางสะโพกออกด้านข้าง (ท่ายืน). Reached from the last page of the pose wizard.
//
// Division of labour (CLAUDE.md): Unity owns the pose detection and decides
// which coaching cue is active; Flutter owns every Thai string and all speech.
// Unity therefore sends cue *IDs* only (it has no Thai font in these
// runtime-built UIs), and this screen maps them to Thai text + TTS.
//
// Wire protocol (Unity -> Flutter), emitted only when something CHANGES:
//   {"type":"coach_ready"}
//   {"type":"coach","cue":"lift_more","side":"left","reps":3,"target":10,"angle":18}
//   {"type":"coach_done","reps":20,"target":20}
// Parsing is deliberately lenient — every field has a fallback.
//
// Flutter -> Unity, before loading the scene:
//   sendToUnity('SceneRouter', 'SetCoach', 'hip_abduction')
//   sendToUnity('SceneRouter', 'LoadGame', 'motionlab')
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_embed_unity/flutter_embed_unity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../services/tts_service.dart';
import '../../state/tts_settings.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive.dart';

/// Thai line spoken + shown for each Unity cue id. Short and imperative — every
/// line stays under ~2 seconds of speech at the narrator's slow rate.
const _cueText = <String, String>{
  'not_in_frame': 'ยืนให้เห็นทั้งตัวในกล้อง',
  'stand_tall': 'ยืนให้ลำตัวตรง',
  'knee_straight': 'เหยียดเข่าให้ตรง',
  'lift_more': 'ยกขาออกด้านข้างอีกนิด',
  'too_high': 'ยกสูงเกินไป ลดลงนิดหนึ่ง',
  'hold': 'ดีมาก ค้างไว้',
  'lower_slow': 'ลดขาลงช้า ๆ',
  'rep_good': 'ดีมาก',
  'switch_side': 'สลับไปอีกข้าง',
  'done': 'เสร็จแล้ว เก่งมาก',
};

/// Cue priority. Progress cues (3) may interrupt an in-flight correction and
/// ignore the minimum gap; corrections (1) never interrupt anything.
int _priorityOf(String cue) => switch (cue) {
      'done' || 'switch_side' => 3,
      'rep_good' => 2,
      _ => 1,
    };

/// Corrections that are only advice get a calm colour; safety/progress cues
/// get a louder one.
Color _colorOf(String cue) => switch (cue) {
      'rep_good' || 'hold' || 'done' => KColors.greenDark,
      'too_high' || 'not_in_frame' => const Color(0xFFEF6C00),
      'switch_side' => KColors.blue,
      _ => KColors.navyText,
    };

class PoseCoachPage extends ConsumerStatefulWidget {
  const PoseCoachPage({super.key});

  @override
  ConsumerState<PoseCoachPage> createState() => _PoseCoachPageState();
}

class _PoseCoachPageState extends ConsumerState<PoseCoachPage> {
  // ---- Throttling constants. Naively speaking every cue makes the app babble
  // over itself, so: one utterance at a time, a floor between utterances, and
  // a longer floor before the same cue repeats. ----
  static const _minGap = Duration(milliseconds: 2500);
  static const _repeatGap = Duration(seconds: 6);

  PermissionStatus _cameraStatus = PermissionStatus.denied;
  bool _checked = false;

  String _cue = '';
  String _side = '';
  int _reps = 0;
  int _target = 10;
  bool _done = false;
  int _doneReps = 0;

  // TTS bookkeeping.
  String _lastSpokenCue = '';
  DateTime _lastSpokeAt = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _busyUntil = DateTime.fromMillisecondsSinceEpoch(0);
  int _speakingPriority = 0;
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    // Portrait, BOTH ways up — the tablet gets rotated 180° depending on which
    // side the charging cable is on.
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _requestCameraPermission();
    // A cue suppressed by the gap would otherwise never be spoken (Unity only
    // re-sends on change), so retry the currently-active cue periodically.
    _retryTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => _trySpeak(_cue),
    );
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    setState(() {
      _cameraStatus = status;
      _checked = true;
    });
    // Warm case: Unity is already running, so send immediately (it won't
    // re-emit unity_ready). Cold case: this is a no-op and the unity_ready
    // handshake below covers it.
    if (status.isGranted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startCoach());
    }
  }

  void _startCoach() {
    sendToUnity('SceneRouter', 'SetCoach', 'hip_abduction');
    sendToUnity('SceneRouter', 'LoadGame', 'motionlab');
  }

  void _onUnityMessage(String data) {
    if (data.contains('unity_ready')) {
      _startCoach();
      return;
    }
    if (data.contains('"exit"')) {
      _exit();
      return;
    }
    if (!data.contains('"coach')) return;

    Map<String, dynamic> msg;
    try {
      msg = jsonDecode(data) as Map<String, dynamic>;
    } catch (_) {
      return; // ignore malformed / non-JSON payloads
    }

    final type = msg['type'] as String? ?? '';
    if (type == 'coach_done') {
      if (!mounted) return;
      setState(() {
        _done = true;
        _doneReps = (msg['reps'] as num?)?.toInt() ?? _doneReps;
      });
      return;
    }
    if (type != 'coach') return;

    final cue = msg['cue'] as String? ?? '';
    if (!mounted) return;
    setState(() {
      _cue = cue;
      _side = msg['side'] as String? ?? _side;
      _reps = (msg['reps'] as num?)?.toInt() ?? _reps;
      _target = (msg['target'] as num?)?.toInt() ?? _target;
      _doneReps = _reps;
    });
    _trySpeak(cue);
  }

  /// Speaks a cue only if the throttling rules allow it. On-screen text is
  /// never gated by this — it always shows the live cue.
  void _trySpeak(String cue) {
    if (cue.isEmpty) return;
    final text = _cueText[cue];
    if (text == null) return;
    if (!ref.read(ttsNarratorEnabledProvider)) return;

    final now = DateTime.now();
    final priority = _priorityOf(cue);
    // Never interrupt an in-flight utterance with an equal-or-lower priority one.
    if (now.isBefore(_busyUntil) && priority <= _speakingPriority) return;
    // Minimum gap between utterances (progress cues are exempt).
    if (priority < 3 && now.difference(_lastSpokeAt) < _minGap) return;
    // Don't nag with the same cue too often.
    if (cue == _lastSpokenCue && now.difference(_lastSpokeAt) < _repeatGap) {
      return;
    }

    _lastSpokenCue = cue;
    _lastSpokeAt = now;
    _speakingPriority = priority;
    // flutter_tts gives no reliable completion signal through TtsService, so
    // estimate how long this line occupies the speaker from its length.
    final ms = (600 + 70 * text.length).clamp(1200, 2800);
    _busyUntil = now.add(Duration(milliseconds: ms));
    ref.read(ttsServiceProvider).speak(text);
  }

  void _exit() {
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/learn');
    }
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    // Leave coach mode off for whatever loads the Motion Lab next, and make
    // sure nothing keeps talking after the user has left this screen.
    sendToUnity('SceneRouter', 'SetCoach', '');
    ref.read(ttsServiceProvider).stop();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) {
      return const _CoachMessage('กำลังเปิดกล้อง…');
    }
    if (!_cameraStatus.isGranted) {
      return const _CoachMessage('ต้องอนุญาตให้ใช้กล้องเพื่อฝึกท่านี้นะครับ');
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            EmbedUnity(onMessageFromUnity: _onUnityMessage),
            SafeArea(
              child: Column(
                children: [
                  _TopBar(
                    reps: _reps,
                    target: _target,
                    side: _side,
                    onExit: _exit,
                  ),
                  const Spacer(),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      context.r(16),
                      0,
                      context.r(16),
                      context.r(20),
                    ),
                    child: _CueCard(cue: _cue),
                  ),
                ],
              ),
            ),
            if (_done) _DoneOverlay(reps: _doneReps, onExit: _exit),
          ],
        ),
      ),
    );
  }
}

class _CoachMessage extends StatelessWidget {
  final String text;
  const _CoachMessage(this.text);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text(text, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}

/// Exit + rep counter + which leg is being worked.
class _TopBar extends StatelessWidget {
  final int reps;
  final int target;
  final String side;
  final VoidCallback onExit;
  const _TopBar({
    required this.reps,
    required this.target,
    required this.side,
    required this.onExit,
  });

  String get _sideLabel => switch (side) {
        'left' => 'ขาซ้าย',
        'right' => 'ขาขวา',
        _ => 'เลือกขาที่จะเริ่ม',
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(context.r(12)),
      child: Row(
        children: [
          GestureDetector(
            onTap: onExit,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: context.r(46),
              height: context.r(46),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(context.r(14)),
              ),
              child: Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: context.r(24),
              ),
            ),
          ),
          const Spacer(),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.r(14),
              vertical: context.r(9),
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(context.r(16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$reps/$target',
                  style: thaiSans(
                    size: context.r(22),
                    weight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _sideLabel,
                  style: thaiSans(
                    size: context.r(13),
                    weight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The one live coaching line, big enough to read from across the room. Works
/// with the narrator switched off — this is never gated on TTS.
class _CueCard extends StatelessWidget {
  final String cue;
  const _CueCard({required this.cue});

  @override
  Widget build(BuildContext context) {
    final text = _cueText[cue] ?? 'เตรียมตัว ยืนหน้ากล้อง';
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: context.r(20),
        vertical: context.r(22),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(context.r(22)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: thaiSans(
          size: context.r(26),
          weight: FontWeight.w800,
          color: _colorOf(cue),
        ),
      ),
    );
  }
}

class _DoneOverlay extends StatelessWidget {
  final int reps;
  final VoidCallback onExit;
  const _DoneOverlay({required this.reps, required this.onExit});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.72),
      alignment: Alignment.center,
      child: Padding(
        padding: EdgeInsets.all(context.r(28)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: KColors.greenDark,
              size: context.r(78),
            ),
            SizedBox(height: context.r(16)),
            Text(
              'ฝึกครบแล้ว เก่งมาก',
              style: thaiSans(
                size: context.r(24),
                weight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            SizedBox(height: context.r(6)),
            Text(
              'ทำได้ $reps ครั้ง',
              style: thaiSans(
                size: context.r(16),
                weight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
            SizedBox(height: context.r(24)),
            GestureDetector(
              onTap: onExit,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.r(28),
                  vertical: context.r(14),
                ),
                decoration: BoxDecoration(
                  color: KColors.greenDark,
                  borderRadius: BorderRadius.circular(context.r(26)),
                ),
                child: Text(
                  'เสร็จสิ้น',
                  style: thaiSans(
                    size: context.r(17),
                    weight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
