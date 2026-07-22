// EMG strap install guide + at-rest calibration.
//
// Hardware (2026-07): each leg has its OWN strap, printed with a "Left Center"
// / "Right Center" tab that sits on the middle of that thigh, and a block of 4
// electrodes that sits on the shin. So the guide is 3 photo steps per leg
// (6 total) followed by ONE calibration card.
//
// Calibration uses the CURRENT EMG stack (emg_session.dart + emg_pipeline.dart):
// both boards PUSH all four channels continuously over Nordic UART, so there is
// no START:<leg>:<ch> handshake and no per-channel polling — the old code that
// did that was stale against the firmware and has been removed. Both legs
// calibrate at the same time because both boards stream at once.
//
// Pop contract (home_page.dart depends on it):
//   finished  → context.pop(true)
//   skipped   → Navigator.pop(context, 'skipped')
//   dismissed → null
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../ble/ble_service.dart';
import '../../ble/emg_pipeline.dart';
import '../../ble/emg_session.dart';
import '../../models/daily_quest.dart';
import '../../models/muscle.dart';
import '../../state/quest_providers.dart';
import '../../theme/app_theme.dart';

/// Per-leg accent, matching the convention already used by the live-balance
/// page (left = indigo, right = orange) so a leg keeps the same colour
/// everywhere in the app.
Color _legAccent(LegSide leg) =>
    leg == LegSide.left ? KColors.indigo : const Color(0xFFFA7F00);

const Color _calibrationAccent = KColors.teal;

/// One photo instruction step. [order] is 1..3 WITHIN its leg — the raw
/// 1.1 / 2.3 numbering from the authoring sheet is never shown to the user.
class _InstallStep {
  final LegSide leg;
  final int order;
  final String image;
  final List<String> lines;
  const _InstallStep({
    required this.leg,
    required this.order,
    required this.image,
    required this.lines,
  });
}

const List<_InstallStep> _installSteps = [
  _InstallStep(
    leg: LegSide.left,
    order: 1,
    image: 'assets/images/hardware_guide/left1.jpg',
    lines: ['เว้นระยะห่างออกจากหัวเข่าประมาณ 1 สายรัด'],
  ),
  _InstallStep(
    leg: LegSide.left,
    order: 2,
    image: 'assets/images/hardware_guide/left2.jpg',
    lines: [
      'เอาป้าย Left Center อยู่ตรงกลางของต้นขาซ้าย',
      'ดึงให้ตึงและทำการรัดได้เลย',
    ],
  ),
  _InstallStep(
    leg: LegSide.left,
    order: 3,
    image: 'assets/images/hardware_guide/left3.jpg',
    lines: [
      'เอาจุด electrode ที่มีแถบ 4 อัน ไว้ตรงหน้าแข้ง',
      'ดึงให้ตึงและทำการรัดได้เลย',
    ],
  ),
  _InstallStep(
    leg: LegSide.right,
    order: 1,
    image: 'assets/images/hardware_guide/right1.jpg',
    lines: ['เว้นระยะห่างออกจากหัวเข่าประมาณ 1 สายรัด'],
  ),
  _InstallStep(
    leg: LegSide.right,
    order: 2,
    image: 'assets/images/hardware_guide/right2.jpg',
    lines: [
      'เอาป้าย Right Center อยู่ตรงกลางของต้นขาขวา',
      'ดึงให้ตึงและทำการรัดได้เลย',
    ],
  ),
  _InstallStep(
    leg: LegSide.right,
    order: 3,
    image: 'assets/images/hardware_guide/right3.jpg',
    lines: [
      'เอาจุด electrode ที่มีแถบ 4 อัน ไว้ตรงหน้าแข้ง',
      'ดึงให้ตึงและทำการรัดได้เลย',
    ],
  ),
];

/// Page index of the calibration card (welcome = 0, installs = 1..6).
const int _calibrationIndex = 7;

/// Total user-facing steps shown in the progress bar (6 install + calibration).
const int _totalSteps = 7;

class HardwareGuidePage extends ConsumerStatefulWidget {
  const HardwareGuidePage({super.key});

