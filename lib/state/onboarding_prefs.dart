import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether the software-intro slides show as part of the first-entry onboarding
/// popup flow. Persisted; **default ON**. When OFF, the onboarding flow shows only
/// the Bluetooth-connect + installation popups (the intro slides are skipped).
///
/// Per the design decision: while this is ON the intro shows on EVERY launch
/// (there is no separate first-run "seen" flag) — the toggle is the sole control.
final introEnabledProvider =
    StateNotifierProvider<IntroEnabledNotifier, bool>(
        (ref) => IntroEnabledNotifier());

class IntroEnabledNotifier extends StateNotifier<bool> {
  static const _key = 'onboarding_intro_enabled';

  // Start ON; asynchronously replace with the stored value once prefs load.
  IntroEnabledNotifier() : super(true) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getBool(_key);
    if (stored != null) state = stored;
  }

  Future<void> set(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}
