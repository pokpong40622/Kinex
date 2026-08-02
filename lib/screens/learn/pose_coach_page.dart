// Live camera practice ("ฝึกกับกล้อง") for ANY of the 9 learn-library poses.
// Reached from the pose wizard (every page) and from the camera button on each
// library card.
//
// Division of labour (CLAUDE.md + docs/adr/2026-08-02-pose-coach-all-poses.md):
// Unity owns the pose detection and decides which coaching cue is active;
// Flutter owns every Thai string and all speech. Unity therefore sends cue
// *IDs* only (it has no Thai font in these runtime-built UIs), and this screen
// maps them to Thai text + TTS.
//
// Wire protocol (Unity -> Flutter), emitted only when something CHANGES:
//   {"type":"coach_ready","pose":"tandem_stand","mode":"hold","target":10,
//    "sides":"per-side"}
//   {"type":"coach","cue":"hold","side":"left","reps":1,"target":10,
//    "hold":0.62,"angle":0}
//   {"type":"coach_done","reps":20,"target":20}
// Parsing is deliberately lenient — every field has a fallback and malformed
// payloads are ignored, never thrown.
//
// Flutter -> Unity, before loading the scene:
//   sendToUnity('SceneRouter', 'SetCoach', '<poseId>')
//   sendToUnity('SceneRouter', 'LoadGame', 'motionlab')
// and on leaving: sendToUnity('SceneRouter', 'SetCoach', '')
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_embed_unity/flutter_embed_unity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../data/pose_library.dart';
import '../../services/tts_service.dart';
import '../../state/learn_progress.dart';
import '../../state/tts_settings.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive.dart';
import 'pose_success_page.dart';

/// Thai line for the cue ids ANY pose may emit (ADR "Global" table). Short and
/// imperative — every line stays under ~2 seconds of speech at the narrator's
/// slow rate, because these are spoken via TTS.
const coachGlobalCues = <String, String>{
  'get_ready': 'เตรียมตัว ยืนหน้ากล้อง',
  'not_in_frame': 'ขยับให้เห็นทั้งตัวในกล้อง',
  'stand_tall': 'ยืนให้ลำตัวตรง',
  'hold': 'ดีมาก ค้างไว้',
  'steady': 'ทรงตัวให้นิ่ง',
  'go_slower': 'ช้าลงอีกนิด',
  'rep_good': 'ดีมาก',
  'switch_side': 'สลับไปอีกข้าง',
  'done': 'เสร็จแล้ว เก่งมาก',
};

/// Thai line for the cue ids only ONE pose emits (ADR "Pose-specific" table).
/// A few ids (`lift_more`, `too_high`, `lower_slow`, `knee_straight`) appear
/// under more than one pose and need different wording per pose — which is
/// exactly why this is keyed by pose first.
const coachPoseCues = <String, Map<String, String>>{
  'sit_to_stand': {
    'sit_first': 'นั่งลงบนเก้าอี้ก่อน',
    'stand_up': 'ลุกขึ้นยืน',
    'sit_down': 'ค่อย ๆ นั่งลง',
    'knees_behind_toes': 'อย่าให้เข่าเลยปลายเท้า',
  },
  'seated_knee_lift': {
    'lift_knee': 'ยกเข่าขึ้น',
    'lift_more': 'ยกเข่าให้สูงอีกนิด',
    'lower_slow': 'วางขาลงช้า ๆ',
  },
  'hip_abduction': {
    'knee_straight': 'เหยียดเข่าให้ตรง',
    'lift_more': 'กางขาออกด้านข้างอีกนิด',
    'too_high': 'ยกสูงเกินไป ลดลงนิด',
    'lower_slow': 'ลดขาลงช้า ๆ',
  },
  'hip_extension': {
    'extend_more': 'เหยียดขาไปด้านหลังอีกนิด',
    'too_high': 'ยกสูงเกินไป ลดลงนิด',
    'no_arch': 'อย่าแอ่นหลัง',
    'knee_straight': 'เหยียดเข่าให้ตรง',
    'lower_slow': 'ลดขาลงช้า ๆ',
  },
  'narrow_base_stand': {
    'on_heels': 'ลงน้ำหนักบนส้นเท้า',
    'on_toes': 'เขย่งขึ้นบนปลายเท้า',
    'phase_done': 'ผ่านแล้ว เตรียมท่าต่อไป',
  },
  'tandem_stand': {
    'feet_in_line': 'วางเท้าต่อกันเป็นเส้นตรง',
  },
  'single_leg_balance': {
    'lift_foot': 'ยกเท้าขึ้นจากพื้น',
  },
  'tandem_walk': {
    // Unity only checks that the ankles stay on ONE line — it does NOT verify
    // heel-to-toe contact (single fixed camera, see the ADR's reduced scope).
    // So this line must say "stay on the line", not "your foot placement is wrong".
    'heel_to_toe': 'เดินให้เท้าอยู่ในแนวเส้นตรง',
    'walk_forward': 'เดินไปข้างหน้าช้า ๆ',
    'step_good': 'ดีมาก ก้าวต่อไป',
  },
  'side_walk': {
    'step_side': 'ก้าวไปด้านข้างหนึ่งก้าว',
    'feet_together': 'ชิดเท้าเข้าหากัน',
    'step_good': 'ดีมาก ก้าวต่อไป',
  },
};

