import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The contact auto-dialed when Unity reports a fall (`sos_call` message)
/// during a game. Configured by the user in Settings.
class EmergencyContact {
  final String name;
  final String phone;

  const EmergencyContact({this.name = '', this.phone = ''});

  bool get isSet => phone.trim().isNotEmpty;

  EmergencyContact copyWith({String? name, String? phone}) => EmergencyContact(
        name: name ?? this.name,
        phone: phone ?? this.phone,
      );
}

final emergencyContactProvider =
    StateNotifierProvider<EmergencyContactNotifier, EmergencyContact>(
        (ref) => EmergencyContactNotifier());

class EmergencyContactNotifier extends StateNotifier<EmergencyContact> {
  static const _nameKey = 'emergency_contact_name';
  static const _phoneKey = 'emergency_contact_phone';

  // Start empty; asynchronously replace with the stored value once prefs load.
  EmergencyContactNotifier() : super(const EmergencyContact()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = EmergencyContact(
      name: prefs.getString(_nameKey) ?? '',
      phone: prefs.getString(_phoneKey) ?? '',
    );
  }

  Future<void> setName(String name) async {
    state = state.copyWith(name: name);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name);
  }

  Future<void> setPhone(String phone) async {
    state = state.copyWith(phone: phone);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_phoneKey, phone);
  }
}
