import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive.dart';
import '../../ble/ble_service.dart';
import '../../widgets/device_connect_panel.dart';

/// Full-screen landing shown on every cold launch (before the hardware guide).
///
/// A Kinex set is TWO boards — leg (EMG) and hand (tilt) — and the old version
/// of this page had a single "เชื่อมต่อ" button, so users connected the leg
/// board and walked away thinking they were done. It now shows both slots via
/// [DeviceConnectPanel] and only reports success once both are live.
///
/// Pop contract (mirrors hardware_guide_page.dart):
///   true      → both boards connected (user tapped the done button)
///   'skipped' → user tapped "ข้าม" / left with fewer than two connected
///   null      → back-dismissed
class ConnectDevicePage extends ConsumerWidget {
  const ConnectDevicePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final legOk = ref.watch(
        bleControllerProvider.select((s) => s.status == BleStatus.connected));
    final handOk = ref
        .watch(handBleProvider.select((s) => s.status == BleStatus.connected));

    // Matches the rest of the app: room photo background + a white rounded card,
    // instead of a full-screen colour gradient wash.
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/bg_room.png', fit: BoxFit.cover),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: EdgeInsets.only(
                        right: context.r(10), top: context.r(4)),
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, 'skipped'),
                      child: Text(
                        'ข้าม',
                        style: thaiSans(
                            size: context.r(15),
                            weight: FontWeight.w700,
                            color: KColors.navyText.withAlpha(160)),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                          horizontal: context.r(20), vertical: context.r(8)),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                            horizontal: context.r(20),
                            vertical: context.r(24)),
                        decoration:
                            cardDecoration(radius: 28, color: Colors.white),
                        child: DeviceConnectPanel(
                          // Both connected → real success; otherwise the user is
                          // choosing to move on without the full set.
                          onDone: () => Navigator.pop(
                              context, (legOk && handOk) ? true : 'skipped'),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