/// Thai text for one Unity cue id: pose-specific wording wins, then the global
/// wording, then the "get ready" line. Never returns blank and never returns a
/// raw cue id — an id Unity invents that Flutter has not been told about still
/// reads as a sensible instruction.
String coachCueText(String poseId, String cue) {
  return coachPoseCues[poseId]?[cue] ??
      coachGlobalCues[cue] ??
      coachGlobalCues['get_ready']!;
}

/// Cue priority. Progress cues (3) may interrupt an in-flight correction and
/// ignore the minimum gap; corrections (1) never interrupt anything.
int _priorityOf(String cue) => switch (cue) {
      'done' || 'switch_side' || 'phase_done' => 3,
      'rep_good' || 'step_good' => 2,
      _ => 1,
    };

/// Corrections that are only advice get a calm colour; safety/progress cues
/// get a louder one.
Color _colorOf(String cue) => switch (cue) {
      'rep_good' || 'step_good' || 'hold' || 'done' || 'phase_done' =>
        KColors.greenDark,
      'too_high' ||
      'not_in_frame' ||
      'no_arch' ||
      'knees_behind_toes' ||
      'go_slower' ||
      'steady' =>
        const Color(0xFFEF6C00),
      'switch_side' => KColors.blue,
      _ => KColors.navyText,
    };

/// Which leg / phase Unity is currently judging. `phase0` / `phase1` are the
/// narrow-base-stand phases, not sides.
String coachSideLabel(String side) => switch (side) {
      'left' => 'ขาซ้าย',
      'right' => 'ขาขวา',
      'phase0' => 'ช่วงส้นเท้า',
      'phase1' => 'ช่วงเขย่งปลายเท้า',
      _ => '',
    };

class PoseCoachPage extends ConsumerStatefulWidget {
  final String poseId;
  const PoseCoachPage({super.key, required this.poseId});

  @override
  ConsumerState<PoseCoachPage> createState() => _PoseCoachPageState();
}

class _PoseCoachPageState extends ConsumerState<PoseCoachPage> {
  // ---- Throttling constants. Naively speaking every cue makes the app babble
  // over itself, so: one utterance at a time, a floor between utterances, and
  // a longer floor before the same cue repeats. ----
  static const _minGap = Duration(milliseconds: 2500);
  static const _repeatGap = Duration(seconds: 6);

  /// The user has tapped เริ่ม — until then we show the start overlay and touch
  /// neither the camera nor Unity.
  bool _started = false;
  PermissionStatus _cameraStatus = PermissionStatus.denied;
  bool _checked = false;

  String _cue = '';
  String _side = '';
  int _reps = 0;
  int _target = 10;
  // 'reps' (n/target counter) or 'hold' (fill ring). Unity tells us via
  // coach_ready; if that never arrives we stay on the counter.
  String _mode = 'reps';
  double _hold = 0;
  bool _done = false;
  int _doneReps = 0;

  // TTS bookkeeping.
  String _lastSpokenCue = '';
  DateTime _lastSpokeAt = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _busyUntil = DateTime.fromMillisecondsSinceEpoch(0);
  int _speakingPriority = 0;
  Timer? _retryTimer;

  LearnPose? get _pose => poseById(widget.poseId);

  @override
  void initState() {
    super.initState();
    // Portrait, BOTH ways up — the tablet gets rotated 180° depending on which
    // side the charging cable is on.
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  /// Start overlay's เริ่ม button: ask for the camera, then hand over to Unity.
  Future<void> _begin() async {
    setState(() => _started = true);
    final status = await Permission.camera.request();
    if (!mounted) return;
    setState(() {
      _cameraStatus = status;
      _checked = true;
    });
    if (!status.isGranted) return;
    // A cue suppressed by the gap would otherwise never be spoken (Unity only
    // re-sends on change), so retry the currently-active cue periodically.
    _retryTimer ??= Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => _trySpeak(_cue),
    );
    // Warm case: Unity is already running, so send immediately (it won't
    // re-emit unity_ready). Cold case: this is a no-op and the unity_ready
    // handshake below covers it.
    WidgetsBinding.instance.addPostFrameCallback((_) => _startCoach());
  }

