import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../ble/ble_service.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';

/// The one place that explains — and performs — the fact that a Kinex set is
/// TWO separate boards: the leg board (EMG) and the hand board (tilt). Users
/// kept connecting one and assuming they were done, so this panel always shows
/// both slots side by side with a "x / 2" counter, never a single button.
///
/// Used by the home top-bar Bluetooth sheet and by the cold-launch connect
/// page, so both entry points tell the same story.
///
/// Colour rules (deliberately narrow, for elderly users on a bright tablet):
///   • identity colour — teal = leg, blue = hand. Only on the icon tile and the
///     board's own connect button, so a board is recognisable at a glance.
///   • state colour — grey = not connected, amber = working, green = connected,
///     red = disconnect. Never reused for identity, so "green" always and only
///     means "this one is done".
class DeviceConnectPanel extends ConsumerWidget {
  /// Shown under the two rows; null hides the footer button entirely.
  final VoidCallback? onOpenDebug;

  /// Shown as the closing action once the user is finished.
  final VoidCallback? onDone;

  const DeviceConnectPanel({super.key, this.onOpenDebug, this.onDone});

  static const legColor = KColors.teal;
  static const handColor = KColors.blue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leg = ref.watch(bleControllerProvider);
    final hand = ref.watch(handBleProvider);
    final r = context.r;

    bool busy(BleState s) =>
        s.status == BleStatus.scanning || s.status == BleStatus.connecting;

    final done = [leg, hand]
        .where((s) => s.status == BleStatus.connected)
        .length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(done: done, r: r),
        SizedBox(height: r(16)),
        _BoardRow(
          step: 1,
          title: 'กล่องขา',
          where: 'ติดแผ่น EMG ที่ขา — วัดกล้ามเนื้อ',
          icon: Icons.directions_walk_rounded,
          identity: legColor,
          state: leg,
          otherBusy: busy(hand),
          onConnect: () => ref
              .read(bleControllerProvider.notifier)
              .quickConnect(namePrefix: 'Kinex-EMG'),
          onDisconnect: () =>
              ref.read(bleControllerProvider.notifier).disconnect(),
        ),
        SizedBox(height: r(10)),
        _BoardRow(
          step: 2,
          title: 'กล่องมือ',
          where: 'ถือไว้ในมือ — วัดการเอียง',
          icon: Icons.back_hand_rounded,
          identity: handColor,
          state: hand,
          otherBusy: busy(leg),
          onConnect: () => ref
              .read(handBleProvider.notifier)
              .quickConnect(namePrefix: 'Kinex-Hand'),
          onDisconnect: () => ref.read(handBleProvider.notifier).disconnect(),
        ),
        if (leg.needsSettings || hand.needsSettings) ...[
          SizedBox(height: r(12)),
          _PermissionNotice(r: r),
        ],
        if (onDone != null) ...[
          SizedBox(height: r(16)),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    done == 2 ? KColors.teal : Colors.grey.shade200,
                foregroundColor: done == 2 ? Colors.white : KColors.navyText,
                elevation: 0,
                padding: EdgeInsets.symmetric(vertical: r(14)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(r(16))),
              ),
              onPressed: onDone,
              child: Text(
                done == 2 ? 'พร้อมแล้ว เริ่มใช้งาน' : 'ข้ามไปก่อน',
                style: thaiSans(
                    size: r(16),
                    weight: FontWeight.w700,
                    color: done == 2 ? Colors.white : KColors.navyText),
              ),
            ),
          ),
        ],
        if (onOpenDebug != null)
          TextButton(
            onPressed: onOpenDebug,
            child: Text('เลือกอุปกรณ์เองใน BLE Debug',
                style: thaiSans(
                    size: r(13),
                    weight: FontWeight.w600,
                    color: Colors.grey.shade600)),
          ),
      ],
    );
  }
}

// ── Header: the "there are two of them" message + progress ───────────────────

