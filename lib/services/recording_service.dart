import 'dart:developer' as dev;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screen_recording/flutter_screen_recording.dart';
import 'package:gal/gal.dart';

/// Thin wrapper around flutter_screen_recording + gal.
/// All failures are swallowed so a recording problem never crashes a test.
class RecordingService {
  bool _recording = false;

  Future<void> start(String label) async {
    if (_recording) return;
    try {
      final started = await FlutterScreenRecording.startRecordScreen(
        label,
        titleNotification: 'กำลังบันทึกการทดสอบ',
        messageNotification: 'Kinex กำลังบันทึกวิดีโอ',
      );
      _recording = started;
    } catch (e) {
      dev.log('recording unavailable: $e', name: 'RecordingService');
    }
  }

  Future<void> stopAndSave() async {
    if (!_recording) return;
    _recording = false;
    try {
      final path = await FlutterScreenRecording.stopRecordScreen;
      if (path.isNotEmpty) {
        await Gal.putVideo(path, album: 'Kinex');
      }
    } catch (e) {
      dev.log('stopAndSave failed: $e', name: 'RecordingService');
    }
  }
}

final recordingServiceProvider = Provider<RecordingService>(
  (_) => RecordingService(),
);
