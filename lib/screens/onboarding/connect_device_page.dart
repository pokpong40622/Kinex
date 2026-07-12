import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive.dart';
import '../../ble/ble_service.dart';

/// Full-screen landing shown on every cold launch (before the hardware guide)
/// that prompts the user to connect their Kinex sensor device via BLE.
///
/// Pop contract (mirrors hardware_guide_page.dart):
///   true      → device connected (auto-pops after short delay)
///   'skipped' → user tapped "ข้าม"
///   null      → back-dismissed
class ConnectDevicePage extends ConsumerStatefulWidget {
  const ConnectDevicePage({super.key});

  @override
  ConsumerState<ConnectDevicePage> createState() => _ConnectDevicePageState();
}

class _ConnectDevicePageState extends ConsumerState<ConnectDevicePage> {
  bool _autoPopped = false;

  @override
  void initState() {
    super.initState();
    // If already connected when page opens, pop immediately.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(bleControllerProvider).status == BleStatus.connected) {
        _autoPopped = true;
        Navigator.of(context).pop(true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen for connection; auto-pop with result=true after a short delay.
    ref.listen<BleState>(bleControllerProvider, (prev, next) {
      if (next.status == BleStatus.connected && !_autoPopped) {
        _autoPopped = true;
        // Capture navigator before the async gap to satisfy the linter.
        final nav = Navigator.of(context);
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) nav.pop(true);
        });
      }
    });

    final ble = ref.watch(bleControllerProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: KColors.blueGradient),
        child: SafeArea(
          child: Column(
            children: [
              // ── Skip button (top-right) ──────────────────────────────────
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: EdgeInsets.only(right: context.r(8), top: context.r(4)),
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, 'skipped'),
                    child: Text(
                      'ข้าม',
                      style: thaiSans(
                          size: context.r(15),
                          weight: FontWeight.w600,
                          color: Colors.white70),
                    ),
                  ),
                ),
              ),

              // ── Main content ─────────────────────────────────────────────
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bluetooth_rounded,
                      size: context.r(72),
                      color: Colors.white.withAlpha(200),
                    ),
                    SizedBox(height: context.r(24)),
                    Text(
                      'เชื่อมต่ออุปกรณ์ Kinex',
                      style: thaiSans(
                          size: context.r(22),
                          weight: FontWeight.w800,
                          color: Colors.white),
                    ),
                    SizedBox(height: context.r(10)),
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: context.r(40)),
                      child: Text(
                        'เชื่อมต่อชุดเซ็นเซอร์ก่อนเริ่มการฝึก',
                        textAlign: TextAlign.center,
                        style: thaiSans(
                            size: context.r(14),
                            weight: FontWeight.w500,
                            color: Colors.white70),
                      ),
                    ),
                    SizedBox(height: context.r(40)),
                    _StatusArea(ble: ble),
                  ],
                ),
              ),

              // ── Primary action button ────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(
                    context.r(32), 0, context.r(32), context.r(36)),
                child: _ConnectButton(
                  ble: ble,
                  onConnect: () =>
                      ref.read(bleControllerProvider.notifier).quickConnect(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Status area ────────────────────────────────────────────────────────────

class _StatusArea extends StatelessWidget {
  final BleState ble;
  const _StatusArea({required this.ble});

  @override
  Widget build(BuildContext context) {
    if (ble.status == BleStatus.scanning ||
        ble.status == BleStatus.connecting) {
      return Column(
        children: [
          const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Colors.white)),
          SizedBox(height: context.r(12)),
          Text(
            'กำลังค้นหา…',
            style: thaiSans(
                size: context.r(14),
                weight: FontWeight.w600,
                color: Colors.white70),
          ),
        ],
      );
    }
    if (ble.status == BleStatus.connected) {
      return Column(
        children: [
          Icon(Icons.check_circle_rounded,
              color: KColors.teal, size: context.r(48)),
          SizedBox(height: context.r(10)),
          Text(
            'เชื่อมต่อแล้ว',
            style: thaiSans(
                size: context.r(16),
                weight: FontWeight.w700,
                color: Colors.white),
          ),
          if (ble.connectedName != null)
            Text(
              ble.connectedName!,
              style: thaiSans(
                  size: context.r(13),
                  weight: FontWeight.w500,
                  color: Colors.white70),
            ),
        ],
      );
    }
    if (ble.needsSettings) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: context.r(32)),
        child: Text(
          'กรุณาเปิดสิทธิ์ Bluetooth ในการตั้งค่าของแอป',
          textAlign: TextAlign.center,
          style: thaiSans(
              size: context.r(14),
              weight: FontWeight.w500,
              color: Colors.white70),
        ),
      );
    }
    if (ble.lastError != null && ble.status == BleStatus.idle) {
      return Text(
        'ไม่พบอุปกรณ์ ลองอีกครั้ง',
        style: thaiSans(
            size: context.r(14),
            weight: FontWeight.w600,
            color: Colors.white70),
      );
    }
    return const SizedBox.shrink();
  }
}

// ── Connect button ─────────────────────────────────────────────────────────

class _ConnectButton extends StatelessWidget {
  final BleState ble;
  final VoidCallback onConnect;
  const _ConnectButton({required this.ble, required this.onConnect});

  @override
  Widget build(BuildContext context) {
    final isBusy = ble.status == BleStatus.scanning ||
        ble.status == BleStatus.connecting ||
        ble.status == BleStatus.connected;

    return GestureDetector(
      onTap: isBusy ? null : onConnect,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: context.r(16)),
        decoration: BoxDecoration(
          color: isBusy ? Colors.white38 : Colors.white,
          borderRadius: BorderRadius.circular(context.r(18)),
          boxShadow: isBusy
              ? null
              : const [
                  BoxShadow(
                      color: Color(0x40000000),
                      blurRadius: 14,
                      offset: Offset(0, 5)),
                ],
        ),
        alignment: Alignment.center,
        child: Text(
          'เชื่อมต่อ',
          style: thaiSans(
              size: context.r(18),
              weight: FontWeight.w800,
              color: isBusy ? Colors.white70 : KColors.blue),
        ),
      ),
    );
  }
}