class _Header extends StatelessWidget {
  final int done;
  final double Function(double) r;
  const _Header({required this.done, required this.r});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('เชื่อมต่ออุปกรณ์ Kinex',
            textAlign: TextAlign.center,
            style: thaiSans(
                size: r(20),
                weight: FontWeight.w800,
                color: KColors.navyText)),
        SizedBox(height: r(6)),
        Text(
          'ชุด Kinex มี 2 กล่อง — กล่องขา และ กล่องมือ\nต้องเชื่อมต่อทีละกล่อง ให้ครบทั้งสอง',
          textAlign: TextAlign.center,
          style: thaiSans(size: r(13.5), color: Colors.grey.shade600),
        ),
        SizedBox(height: r(12)),
        // Progress counter — the single number that tells the user they are not
        // finished after connecting just one board.
        Container(
          padding: EdgeInsets.symmetric(horizontal: r(14), vertical: r(7)),
          decoration: BoxDecoration(
            color: (done == 2 ? KColors.teal : KColors.orangeDark)
                .withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(r(20)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                  done == 2
                      ? Icons.check_circle_rounded
                      : Icons.info_outline_rounded,
                  size: r(17),
                  color: done == 2 ? KColors.teal : KColors.orangeDark),
              SizedBox(width: r(7)),
              Text('เชื่อมต่อแล้ว $done จาก 2',
                  style: thaiSans(
                      size: r(13),
                      weight: FontWeight.w700,
                      color: done == 2 ? KColors.teal : KColors.orangeDark)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── One board slot ───────────────────────────────────────────────────────────

class _BoardRow extends StatelessWidget {
  final int step;
  final String title;
  final String where;
  final IconData icon;
  final Color identity;
  final BleState state;
  final bool otherBusy; // the other board owns the shared scanner right now
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;

  const _BoardRow({
    required this.step,
    required this.title,
    required this.where,
    required this.icon,
    required this.identity,
    required this.state,
    required this.otherBusy,
    required this.onConnect,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final connected = state.status == BleStatus.connected;
    final working = state.status == BleStatus.scanning ||
        state.status == BleStatus.connecting;

    return Container(
      padding: EdgeInsets.all(r(14)),
      decoration: BoxDecoration(
        color: connected ? identity.withValues(alpha: 0.05) : KColors.appBg,
        borderRadius: BorderRadius.circular(r(18)),
        border: Border.all(
            color: connected ? identity : KColors.hairline,
            width: connected ? 1.5 : 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Step number + identity tile: "this is board 1 of 2".
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: EdgeInsets.all(r(10)),
                    decoration: BoxDecoration(
                      color: identity.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(r(14)),
                    ),
                    child: Icon(icon, color: identity, size: r(26)),
                  ),
                  Positioned(
                    left: -r(4),
                    top: -r(4),
                    child: Container(
                      width: r(20),
                      height: r(20),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: identity,
                        shape: BoxShape.circle,
                      ),
                      child: Text('$step',
                          style: montserrat(
                              size: r(11),
                              weight: FontWeight.w800,
                              color: Colors.white)),
                    ),
                  ),
                ],
              ),
              SizedBox(width: r(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: thaiSans(
                            size: r(16),
                            weight: FontWeight.w800,
                            color: KColors.navyText)),
                    SizedBox(height: r(2)),
                    Text(where,
                        style:
                            thaiSans(size: r(12), color: Colors.grey.shade600)),
                  ],
                ),
              ),
              _StatusChip(state: state, r: r),
            ],
          ),
          SizedBox(height: r(12)),
          SizedBox(
            width: double.infinity,
            child: connected
                ? OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE53935)),
                      padding: EdgeInsets.symmetric(vertical: r(11)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(r(14))),
                    ),
                    onPressed: onDisconnect,
                    child: Text('ตัดการเชื่อมต่อ',
                        style: thaiSans(
                            size: r(14),
                            weight: FontWeight.w700,
                            color: const Color(0xFFE53935))),
                  )
                : ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: identity,
                      disabledBackgroundColor: Colors.grey.shade300,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: r(11)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(r(14))),
                    ),
                    icon: working
                        ? SizedBox(
                            width: r(16),
                            height: r(16),
                            child: const CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Icon(Icons.bluetooth_searching_rounded, size: r(18)),
                    // Both slots share the phone's one BLE scanner, so only one
                    // can search at a time.
                    onPressed: (working || otherBusy) ? null : onConnect,
                    label: Text(
                      working ? 'กำลังค้นหา…' : 'เชื่อมต่อ$title',
                      style: thaiSans(
                          size: r(14),
                          weight: FontWeight.w700,
                          color: Colors.white),
                    ),
                  ),
          ),
          if (otherBusy && !connected && !working) ...[
            SizedBox(height: r(6)),
            Text('รอให้อีกกล่องเชื่อมต่อเสร็จก่อน',
                style: thaiSans(size: r(11), color: Colors.grey.shade500)),
          ],
          if (!connected && !working && state.lastError != null) ...[
            SizedBox(height: r(6)),
            Text('ไม่พบกล่องนี้ — เปิดเครื่องแล้วลองอีกครั้ง',
                style: thaiSans(size: r(11), color: KColors.orangeDark)),
          ],
        ],
      ),
    );
  }
}

// ── Status chip ──────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final BleState state;
  final double Function(double) r;
  const _StatusChip({required this.state, required this.r});

  @override
  Widget build(BuildContext context) {
    final Color c;
    final String label;
    switch (state.status) {
      case BleStatus.idle:
        c = Colors.grey;
        label = 'ยังไม่ต่อ';
      case BleStatus.scanning:
        c = KColors.orangeDark;
        label = 'ค้นหา…';
      case BleStatus.connecting:
        c = KColors.orangeDark;
        label = 'กำลังต่อ…';
      case BleStatus.connected:
        c = KColors.teal;
        label = 'ต่อแล้ว';
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: r(9), vertical: r(5)),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(r(20)),
      ),
      child: Text(label,
          style: thaiSans(size: r(11), weight: FontWeight.w700, color: c)),
    );
  }
}

// ── Permission notice ────────────────────────────────────────────────────────

class _PermissionNotice extends StatelessWidget {
  final double Function(double) r;
  const _PermissionNotice({required this.r});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(r(12)),
      decoration: BoxDecoration(
        color: KColors.orangeDark.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(r(14)),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline_rounded,
              color: KColors.orangeDark, size: r(20)),
          SizedBox(width: r(10)),
          Expanded(
            child: Text('แอปต้องได้รับสิทธิ์ Bluetooth ก่อนจึงจะค้นหากล่องได้',
                style: thaiSans(size: r(12), color: KColors.navyText)),
          ),
          TextButton(
            onPressed: openAppSettings,
            child: Text('ตั้งค่า',
                style: thaiSans(
                    size: r(13),
                    weight: FontWeight.w700,
                    color: KColors.orangeDark)),
          ),
        ],
      ),
    );
  }
}