  void _startCoach() {
    sendToUnity('SceneRouter', 'SetCoach', widget.poseId);
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
    if (!mounted) return;

    if (type == 'coach_ready') {
      setState(() {
        _mode = msg['mode'] as String? ?? _mode;
        _target = (msg['target'] as num?)?.toInt() ?? _target;
      });
      return;
    }
    if (type == 'coach_done') {
      setState(() {
        _done = true;
        _doneReps = (msg['reps'] as num?)?.toInt() ?? _doneReps;
      });
      // Finishing in front of the camera is what counts as "practised" — the
      // success screen's X/9 reads this, not the weaker "opened the wizard"
      // signal in learnProgressProvider.
      ref.read(posePracticedProvider.notifier).markPracticed(widget.poseId);
      return;
    }
    if (type != 'coach') return;

    final cue = msg['cue'] as String? ?? '';
    setState(() {
      _cue = cue;
      _side = msg['side'] as String? ?? _side;
      _reps = (msg['reps'] as num?)?.toInt() ?? _reps;
      _target = (msg['target'] as num?)?.toInt() ?? _target;
      _hold = ((msg['hold'] as num?)?.toDouble() ?? _hold).clamp(0.0, 1.0);
      _doneReps = _reps;
    });
    _trySpeak(cue);
  }

