import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Info ("ข้อมูล") page view mode.
/// false = Normal — simple balance summary for the elderly user.
/// true  = Advanced — clinical per-muscle %MVC / CCI / raw EMG for a therapist.
/// In-memory (resets each launch); the default is the gentle Normal view.
final infoAdvancedProvider = StateProvider<bool>((_) => false);
