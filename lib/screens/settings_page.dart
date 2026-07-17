import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../state/onboarding_prefs.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final w = MediaQuery.sizeOf(context).width;
    final introEnabled = ref.watch(introEnabledProvider);
    return Scaffold(
      backgroundColor: KColors.cardBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: KColors.navyText),
          onPressed: () => context.pop(),
        ),
        title: Text('ตั้งค่า',
            style: thaiSans(
                size: 20,
                weight: FontWeight.w700,
                color: KColors.navyText)),
        centerTitle: false,
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(
            horizontal: w * 0.04, vertical: w * 0.04),
        children: [
          // Section: บัญชี
          Text('บัญชี',
              style: thaiSans(
                  size: 13,
                  weight: FontWeight.w600,
                  color: KColors.navyText.withAlpha(140))),
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
          Text('การแนะนำ',
              style: thaiSans(
                  size: 13,
                  weight: FontWeight.w600,
                  color: KColors.navyText.withAlpha(140))),
          const SizedBox(height: 8),
          Container(
            decoration: cardDecoration(radius: 16),
            child: SwitchListTile(
              value: introEnabled,
              onChanged: (v) =>
                  ref.read(introEnabledProvider.notifier).set(v),
              activeThumbColor: KColors.teal,
              contentPadding: EdgeInsets.symmetric(horizontal: w * 0.045),
              secondary: const Icon(Icons.slideshow_rounded,
                  color: KColors.teal, size: 22),
              title: Text('แสดงการแนะนำแอปตอนเปิด',
                  style: thaiSans(
                      size: 16,
                      weight: FontWeight.w600,
                      color: KColors.navyText)),
              subtitle: Text(
                  'ปิดแล้วจะแสดงเฉพาะการเชื่อมต่อบลูทูธและการติดตั้งแผ่น EMG',
                  style: thaiSans(
                      size: 12,
                      weight: FontWeight.w500,
                      color: KColors.navyText.withAlpha(130))),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text('ฟีเจอร์เพิ่มเติมเร็วๆ นี้',
                style: thaiSans(
                    size: 13,
                    weight: FontWeight.w500,
                    color: KColors.navyText.withAlpha(100))),
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

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return ListTile(
      onTap: onTap,
      contentPadding:
          EdgeInsets.symmetric(horizontal: w * 0.045, vertical: 2),
      leading: Icon(icon, color: KColors.teal, size: 22),
      title: Text(label,
          style: thaiSans(
              size: 16,
              weight: FontWeight.w600,
              color: KColors.navyText)),
      trailing: const Icon(Icons.chevron_right_rounded,
          color: KColors.navyText, size: 22),
    );
  }
}
