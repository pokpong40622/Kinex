import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../state/onboarding_prefs.dart';
import '../state/emergency_contact.dart';
import '../state/tts_settings.dart';
import '../state/tutorial_prefs.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final w = MediaQuery.sizeOf(context).width;
    final introEnabled = ref.watch(introEnabledProvider);
    final tutorialEnabled = ref.watch(tutorialEnabledProvider);
    final ttsNarratorEnabled = ref.watch(ttsNarratorEnabledProvider);
    // Read once for initial field values — fields save on change via the
    // notifier directly, so this page doesn't need to re-render per keystroke.
    final contact = ref.read(emergencyContactProvider);
    return Scaffold(
      backgroundColor: KColors.appBg,
      appBar: AppBar(
        backgroundColor: KColors.appBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: KColors.navyText,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'ตั้งค่า',
          style: thaiSans(
            size: 20,
            weight: FontWeight.w700,
            color: KColors.navyText,
          ),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.04),
        children: [
          // Section: บัญชี
          Text(
            'บัญชี',
            style: thaiSans(
              size: 13,
              weight: FontWeight.w600,
              color: KColors.navyText.withAlpha(140),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: cardDecoration(radius: 16),
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.person_rounded,
                  label: 'บัญชีผู้ใช้',
                  onTap: null,
                ),
                const Divider(height: 1, indent: 56),
                _SettingsTile(
                  icon: Icons.info_outline_rounded,
                  label: 'เกี่ยวกับแอป',
                  onTap: null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Section: การแนะนำ (onboarding)
          Text(
            'การแนะนำ',
            style: thaiSans(
              size: 13,
              weight: FontWeight.w600,
              color: KColors.navyText.withAlpha(140),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: cardDecoration(radius: 16),
            child: SwitchListTile(
              value: introEnabled,
              onChanged: (v) => ref.read(introEnabledProvider.notifier).set(v),
              activeThumbColor: KColors.teal,
              contentPadding: EdgeInsets.symmetric(horizontal: w * 0.045),
              secondary: const Icon(
                Icons.slideshow_rounded,
                color: KColors.teal,
                size: 22,
              ),
              title: Text(
                'แสดงการแนะนำแอปตอนเปิด',
                style: thaiSans(
                  size: 16,
                  weight: FontWeight.w600,
                  color: KColors.navyText,
                ),
              ),
              subtitle: Text(
                'ปิดแล้วจะแสดงเฉพาะการเชื่อมต่อบลูทูธและการติดตั้งสายรัด EMG',
                style: thaiSans(
                  size: 12,
                  weight: FontWeight.w500,
                  color: KColors.navyText.withAlpha(130),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Section: โหมดสอนเล่น (The Dasher in-game tutorial toggle)
          Text(
            'โหมดสอนเล่น',
            style: thaiSans(
              size: 13,
              weight: FontWeight.w600,
              color: KColors.navyText.withAlpha(140),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: cardDecoration(radius: 16),
            child: SwitchListTile(
              value: tutorialEnabled,
              onChanged: (v) =>
                  ref.read(tutorialEnabledProvider.notifier).set(v),
              activeThumbColor: KColors.teal,
              contentPadding: EdgeInsets.symmetric(horizontal: w * 0.045),
              secondary: const Icon(
                Icons.school_rounded,
                color: KColors.teal,
                size: 22,
              ),
              title: Text(
                'โหมดสอนเล่น (กำลังพัฒนา)',
                style: thaiSans(
                  size: 16,
                  weight: FontWeight.w600,
                  color: KColors.navyText,
                ),
              ),
              subtitle: Text(
                'สอนท่าทางทั้ง 3 ท่าก่อนเริ่มเกม The Dasher',
                style: thaiSans(
                  size: 12,
                  weight: FontWeight.w500,
                  color: KColors.navyText.withAlpha(130),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Section: เสียงบรรยาย (Thai TTS narrator toggle)
          Text(
            'เสียงบรรยาย',
            style: thaiSans(
              size: 13,
              weight: FontWeight.w600,
              color: KColors.navyText.withAlpha(140),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: cardDecoration(radius: 16),
            child: SwitchListTile(
              value: ttsNarratorEnabled,
              onChanged: (v) =>
                  ref.read(ttsNarratorEnabledProvider.notifier).set(v),
              activeThumbColor: KColors.teal,
              contentPadding: EdgeInsets.symmetric(horizontal: w * 0.045),
              secondary: const Icon(
                Icons.record_voice_over_rounded,
                color: KColors.teal,
                size: 22,
              ),
              title: Text(
                'อ่านออกเสียง (ผู้บรรยาย)',
                style: thaiSans(
                  size: 16,
                  weight: FontWeight.w600,
                  color: KColors.navyText,
                ),
              ),
              subtitle: Text(
                'อ่านคำแนะนำสั้น ๆ ในการ์ดเรียนรู้และหน้าเรียนรู้ท่าทาง',
                style: thaiSans(
                  size: 12,
                  weight: FontWeight.w500,
                  color: KColors.navyText.withAlpha(130),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Section: ผู้ติดต่อฉุกเฉิน (emergency contact — auto-dialed on fall detection)
          Text(
            'ผู้ติดต่อฉุกเฉิน',
            style: thaiSans(
              size: 13,
              weight: FontWeight.w600,
              color: KColors.navyText.withAlpha(140),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: w * 0.045,
              vertical: w * 0.04,
            ),
            decoration: cardDecoration(radius: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ชื่อผู้ติดต่อ',
                  style: thaiSans(
                    size: 14,
                    weight: FontWeight.w600,
                    color: KColors.navyText,
                  ),
                ),
                const SizedBox(height: 6),
                _SettingsTextField(
                  initialValue: contact.name,
                  hint: 'กรอกชื่อ (ไม่บังคับ)',
                  keyboardType: TextInputType.name,
                  onChanged: (v) =>
                      ref.read(emergencyContactProvider.notifier).setName(v),
                ),
                const SizedBox(height: 16),
                Text(
                  'เบอร์โทรศัพท์',
                  style: thaiSans(
                    size: 14,
                    weight: FontWeight.w600,
                    color: KColors.navyText,
                  ),
                ),
                const SizedBox(height: 6),
                _SettingsTextField(
                  initialValue: contact.phone,
                  hint: 'กรอกเบอร์โทรศัพท์',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (v) =>
                      ref.read(emergencyContactProvider.notifier).setPhone(v),
                ),
                const SizedBox(height: 10),
                Text(
                  'หากตรวจพบการล้มระหว่างเล่นเกม ระบบจะโทรหาเบอร์นี้อัตโนมัติ',
                  style: thaiSans(
                    size: 12,
                    weight: FontWeight.w500,
                    color: KColors.navyText.withAlpha(130),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'ฟีเจอร์เพิ่มเติมเร็วๆ นี้',
              style: thaiSans(
                size: 13,
                weight: FontWeight.w500,
                color: KColors.navyText.withAlpha(100),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _SettingsTile({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: w * 0.045, vertical: 2),
      leading: Icon(icon, color: KColors.teal, size: 22),
      title: Text(
        label,
        style: thaiSans(
          size: 16,
          weight: FontWeight.w600,
          color: KColors.navyText,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: KColors.navyText,
        size: 22,
      ),
    );
  }
}

class _SettingsTextField extends StatelessWidget {
  final String initialValue;
  final String hint;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String> onChanged;

  const _SettingsTextField({
    required this.initialValue,
    required this.hint,
    required this.keyboardType,
    required this.onChanged,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: KColors.appBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: KColors.hairline, width: 1),
      ),
      child: TextFormField(
        initialValue: initialValue,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        style: thaiSans(
          size: 16,
          weight: FontWeight.w600,
          color: KColors.navyText,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: thaiSans(
            size: 15,
            weight: FontWeight.w500,
            color: KColors.navyText.withAlpha(120),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
