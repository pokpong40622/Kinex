import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/assessment_session.dart';
import '../../data/emg_repository.dart';
import '../../models/emg_metrics.dart';
import '../../models/muscle.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive.dart';
import '../../widgets/assessment_button.dart';
import '../../widgets/assessment_scaffold.dart';

class MvcCalibrationPage extends ConsumerStatefulWidget {
  const MvcCalibrationPage({super.key});

  @override
  ConsumerState<MvcCalibrationPage> createState() => _MvcCalibrationPageState();
}

class _MvcCalibrationPageState extends ConsumerState<MvcCalibrationPage> {
  int _index = 0;
  final Map<Muscle, double> _peaks = {};
  bool _measuring = false;
  int _secondsLeft = 3;
  Timer? _timer;
  bool _saving = false;

  static const _baseMicrovolt = {
    Muscle.vl: 320.0,
    Muscle.bf: 280.0,
    Muscle.ta: 210.0,
    Muscle.gcm: 350.0,
  };

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Muscle get _currentMuscle => Muscle.values[_index];
  bool get _recorded => _peaks.containsKey(_currentMuscle);

  void _startMeasuring() {
    setState(() {
      _measuring = true;
      _secondsLeft = 3;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) {
        t.cancel();
        _recordPeak();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _recordPeak() {
    final rand = math.Random();
    final base = _baseMicrovolt[_currentMuscle]!;
    final jitter = base * 0.05 * (rand.nextDouble() * 2 - 1);
    final peak = (base + jitter).roundToDouble();
    setState(() {
      _peaks[_currentMuscle] = peak;
      _measuring = false;
      _secondsLeft = 3;
    });
  }

  Future<void> _goNext() async {
    if (_index < Muscle.values.length - 1) {
      setState(() => _index++);
    } else {
      await _finish();
    }
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    final c = MvcCalibration(
      peakMicrovolts: Map.of(_peaks),
      calibratedAt: DateTime.now(),
    );
    await ref.read(emgRepositoryProvider).saveCalibration(c);
    ref.read(assessmentSessionProvider.notifier).setMvcCalibration(c);
    ref.invalidate(mvcCalibrationProvider);
    if (!mounted) return;
    // Inside the assessment flow → continue to the summary. Launched standalone
    // (e.g. the Info page "ไปปรับเทียบ" button) → just return; the value is saved.
    final inAssessment = ref.read(assessmentSessionProvider).allMovementTestsComplete;
    if (inAssessment) {
      context.go('/assessment/summary');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกค่า MVC แล้ว')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final muscle = _currentMuscle;
    final recorded = _recorded;

    Widget? bottomWidget;
    if (_saving) {
      bottomWidget = const AssessmentButton(label: 'กำลังบันทึก...', onTap: null);
    } else if (recorded) {
      bottomWidget = AssessmentButton(
        label: _index < Muscle.values.length - 1 ? 'ถัดไป' : 'เสร็จสิ้น',
        icon: _index < Muscle.values.length - 1
            ? Icons.arrow_forward_rounded
            : Icons.check_circle_rounded,
        onTap: _goNext,
      );
    }

    return AssessmentScaffold(
      title: 'ปรับเทียบกล้ามเนื้อ (MVC)',
      body: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: context.r(20),
          vertical: context.r(8),
        ),
        children: [
          // Mock-mode notice
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.r(16),
              vertical: context.r(10),
            ),
            decoration: cardDecoration(
              radius: 12,
              color: KColors.teal.withAlpha(28),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: context.r(18),
                  color: KColors.tealDark,
                ),
                SizedBox(width: context.r(8)),
                Expanded(
                  child: Text(
                    'ขณะนี้ยังไม่ได้เชื่อมต่อ EMG — ใช้ค่าจำลอง',
                    style: thaiSans(
                      size: context.r(13),
                      color: KColors.tealDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: context.r(16)),
          // Progress label
          Center(
            child: Text(
              'กล้ามเนื้อ ${_index + 1}/4',
              style: thaiSans(
                size: context.r(15),
                weight: FontWeight.w700,
                color: KColors.navyText.withAlpha(160),
              ),
            ),
          ),
          SizedBox(height: context.r(24)),
          // Main card
          Container(
            padding: EdgeInsets.all(context.r(24)),
            decoration: cardDecoration(),
            child: Column(
              children: [
                Text(
                  'เกร็งกล้ามเนื้อ ${muscle.thaiName} (${muscle.code})'
                  ' ให้สุดแรง\nแล้วค้างไว้ ~3 วินาที',
                  textAlign: TextAlign.center,
                  style: thaiSans(
                    size: context.r(18),
                    weight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: context.r(36)),
                if (_measuring) ...[
                  // Countdown ring
                  SizedBox(
                    width: context.r(120),
                    height: context.r(120),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox.expand(
                          child: CircularProgressIndicator(
                            value: (3 - _secondsLeft) / 3,
                            strokeWidth: context.r(8),
                            color: KColors.teal,
                            backgroundColor: KColors.teal.withAlpha(40),
                          ),
                        ),
                        Text(
                          '$_secondsLeft',
                          style: montserrat(
                            size: context.r(44),
                            weight: FontWeight.w900,
                            color: KColors.tealDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: context.r(16)),
                  Text(
                    'กำลังวัด...',
                    style: thaiSans(size: context.r(16), color: KColors.tealDark),
                  ),
                ] else if (recorded) ...[
                  // Result display
                  Icon(
                    Icons.check_circle_rounded,
                    size: context.r(64),
                    color: KColors.greenDark,
                  ),
                  SizedBox(height: context.r(12)),
                  Text(
                    '${_peaks[muscle]!.toStringAsFixed(0)} µV ✓',
                    style: montserrat(
                      size: context.r(30),
                      weight: FontWeight.w900,
                      color: KColors.greenDark,
                    ),
                  ),
                ] else ...[
                  // วัดค่า button — large circle tap target
                  GestureDetector(
                    onTap: _startMeasuring,
                    child: Container(
                      width: context.r(120),
                      height: context.r(120),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [KColors.teal, KColors.blue],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: KColors.teal.withAlpha(100),
                            blurRadius: context.r(16),
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'วัดค่า',
                          style: thaiSans(
                            size: context.r(22),
                            weight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                SizedBox(height: context.r(8)),
              ],
            ),
          ),
          SizedBox(height: context.r(24)),
        ],
      ),
      bottom: bottomWidget,
    );
  }
}