  /// Speaks a cue only if the throttling rules allow it. On-screen text is
  /// never gated by this — it always shows the live cue.
  void _trySpeak(String cue) {
    if (cue.isEmpty) return;
    final text = coachCueText(widget.poseId, cue);
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

  /// "ฝึกอีกครั้ง" on the success screen — clear the finished session and ask
  /// Unity for a fresh one. Reloading the scene is what resets Unity's own
  /// counters, so this is the same call the screen makes on entry.
  void _retry() {
    setState(() {
      _done = false;
      _reps = 0;
      _doneReps = 0;
      _hold = 0;
      _cue = '';
      _side = '';
    });
    _lastSpokenCue = '';
    _startCoach();
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
    // Only talk to Unity / the narrator if we ever started them — an unknown
    // pose or an abandoned start overlay never touched either.
    if (_started) {
      // Leave coach mode off for whatever loads the Motion Lab next, and make
      // sure nothing keeps talking after the user has left this screen.
      sendToUnity('SceneRouter', 'SetCoach', '');
      ref.read(ttsServiceProvider).stop();
    }
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pose = _pose;
    if (pose == null) {
      return _CoachMessage('ไม่พบท่านี้', onExit: _exit);
    }
    if (!_started) {
      return _StartOverlay(pose: pose, onStart: _begin, onExit: _exit);
    }
    if (!_checked) {
      return _CoachMessage('กำลังเปิดกล้อง…', onExit: _exit);
    }
    if (!_cameraStatus.isGranted) {
      return _CoachMessage(
        'ต้องอนุญาตให้ใช้กล้องเพื่อฝึกท่านี้นะครับ',
        onExit: _exit,
      );
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
                  CoachHud(
                    mode: _mode,
                    reps: _reps,
                    target: _target,
                    hold: _hold,
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
                    child: CoachCueCard(poseId: widget.poseId, cue: _cue),
                  ),
                ],
              ),
            ),
            if (_done)
              PoseSuccessView(
                pose: pose,
                reps: _doneReps,
                mode: _mode,
                onExit: _exit,
                onRetry: _retry,
              ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen message (camera opening / permission refused / unknown pose)
/// with an always-visible way back out.
class _CoachMessage extends StatelessWidget {
  final String text;
  final VoidCallback onExit;
  const _CoachMessage(this.text, {required this.onExit});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(context.r(12)),
              child: Row(children: [_ExitButton(onTap: onExit)]),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.r(28)),
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    style: thaiSans(
                      size: context.r(18),
                      weight: FontWeight.w700,
                      color: Colors.white,
                    ),
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

/// Calm "here is what you are about to do" screen shown before the camera is
/// touched: pose name, one line of instruction, one big เริ่ม button.
class _StartOverlay extends StatelessWidget {
  final LearnPose pose;
  final VoidCallback onStart;
  final VoidCallback onExit;
  const _StartOverlay({
    required this.pose,
    required this.onStart,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    final color = pose.category.color;
    return Scaffold(
      backgroundColor: KColors.appBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(context.r(12)),
              child: Row(
                children: [_ExitButton(onTap: onExit, light: false)],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: context.r(24)),
                child: Column(
                  children: [
                    SizedBox(height: context.r(12)),
                    Container(
                      width: context.r(88),
                      height: context.r(88),
                      decoration: BoxDecoration(
                        color: color.withAlpha(26),
                        shape: BoxShape.circle,
                        border: Border.all(color: color.withAlpha(70)),
                      ),
                      child: Icon(
                        Icons.videocam_rounded,
                        color: color,
                        size: context.r(42),
                      ),
                    ),
                    SizedBox(height: context.r(18)),
                    Text(
                      pose.name,
                      textAlign: TextAlign.center,
                      style: thaiSans(
                        size: context.r(23),
                        weight: FontWeight.w800,
                        color: KColors.navyText,
                      ),
                    ),
                    SizedBox(height: context.r(8)),
                    Text(
                      pose.subtitle,
                      textAlign: TextAlign.center,
                      style: thaiSans(
                        size: context.r(14),
                        weight: FontWeight.w600,
                        color: KColors.navyText.withAlpha(160),
                      ),
                    ),
                    SizedBox(height: context.r(20)),
                    Container(
                      padding: EdgeInsets.all(context.r(16)),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(context.r(18)),
                        border: Border.all(color: KColors.hairline),
                      ),
                      child: Text(
                        'ยืนให้เห็นทั้งตัวในกล้อง แล้วทำตามคำแนะนำบนหน้าจอ',
                        textAlign: TextAlign.center,
                        style: thaiSans(
                          size: context.r(15),
                          weight: FontWeight.w700,
                          color: KColors.navyText,
                        ),
                      ),
                    ),
                    SizedBox(height: context.r(24)),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.r(24),
                0,
                context.r(24),
                context.r(24),
              ),
              child: GestureDetector(
                onTap: onStart,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: double.infinity,
                  height: context.r(64),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(context.r(32)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: context.r(30),
                      ),
                      SizedBox(width: context.r(8)),
                      Text(
                        'เริ่ม',
                        style: thaiSans(
                          size: context.r(22),
                          weight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
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

/// Big, obvious close control. 52dp so it clears the 48dp minimum target on
/// every device the `r()` clamp allows.
class _ExitButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool light;
  const _ExitButton({required this.onTap, this.light = true});

  @override
  Widget build(BuildContext context) {
    final size = context.r(52);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: light ? Colors.black.withValues(alpha: 0.55) : Colors.white,
          borderRadius: BorderRadius.circular(context.r(16)),
          border: light ? null : Border.all(color: KColors.hairline),
        ),
        child: Icon(
          Icons.close_rounded,
          color: light ? Colors.white : KColors.navyText,
          size: context.r(26),
        ),
      ),
    );
  }
}

/// Exit control + progress read-out. `mode: 'hold'` shows a fill ring driven by
/// [hold]; anything else shows the `n/target` rep counter.
class CoachHud extends StatelessWidget {
  final String mode;
  final int reps;
  final int target;
  final double hold;
  final String side;
  final VoidCallback onExit;
  const CoachHud({
    super.key,
    required this.mode,
    required this.reps,
    required this.target,
    required this.hold,
    required this.side,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    final label = coachSideLabel(side);
    return Padding(
      padding: EdgeInsets.all(context.r(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ExitButton(onTap: onExit),
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
              mainAxisSize: MainAxisSize.min,
              children: [
                if (mode == 'hold')
                  _HoldRing(hold: hold, target: target)
                else
                  Text(
                    '$reps/$target',
                    style: thaiSans(
                      size: context.r(22),
                      weight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                if (label.isNotEmpty) ...[
                  SizedBox(height: context.r(2)),
                  Text(
                    label,
                    style: thaiSans(
                      size: context.r(13),
                      weight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Circular hold progress — the seconds banked so far out of the target,
/// with the ring itself as the at-a-glance signal.
class _HoldRing extends StatelessWidget {
  final double hold;
  final int target;
  const _HoldRing({required this.hold, required this.target});

  @override
  Widget build(BuildContext context) {
    final size = context.r(56);
    final seconds = (hold.clamp(0.0, 1.0) * target).round();
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: hold.clamp(0.0, 1.0),
              strokeWidth: context.r(5),
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation(KColors.greenLight),
            ),
          ),
          FittedBox(
            child: Text(
              '$seconds/$target',
              style: thaiSans(
                size: context.r(15),
                weight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The one live coaching line, big enough to read from across the room. Works
/// with the narrator switched off — this is never gated on TTS.
class CoachCueCard extends StatelessWidget {
  final String poseId;
  final String cue;
  const CoachCueCard({super.key, required this.poseId, required this.cue});

  @override
  Widget build(BuildContext context) {
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
        coachCueText(poseId, cue),
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