  @override
  ConsumerState<HardwareGuidePage> createState() => _HardwareGuidePageState();
}

class _HardwareGuidePageState extends ConsumerState<HardwareGuidePage> {
  int _step = 0;

  /// Shared with every other EMG page — do NOT reset these here, or navigating
  /// in from a page that already calibrated would throw the work away.
  Map<LegSide, EmgLegMetrics> get _legs => ref.read(emgSessionProvider).legs;

  final Map<LegSide, StreamSubscription<String>?> _subs = {};
  final Map<LegSide, bool> _listening = {
    LegSide.left: false,
    LegSide.right: false,
  };

  /// Legs the user has explicitly started calibrating on this screen. Used only
  /// to tell "waiting for the user to press start" apart from "counting down".
  final Set<LegSide> _running = {};

  DateTime _lastPaint = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
    // The countdown moves with the clock, not with incoming samples.
    _tick = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted && _step == _calibrationIndex) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    for (final s in _subs.values) {
      s?.cancel();
    }
    super.dispose();
  }

  // ---- BLE plumbing (same pattern as emg_live_balance_page) -----------------

  BleController _controllerFor(LegSide leg) => leg == LegSide.left
      ? ref.read(bleControllerProvider.notifier)
      : ref.read(legRBleProvider.notifier);

  bool _isConnected(LegSide leg) =>
      (leg == LegSide.left
          ? ref.read(bleControllerProvider).status
          : ref.read(legRBleProvider).status) ==
      BleStatus.connected;

  /// Attach/detach each leg's listener to match its connection state.
  void _sync() {
    for (final leg in LegSide.values) {
      final connected = _isConnected(leg);
      final listening = _listening[leg] ?? false;
      if (connected && !listening) {
        _subs[leg]?.cancel();
        _subs[leg] = _controllerFor(leg).incoming.listen((l) => _onLine(leg, l));
        _listening[leg] = true;
      } else if (!connected && listening) {
        _subs[leg]?.cancel();
        _subs[leg] = null;
        _listening[leg] = false;
      }
    }
  }

  void _onLine(LegSide leg, String line) {
    final values = parseEmgLine(line);
    if (values.length < kEmgChannels) return;
    _legs[leg]!.update(values);

    // Samples arrive far faster than the screen needs; cap the repaint rate.
    final now = DateTime.now();
    if (now.difference(_lastPaint) < kEmgPaintInterval) return;
    _lastPaint = now;
    if (mounted && _step == _calibrationIndex) setState(() {});
  }

  // ---- Calibration ---------------------------------------------------------

  /// Legs whose board is connected right now.
  List<LegSide> get _connectedLegs =>
      LegSide.values.where(_isConnected).toList();

  bool _calibrated(LegSide leg) => _legs[leg]!.calibrated;

  /// Starts (or restarts) the 30 s at-rest window on every connected leg that
  /// is not calibrated yet. Both boards stream at once, so both run together.
  Future<void> _startCalibration({bool includeCalibrated = false}) async {
    final targets = _connectedLegs
        .where((l) => includeCalibrated || !_calibrated(l))
        .toList();
    if (targets.isEmpty) return;
    for (final leg in targets) {
      _running.add(leg);
      await ref.read(emgSessionProvider).recalibrate(leg);
    }
    if (mounted) setState(() {});
  }

  Future<void> _redo(LegSide leg) async {
    _running.add(leg);
    await ref.read(emgSessionProvider).recalibrate(leg);
    if (mounted) setState(() {});
  }

  Future<void> _finish() async {
    // The daily EMG quest is about actually measuring, so it needs a leg that
    // really calibrated — finishing the guide with no board connected (which
    // the bottom button allows, so the user is never trapped) must not count.
    if (LegSide.values.any(_calibrated)) {
      await ref.read(dailyQuestsProvider.notifier).bump(QuestId.emgCheck);
    }
    if (!mounted) return;
    context.pop(true);
  }

  // ---- Navigation ----------------------------------------------------------

  void _next() {
    if (_step < _calibrationIndex) setState(() => _step++);
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  Future<void> _skipFlow() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('ข้ามการติดตั้ง EMG?',
            style: thaiSans(
                size: 18, weight: FontWeight.w700, color: KColors.navyText)),
        content: Text('สามารถตั้งค่าใหม่ได้ในภายหลัง',
            style: thaiSans(size: 15, color: const Color(0xFF5A6685))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('ยกเลิก',
                style: thaiSans(size: 15, color: KColors.navyText)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('ข้าม',
                style: thaiSans(
                    size: 15, weight: FontWeight.w700, color: KColors.purple)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) Navigator.pop(context, 'skipped');
  }

  // ---- Build ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    ref.listen(bleControllerProvider, (_, _) => _sync());
    ref.listen(legRBleProvider, (_, _) => _sync());

    final w = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(w * 0.06, w * 0.03, w * 0.06, w * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(w),
              SizedBox(height: w * 0.035),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: _body(w),
                ),
              ),
              SizedBox(height: w * 0.035),
              _bottom(w),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(double w) {
    if (_step == 0) return _WelcomeView(w: w, onSkip: _skipFlow);
    if (_step == _calibrationIndex) return _calibrationView(w);
    return _InstallView(w: w, step: _installSteps[_step - 1]);
  }

  // ---- Header: back + 7-step progress + skip -------------------------------

  Widget _header(double w) {
    final onWelcome = _step == 0;
    return Column(
      children: [
        Row(
          children: [
            SizedBox(
              width: w * 0.12,
              height: w * 0.12,
              child: onWelcome
                  ? const SizedBox.shrink()
                  : Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      elevation: 2,
                      shadowColor: const Color(0x22000000),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _back,
                        child: Icon(Icons.arrow_back_ios_new_rounded,
                            size: w * 0.05, color: KColors.navyText),
                      ),
                    ),
            ),
            Expanded(
              child: onWelcome
                  ? const SizedBox.shrink()
                  : Text(
                      'ขั้นตอนที่ $_step จาก $_totalSteps',
                      textAlign: TextAlign.center,
                      style: thaiSans(
                          size: w * 0.038,
                          weight: FontWeight.w700,
                          color: const Color(0xFF7A88A6)),
                    ),
            ),
            SizedBox(
              width: w * 0.12,
              child: onWelcome
                  ? const SizedBox.shrink()
                  : TextButton(
                      onPressed: _skipFlow,
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      child: Text('ข้าม',
                          style: thaiSans(
                              size: w * 0.038,
                              weight: FontWeight.w700,
                              color: KColors.purple)),
                    ),
            ),
          ],
        ),
        if (!onWelcome) ...[
          SizedBox(height: w * 0.025),
          _progressBar(w),
        ],
      ],
    );
  }

  /// Seven segments — three per leg in that leg's accent, then the calibration
  /// segment — so the user can see at a glance where they are and how far is
  /// left, and which leg the current segments belong to.
  Widget _progressBar(double w) {
    Color colorFor(int i) {
      if (i >= _installSteps.length) return _calibrationAccent;
      return _legAccent(_installSteps[i].leg);
    }

    return Row(
      children: List.generate(_totalSteps, (i) {
        final done = i < _step; // _step is 1-based over these segments
        final current = i == _step - 1;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: EdgeInsets.symmetric(horizontal: w * 0.006),
            height: current ? w * 0.022 : w * 0.014,
            decoration: BoxDecoration(
              color: done ? colorFor(i) : const Color(0xFFE1E6F2),
              borderRadius: BorderRadius.circular(w * 0.02),
            ),
          ),
        );
      }),
    );
  }

  // ---- Calibration card ----------------------------------------------------

  Widget _calibrationView(double w) {
    final connected = _connectedLegs;
    final anyRunning =
        connected.any((l) => _running.contains(l) && !_calibrated(l));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: w * 0.02),
        Center(
          child: Container(
            width: w * 0.22,
            height: w * 0.22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _calibrationAccent.withValues(alpha: 0.12),
            ),
            child: Icon(Icons.monitor_heart_rounded,
                color: _calibrationAccent, size: w * 0.12),
          ),
        ),
        SizedBox(height: w * 0.04),
        Text('เช็คกล้ามเนื้อ',
            textAlign: TextAlign.center,
            style: thaiSans(
                size: w * 0.062,
                weight: FontWeight.w700,
                color: KColors.navyText)),
        SizedBox(height: w * 0.025),
        Text(
          anyRunning
              ? 'กำลังวัดค่าพื้นฐาน — นั่งนิ่ง ๆ ผ่อนคลายขาทั้งสองข้าง อย่าเพิ่งขยับ'
              : 'นั่งบนเก้าอี้ วางเท้าราบกับพื้น ผ่อนคลายขาทั้งสองข้าง '
                  'แล้วกดปุ่มด้านล่างเพื่อวัดค่าพื้นฐาน ${kCalibrationSeconds.toInt()} วินาที',
          textAlign: TextAlign.center,
          style: thaiSans(
              size: w * 0.042,
              weight: FontWeight.w400,
              color: const Color(0xFF5A6685)),
        ),
        SizedBox(height: w * 0.05),
        for (final leg in LegSide.values) ...[
          _legStatusCard(w, leg),
          SizedBox(height: w * 0.035),
        ],
        if (connected.length < LegSide.values.length) _connectNotice(w),
      ],
    );
  }

  Widget _legStatusCard(double w, LegSide leg) {
    final accent = _legAccent(leg);
    final m = _legs[leg]!;
    final connected = _isConnected(leg);
    final calibrated = m.calibrated;
    final running = _running.contains(leg) && !calibrated;
    final remaining = m.calibrationRemaining ?? 0;
    final waiting = running && remaining >= kCalibrationSeconds;
    final progress =
        ((kCalibrationSeconds - remaining) / kCalibrationSeconds).clamp(0.0, 1.0);

    Widget status;
    if (!connected) {
      status = Text('ยังไม่ได้เชื่อมต่อบอร์ดของขาข้างนี้',
          style: thaiSans(size: w * 0.038, color: const Color(0xFF8C99B5)));
    } else if (calibrated) {
      final at = m.calibratedAt;
      status = Row(
        children: [
          Icon(Icons.check_circle_rounded,
              color: KColors.teal, size: w * 0.055),
          SizedBox(width: w * 0.02),
          Expanded(
            child: Text(
              at == null
                  ? 'ปรับเทียบแล้ว พร้อมใช้งาน'
                  : 'ปรับเทียบแล้ว · ${DateFormat('d MMM HH:mm').format(at)}',
              style: thaiSans(
                  size: w * 0.038,
                  weight: FontWeight.w700,
                  color: KColors.tealDark),
            ),
          ),
          TextButton(
            onPressed: () => _redo(leg),
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: Text('วัดใหม่',
                style: thaiSans(
                    size: w * 0.038,
                    weight: FontWeight.w700,
                    color: KColors.purple)),
          ),
        ],
      );
    } else if (running) {
      status = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            waiting
                ? 'กำลังรอสัญญาณจากบอร์ด…'
                : 'เหลืออีก ${remaining.ceil()} วินาที',
            style: thaiSans(
                size: w * 0.042, weight: FontWeight.w800, color: accent),
          ),
          SizedBox(height: w * 0.02),
          ClipRRect(
            borderRadius: BorderRadius.circular(w * 0.02),
            child: LinearProgressIndicator(
              value: waiting ? null : progress,
              minHeight: w * 0.022,
              backgroundColor: accent.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
        ],
      );
    } else {
      status = Text('ยังไม่ได้ปรับเทียบ',
          style: thaiSans(size: w * 0.038, color: const Color(0xFF8C99B5)));
    }

    return Container(
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(w * 0.05),
        border: Border.all(
            color: connected
                ? accent.withValues(alpha: 0.45)
                : const Color(0xFFE1E6F2),
            width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LegChip(w: w, leg: leg),
          SizedBox(height: w * 0.03),
          status,
        ],
      ),
    );
  }

  Widget _connectNotice(double w) {
    final leftOn = _isConnected(LegSide.left);
    final rightOn = _isConnected(LegSide.right);
    final leftState = ref.watch(bleControllerProvider);
    final rightState = ref.watch(legRBleProvider);
    final busy = [leftState, rightState].any((s) =>
        s.status == BleStatus.scanning || s.status == BleStatus.connecting);

    final missing = <String>[
      if (!leftOn) 'ขาซ้าย',
      if (!rightOn) 'ขาขวา',
    ].join(' และ ');

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(w * 0.045),
        border: Border.all(color: const Color(0xFFFFB300)),
      ),
      child: Column(
        children: [
          Text('ยังไม่ได้เชื่อมต่อบอร์ด EMG ($missing)',
              textAlign: TextAlign.center,
              style: thaiSans(
                  size: w * 0.038,
                  weight: FontWeight.w700,
                  color: const Color(0xFFE65100))),
          SizedBox(height: w * 0.025),
          OutlinedButton.icon(
            onPressed: busy
                ? null
                : () {
                    if (!leftOn) {
                      ref.read(bleControllerProvider.notifier).quickConnect();
                    }
                    if (!rightOn) {
                      ref.read(legRBleProvider.notifier).quickConnect();
                    }
                  },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFFFB300)),
              padding: EdgeInsets.symmetric(
                  horizontal: w * 0.05, vertical: w * 0.025),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(w * 0.04)),
            ),
            icon: busy
                ? SizedBox(
                    width: w * 0.04,
                    height: w * 0.04,
                    child: const CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFFE65100)),
                  )
                : Icon(Icons.bluetooth_searching_rounded,
                    size: w * 0.045, color: const Color(0xFFE65100)),
            label: Text(busy ? 'กำลังค้นหา…' : 'เชื่อมต่ออุปกรณ์',
                style: thaiSans(
                    size: w * 0.038,
                    weight: FontWeight.w700,
                    color: const Color(0xFFE65100))),
          ),
        ],
      ),
    );
  }

  // ---- Bottom action -------------------------------------------------------

  Widget _bottom(double w) {
    if (_step == 0) return _primaryButton(w, 'เริ่มติดตั้ง', _next);
    if (_step < _calibrationIndex) return _primaryButton(w, 'ถัดไป', _next);

    final connected = _connectedLegs;
    final running =
        connected.any((l) => _running.contains(l) && !_calibrated(l));
    final pending = connected.where((l) => !_calibrated(l)).toList();

    if (running) {
      final left = connected
          .where((l) => !_calibrated(l))
          .map((l) => _legs[l]!.calibrationRemaining ?? 0)
          .fold<double>(0, (a, b) => b > a ? b : a);
      return _primaryButton(
          w, 'กำลังปรับเทียบ… ${left.ceil()} วินาที', null);
    }
    if (pending.isNotEmpty) {
      return _primaryButton(w, 'เริ่มปรับเทียบ (${kCalibrationSeconds.toInt()} วินาที)',
          _startCalibration);
    }
    if (connected.isEmpty) {
      // No board to calibrate — let the user leave rather than trapping them.
      return _primaryButton(w, 'เสร็จสิ้น', _finish);
    }
    return _primaryButton(w, 'เสร็จสิ้น พร้อมใช้งาน', _finish);
  }

  Widget _primaryButton(double w, String label, VoidCallback? onTap) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: w * 0.155,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled ? KColors.purple : const Color(0xFFC3CBDD),
          borderRadius: BorderRadius.circular(w * 0.078),
          boxShadow: enabled
              ? const [
                  BoxShadow(
                      color: Color(0x406F1BC8),
                      blurRadius: 18,
                      offset: Offset(0, 8))
                ]
              : null,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: w * 0.05),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label,
                style: thaiSans(
                    size: w * 0.05,
                    weight: FontWeight.w700,
                    color: Colors.white)),
          ),
        ),
      ),
    );
  }
}

