import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../ble/ble_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive.dart';

/// Connects the two Kinex boards: the Leg board (EMG, "Kinex-EMG") and the Hand
/// board (MPU6050 tilt, "Kinex-Hand"). Each has its own connection, so you can
/// connect one, the other, or both. They share the phone's single BLE scanner,
/// so a board's connect button is disabled while the other board is scanning or
/// connecting — connect them one at a time.
class DevicesPage extends ConsumerWidget {
  const DevicesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final legState = ref.watch(bleControllerProvider);
    final handState = ref.watch(handBleProvider);

    bool busy(BleState s) =>
        s.status == BleStatus.scanning || s.status == BleStatus.connecting;

    return Scaffold(
      backgroundColor: KColors.appBg,
      appBar: AppBar(
        backgroundColor: KColors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('อุปกรณ์ Kinex',
            style: montserrat(size: context.r(18), color: Colors.white)),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(context.r(14), context.r(16), context.r(14),
            context.r(24) + MediaQuery.paddingOf(context).bottom),
        children: [
          _DeviceCard(
            provider: bleControllerProvider,
            title: 'อุปกรณ์ขา',
            subtitle: 'เซนเซอร์กล้ามเนื้อ (EMG) · Kinex-EMG',
            icon: Icons.directions_walk,
            accent: KColors.teal,
            state: legState,
            otherBusy: busy(handState),
            namePrefix: 'Kinex-EMG',
          ),
          SizedBox(height: context.r(14)),
          _DeviceCard(
            provider: handBleProvider,
            title: 'อุปกรณ์มือ',
            subtitle: 'เซนเซอร์การเอียง (MPU6050) · Kinex-Hand',
            icon: Icons.back_hand,
            accent: KColors.blue,
            state: handState,
            otherBusy: busy(legState),
            namePrefix: 'Kinex-Hand',
          ),
          SizedBox(height: context.r(20)),
          Center(
            child: TextButton.icon(
              onPressed: () => context.push('/ble-debug'),
              icon: Icon(Icons.terminal, size: context.r(18), color: KColors.navyText),
              label: Text('เปิดหน้า BLE Debug (ดูข้อมูลดิบ)',
                  style: thaiSans(size: context.r(13), color: KColors.navyText)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Device card ─────────────────────────────────────────────────────────────

class _DeviceCard extends ConsumerWidget {
  final NotifierProvider<BleController, BleState> provider;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final BleState state;
  final bool otherBusy; // the OTHER board is scanning/connecting → block this one
  final String namePrefix;

  const _DeviceCard({
    required this.provider,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.state,
    required this.otherBusy,
    required this.namePrefix,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctl = ref.read(provider.notifier);
    final connected = state.status == BleStatus.connected;
    final scanning = state.status == BleStatus.scanning;
    final connecting = state.status == BleStatus.connecting;
    final r = context.r;

    return Container(
      padding: EdgeInsets.all(r(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(r(18)),
        border: Border.all(
            color: connected ? accent : Colors.grey.shade200,
            width: connected ? 1.5 : 1),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: r(10),
              offset: Offset(0, r(3))),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(r(10)),
                decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(r(12))),
                child: Icon(icon, color: accent, size: r(26)),
              ),
              SizedBox(width: r(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: montserrat(
                            size: r(17),
                            color: KColors.navyText,
                            weight: FontWeight.w700)),
                    SizedBox(height: r(2)),
                    Text(subtitle,
                        style: thaiSans(size: r(12), color: Colors.grey.shade600)),
                  ],
                ),
              ),
              _StatusPill(status: state.status, accent: accent, r: r),
            ],
          ),
          if (state.lastError != null) ...[
            SizedBox(height: r(10)),
            Text(state.lastError!,
                style: thaiSans(size: r(12), color: const Color(0xFFC62828))),
          ],
          SizedBox(height: r(14)),
          SizedBox(
            width: double.infinity,
            child: connected
                ? OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: EdgeInsets.symmetric(vertical: r(12)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(r(12))),
                    ),
                    onPressed: ctl.disconnect,
                    child: Text('ตัดการเชื่อมต่อ',
                        style: thaiSans(size: r(15), color: Colors.red)),
                  )
                : ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      disabledBackgroundColor: Colors.grey.shade300,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: r(12)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(r(12))),
                      elevation: 1,
                    ),
                    icon: (scanning || connecting)
                        ? SizedBox(
                            width: r(18),
                            height: r(18),
                            child: const CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Icon(Icons.bluetooth_searching, size: r(20)),
                    label: Text(
                      scanning
                          ? 'กำลังค้นหา…'
                          : connecting
                              ? 'กำลังเชื่อมต่อ…'
                              : 'เชื่อมต่อ',
                      style: thaiSans(size: r(15), color: Colors.white),
                    ),
                    // Block while THIS board is busy, or the OTHER board is using
                    // the shared scanner.
                    onPressed: (scanning || connecting || otherBusy)
                        ? null
                        : () => ctl.quickConnect(namePrefix: namePrefix),
                  ),
          ),
          if (otherBusy && !connected && !scanning && !connecting) ...[
            SizedBox(height: r(8)),
            Text('รออีกอุปกรณ์เชื่อมต่อเสร็จก่อน',
                style: thaiSans(size: r(11), color: Colors.grey.shade500)),
          ],
        ],
      ),
    );
  }
}

// ─── Status pill ─────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  final BleStatus status;
  final Color accent;
  final double Function(double) r;

  const _StatusPill({required this.status, required this.accent, required this.r});

  @override
  Widget build(BuildContext context) {
    final Color c;
    final String label;
    switch (status) {
      case BleStatus.idle:
        c = Colors.grey;
        label = 'ยังไม่เชื่อมต่อ';
      case BleStatus.scanning:
        c = KColors.orangeDark;
        label = 'ค้นหา';
      case BleStatus.connecting:
        c = KColors.blue;
        label = 'เชื่อมต่อ…';
      case BleStatus.connected:
        c = accent;
        label = 'เชื่อมต่อแล้ว';
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: r(10), vertical: r(5)),
      decoration: BoxDecoration(
          color: c.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(r(20))),
      child: Text(label,
          style: thaiSans(size: r(11), color: c)),
    );
  }
}
