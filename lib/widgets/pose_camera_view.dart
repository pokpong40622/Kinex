import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../rep_counters/pose_frame.dart';
import 'pose_skeleton_painter.dart';

/// Opens the front camera, runs ML Kit pose detection on each frame, and
/// reports a [PoseFrame] via [onFrame]. Optionally overlays the detected
/// skeleton on the live preview.
class PoseCameraView extends StatefulWidget {
  final void Function(PoseFrame frame) onFrame;
  final bool showSkeleton;
  final bool mirror;

  const PoseCameraView({
    super.key,
    required this.onFrame,
    this.showSkeleton = true,
    this.mirror = true,
  });

  @override
  State<PoseCameraView> createState() => _PoseCameraViewState();
}

class _PoseCameraViewState extends State<PoseCameraView> {
  CameraController? _controller;
  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
      model: PoseDetectionModel.base,
    ),
  );

  bool _busy = false;
  PoseFrame? _lastFrame;
  Size _imageSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final cameras = await availableCameras();
    final front = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    final controller = CameraController(
      front,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup:
          Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
    );

    await controller.initialize();
    if (!mounted) {
      await controller.dispose();
      return;
    }

    setState(() => _controller = controller);
    await controller.startImageStream(_onCameraImage);
  }

  void _onCameraImage(CameraImage image) {
    if (_busy) return;
    _busy = true;
    _processImage(image).whenComplete(() => _busy = false);
  }

  Future<void> _processImage(CameraImage image) async {
    final controller = _controller;
    if (controller == null) return;

    final inputImage = _toInputImage(image, controller.description);
    if (inputImage == null) return;

    final poses = await _poseDetector.processImage(inputImage);
    if (!mounted || poses.isEmpty) return;

    final frame = _toPoseFrame(poses.first);
    // ML Kit returns landmarks in the ROTATED image space, so for a 90°/270°
    // sensor the coordinate dimensions are swapped vs the raw CameraImage.
    final rotation =
        InputImageRotationValue.fromRawValue(controller.description.sensorOrientation) ??
            InputImageRotation.rotation0deg;
    final swap = rotation == InputImageRotation.rotation90deg ||
        rotation == InputImageRotation.rotation270deg;
    setState(() {
      _lastFrame = frame;
      _imageSize = swap
          ? Size(image.height.toDouble(), image.width.toDouble())
          : Size(image.width.toDouble(), image.height.toDouble());
    });
    widget.onFrame(frame);
  }

  /// Converts a [CameraImage] to ML Kit's [InputImage], using the camera
  /// sensor orientation for rotation.
  ///
  /// NOTE: rotation handling for `CameraImage` planes/formats is fiddly and
  /// device-dependent (especially on Android, where sensor orientation and
  /// device orientation combine). This covers the common portrait front-
  /// camera case; if the skeleton overlay looks rotated/mirrored on a real
  /// device, adjust [InputImageRotation] here.
  InputImage? _toInputImage(CameraImage image, CameraDescription camera) {
    final rotation =
        InputImageRotationValue.fromRawValue(camera.sensorOrientation) ??
            InputImageRotation.rotation0deg;

    final format = Platform.isAndroid
        ? InputImageFormat.nv21
        : InputImageFormat.bgra8888;

    if (image.planes.isEmpty) return null;

    // Android nv21 (and iOS bgra8888) are delivered as a single contiguous
    // plane that ML Kit expects.
    final bytes = image.planes.length == 1
        ? image.planes.first.bytes
        : _concatenatePlanes(image.planes);

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final builder = BytesBuilder();
    for (final plane in planes) {
      builder.add(plane.bytes);
    }
    return builder.toBytes();
  }

  /// Builds a [PoseFrame] of length [Lm.count], using ML Kit landmark type
  /// ordinals as indices (BlazePose ordering matches [Lm] constants).
  PoseFrame _toPoseFrame(Pose pose) {
    final landmarks = List<Landmark>.filled(Lm.count, const Landmark(0, 0, 0, 0));
    for (final entry in pose.landmarks.entries) {
      final index = entry.key.index;
      if (index < Lm.count) {
        final lm = entry.value;
        landmarks[index] = Landmark(lm.x, lm.y, lm.z, lm.likelihood);
      }
    }
    return PoseFrame(landmarks);
  }

  @override
  void dispose() {
    final controller = _controller;
    if (controller != null && controller.value.isStreamingImages) {
      controller.stopImageStream();
    }
    controller?.dispose();
    _poseDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(controller),
        if (widget.showSkeleton)
          CustomPaint(
            painter: PoseSkeletonPainter(
              frame: _lastFrame,
              imageSize: _imageSize,
              mirror: widget.mirror,
            ),
          ),
      ],
    );
  }
}
