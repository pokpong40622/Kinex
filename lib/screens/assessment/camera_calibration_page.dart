import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../rep_counters/pose_frame.dart';
import '../../rep_counters/rep_counter.dart';
import '../../rep_counters/rep_counter_factory.dart';
import '../../theme/app_theme.dart';
import '../../widgets/assessment_button.dart';
import '../../widgets/assessment_scaffold.dart';
import '../../widgets/pose_camera_view.dart';

enum _PermissionState { checking, denied, granted }

/// Helps the user position themselves in front of the camera before the real
/// timed test starts. Counting and calibration happen on
/// [LiveAssessmentPage] — this screen only confirms the body is visible.
class CameraCalibrationPage extends ConsumerStatefulWidget {
  final String testId;
  const CameraCalibrationPage({super.key, required this.testId});

  @override
  ConsumerState<CameraCalibrationPage> createState() =>
      _CameraCalibrationPageState();
}

class _CameraCalibrationPageState extends ConsumerState<CameraCalibrationPage> {
  static const _goodFramesNeeded = 5;

  _PermissionState _permission = _PermissionState.checking;
  late final RepCounter _counter;
  int _goodFrames = 0;

  @override
  void initState() {
    super.initState();
    _counter = createRepCounter(widget.testId);
    _requestPermission();
  }

  Future<void> _requestPermission() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    setState(() {
      _permission =
          status.isGranted ? _PermissionState.granted : _PermissionState.denied;
    });
  }

  void _onFrame(PoseFrame frame) {
    _counter.add(frame);
    final good = _counter.guidance == null;
    setState(() {
      _goodFrames = good ? _goodFrames + 1 : 0;
    });
  }

  bool get _ready => _goodFrames >= _goodFramesNeeded;

  @override
  Widget build(BuildContext context) {
    return AssessmentScaffold(
      title: 'จัดท่าให้พร้อม',
      body: _body(),
      bottom: _permission == _PermissionState.granted
          ? AssessmentButton(
              label: 'เริ่มจับเวลา',
              onTap: _ready
                  ? () => context.go('/assessment/test/${widget.testId}/live')
                  : null,
            )
          : null,
    );
  }

  Widget _body() {
    switch (_permission) {
      case _PermissionState.checking:
        return const Center(child: CircularProgressIndicator());
      case _PermissionState.denied:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.videocam_off_outlined,
                    size: 56, color: KColors.navyText),
                const SizedBox(height: 16),
                Text(
                  'จำเป็นต้องใช้กล้องเพื่อทำแบบทดสอบนี้\nกรุณาอนุญาตการใช้กล้องในตั้งค่า',
                  textAlign: TextAlign.center,
                  style: thaiSans(size: 18, weight: FontWeight.w700),
                ),
                const SizedBox(height: 24),
                AssessmentButton(
                  label: 'ย้อนกลับ',
                  primary: false,
                  onTap: () => context.pop(),
                ),
              ],
            ),
          ),
        );
      case _PermissionState.granted:
        return Stack(
          fit: StackFit.expand,
          children: [
            PoseCameraView(onFrame: _onFrame),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(160),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _counter.guidance != null
                      ? 'ปรับตำแหน่ง: ${_counter.guidance}'
                      : 'พร้อม! มองเห็นร่างกายชัดเจน',
                  textAlign: TextAlign.center,
                  style: thaiSans(
                    size: 22,
                    weight: FontWeight.w800,
                    color: _counter.guidance != null
                        ? const Color(0xFFFFB74D)
                        : Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
    }
  }
}