// ── Welcome ─────────────────────────────────────────────────────────────────

class _WelcomeView extends StatelessWidget {
  final double w;
  final VoidCallback onSkip;
  const _WelcomeView({required this.w, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: w * 0.06),
        Container(
          width: w * 0.58,
          height: w * 0.58,
          decoration: BoxDecoration(
            color: KColors.purple,
            borderRadius: BorderRadius.circular(w * 0.09),
            boxShadow: [
              BoxShadow(
                  color: KColors.purple.withValues(alpha: 0.35),
                  blurRadius: 30,
                  offset: const Offset(0, 14)),
            ],
          ),
          padding: EdgeInsets.all(w * 0.1),
          child: Image.asset('assets/images/kinex_logo.png', fit: BoxFit.contain),
        ),
        SizedBox(height: w * 0.08),
        Text('ติดตั้งสายรัด EMG',
            textAlign: TextAlign.center,
            style: thaiSans(
                size: w * 0.068,
                weight: FontWeight.w700,
                color: KColors.navyText)),
        SizedBox(height: w * 0.03),
        Text(
          'ใส่สายรัดขาซ้ายและขาขวาข้างละ 3 ขั้นตอน '
          'แล้วเช็คกล้ามเนื้อก่อนเริ่มใช้งาน',
          textAlign: TextAlign.center,
          style: thaiSans(
              size: w * 0.043,
              weight: FontWeight.w400,
              color: const Color(0xFF5A6685)),
        ),
        SizedBox(height: w * 0.06),
        OutlinedButton(
          onPressed: onSkip,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: KColors.purple.withValues(alpha: 0.5)),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(w * 0.05)),
            padding:
                EdgeInsets.symmetric(horizontal: w * 0.08, vertical: w * 0.028),
          ),
          child: Text('ข้ามขั้นตอนนี้',
              style: thaiSans(
                  size: w * 0.04,
                  weight: FontWeight.w600,
                  color: KColors.purple)),
        ),
      ],
    );
  }
}

