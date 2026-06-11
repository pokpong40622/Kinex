import 'package:flutter/material.dart';
import '../rep_counters/pose_frame.dart';

/// Draws a BlazePose skeleton (teal bones + magenta joints) over a camera
/// preview, scaling from image coordinates to the canvas size.
class PoseSkeletonPainter extends CustomPainter {
  final PoseFrame? frame;
  final Size imageSize;
  final bool mirror;
  final double minLikelihood;

  PoseSkeletonPainter({
    required this.frame,
    required this.imageSize,
    this.mirror = true,
    this.minLikelihood = 0.5,
  });

  /// Pairs of landmark indices forming the skeleton's bones.
  static const _bones = [
    [Lm.leftShoulder, Lm.rightShoulder],
    [Lm.leftShoulder, Lm.leftElbow],
    [Lm.leftElbow, Lm.leftWrist],
    [Lm.rightShoulder, Lm.rightElbow],
    [Lm.rightElbow, Lm.rightWrist],
    [Lm.leftShoulder, Lm.leftHip],
    [Lm.rightShoulder, Lm.rightHip],
    [Lm.leftHip, Lm.rightHip],
    [Lm.leftHip, Lm.leftKnee],
    [Lm.leftKnee, Lm.leftAnkle],
    [Lm.rightHip, Lm.rightKnee],
    [Lm.rightKnee, Lm.rightAnkle],
  ];

  /// All joints referenced by [_bones], for drawing dots.
  static final _joints = {for (final bone in _bones) ...bone}.toList();

  @override
  void paint(Canvas canvas, Size size) {
    final f = frame;
    if (f == null || imageSize.width == 0 || imageSize.height == 0) return;

    // The preview is stretched to fill the view, so stretch the landmark
    // (rotated-image) coords the same way (independent X/Y) to stay aligned.
    final scaleX = size.width / imageSize.width;
    final scaleY = size.height / imageSize.height;

    final bonePaint = Paint()
      ..color = Colors.teal
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final jointPaint = Paint()
      ..color = Colors.pinkAccent
      ..style = PaintingStyle.fill;

    Offset? pointOf(int index) {
      final lm = f[index];
      if (lm.likelihood < minLikelihood) return null;
      var x = lm.x * scaleX;
      final y = lm.y * scaleY;
      if (mirror) x = size.width - x;
      return Offset(x, y);
    }

    for (final bone in _bones) {
      final p1 = pointOf(bone[0]);
      final p2 = pointOf(bone[1]);
      if (p1 == null || p2 == null) continue;
      canvas.drawLine(p1, p2, bonePaint);
    }

    for (final joint in _joints) {
      final p = pointOf(joint);
      if (p == null) continue;
      canvas.drawCircle(p, 5, jointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant PoseSkeletonPainter oldDelegate) =>
      !identical(oldDelegate.frame, frame) ||
      oldDelegate.imageSize != imageSize ||
      oldDelegate.mirror != mirror ||
      oldDelegate.minLikelihood != minLikelihood;
}