// ── One photo instruction step ──────────────────────────────────────────────

class _InstallView extends StatelessWidget {
  final double w;
  final _InstallStep step;
  const _InstallView({required this.w, required this.step});

  @override
  Widget build(BuildContext context) {
    final accent = _legAccent(step.leg);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: _LegChip(w: w, leg: step.leg, order: step.order)),
        SizedBox(height: w * 0.035),
        // The photo carries the instruction, so it gets the whole width.
        // `contain` (not `cover`) so the printed Left/Right Center tab is never
        // cropped out — the shin photo is 4:3 while the others are square.
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF2F4FA),
              borderRadius: BorderRadius.circular(w * 0.06),
              border: Border.all(color: accent.withValues(alpha: 0.35), width: 2),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 24,
                    offset: Offset(0, 12)),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(step.image, fit: BoxFit.contain),
          ),
        ),
        SizedBox(height: w * 0.05),
        for (final line in step.lines) ...[
          _Bullet(w: w, accent: accent, text: line),
          SizedBox(height: w * 0.025),
        ],
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  final double w;
  final Color accent;
  final String text;
  const _Bullet({required this.w, required this.accent, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(top: w * 0.018),
          width: w * 0.025,
          height: w * 0.025,
          decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
        ),
        SizedBox(width: w * 0.03),
        Expanded(
          child: Text(text,
              style: thaiSans(
                  size: w * 0.048,
                  weight: FontWeight.w600,
                  color: KColors.navyText)),
        ),
      ],
    );
  }
}

/// "ขาซ้าย · ขั้นตอนที่ 1/3" (or just "ขาซ้าย" when [order] is null), in that
/// leg's accent so the user never loses track of which leg they are on.
class _LegChip extends StatelessWidget {
  final double w;
  final LegSide leg;
  final int? order;
  const _LegChip({required this.w, required this.leg, this.order});

  @override
  Widget build(BuildContext context) {
    final accent = _legAccent(leg);
    final label = order == null
        ? 'ขา${leg.thaiName}'
        : 'ขา${leg.thaiName} · ขั้นตอนที่ $order/3';
    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: w * 0.045, vertical: w * 0.018),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(w * 0.06),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.accessibility_new_rounded, size: w * 0.045, color: accent),
          SizedBox(width: w * 0.02),
          Text(label,
              style: thaiSans(
                  size: w * 0.042, weight: FontWeight.w800, color: accent)),
        ],
      ),
    );
  }
}
