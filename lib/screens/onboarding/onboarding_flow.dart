// First-entry onboarding popup FLOW, shown over the home page: software intro
// slides → Bluetooth connect → EMG-installation welcome, as ONE sequence of
// pages inside a single themed dialog with a page-dot indicator and a Skip
// button. Replaces the two separate full-page pushes (/connect-device then
// /hardware-guide) that home used to do on launch.
//
// - The intro slides are included only when the settings toggle
//   (introEnabledProvider) is ON. When OFF, the flow starts at Bluetooth.
// - Bluetooth stage: the user must CONNECT (auto-advances) or tap ข้าม — there
//   is no silent "next" pass-through.
// - Installation stage: "เริ่มติดตั้ง" closes the flow with [installRequested]
//   so home opens the real hardware guide (/hardware-guide); "ข้ามไปก่อน" and the
//   top-right Skip close it with [dismissed].
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive.dart';
import '../../ble/ble_service.dart';

enum OnboardingResult { installRequested, dismissed }

/// Show the onboarding flow as a modal dialog over the current screen. Returns
/// how it ended so the caller can open the hardware guide (installRequested) or
/// treat it as skipped (dismissed / null on barrier-less dismiss).
Future<OnboardingResult?> showOnboardingFlow(
  BuildContext context, {
  required bool introEnabled,
}) {
  return showDialog<OnboardingResult>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (_) => _OnboardingFlow(introEnabled: introEnabled),
  );
}

class _IntroSlide {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  /// Optional illustration. When set, it replaces the halo-icon so a real
  /// screenshot / AI-generated picture can teach the UI. Drop files under
  /// assets/images/onboarding/ and set this path (see image prompts handed to
  /// the user). Falls back to [icon] when null.
  final String? imageAsset;
  const _IntroSlide({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    this.imageAsset,
  });
}

final _introSlides = <_IntroSlide>[
  // ── What is this ──────────────────────────────────────────────────────────
  _IntroSlide(
    icon: Icons.self_improvement_rounded,
    color: KColors.purple,
    title: 'ยินดีต้อนรับสู่ Kinex',
    body:
        'แอปฟื้นฟูกล้ามเนื้อขาที่บ้าน ด้วยเกมสนุก ๆ ที่ควบคุมด้วยการขยับร่างกายจริง '
        'พร้อมเซ็นเซอร์วัดกล้ามเนื้อ (EMG)',
    imageAsset: 'assets/images/onboarding/intro_welcome.png',
  ),
  _IntroSlide(
    icon: Icons.directions_run_rounded,
    color: KColors.blue,
    title: 'เล่นด้วยการขยับตัว',
    body:
        'กล้องหน้าจะจับการเคลื่อนไหวของคุณ ยืนให้เห็นทั้งตัวแล้วขยับตามเกม '
        'เช่น ก้าวข้าง นั่ง-ลุก และเตะขา เพื่อฝึกกล้ามเนื้อ',
    imageAsset: 'assets/images/onboarding/intro_move.png',
  ),
  // NOTE: the "where things are" tour (games / progress / assess) is no longer a
  // set of picture slides here — it now runs as a live dim-hole coach-mark walk
  // over the REAL home UI right after this flow closes (see _CoachMarkOverlay in
  // home_page.dart).
  // ── Safety ────────────────────────────────────────────────────────────────
  _IntroSlide(
    icon: Icons.health_and_safety_rounded,
    color: KColors.teal,
    title: 'เตรียมพื้นที่ให้พร้อม',
    body:
        'จัดพื้นที่โล่งประมาณ 2 เมตร วางแท็บเล็ตให้มั่นคงระดับสายตา มีที่จับหรือเก้าอี้ '
        'ไว้พยุงตัว และหยุดพักทันทีหากรู้สึกเจ็บหรือเวียนหัว',
    imageAsset: 'assets/images/onboarding/intro_safety.png',
  ),
];

class _OnboardingFlow extends ConsumerStatefulWidget {
  final bool introEnabled;
  const _OnboardingFlow({required this.introEnabled});

  @override
  ConsumerState<_OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<_OnboardingFlow> {
  int _page = 0;
  bool _btAutoAdvanced = false;

  int get _introCount => widget.introEnabled ? _introSlides.length : 0;
  int get _totalPages => _introCount + 2; // + bluetooth + install
  bool get _isIntro => _page < _introCount;
  bool get _isBluetooth => _page == _introCount;

  void _next() => setState(() => _page++);
  void _goToInstall() => setState(() => _page = _introCount + 1);

  void _finish(OnboardingResult result) => Navigator.of(context).pop(result);

  @override
  Widget build(BuildContext context) {
    // Bluetooth stage: auto-advance to installation shortly after a connection
    // lands (mirrors the standalone connect page's listener).
    ref.listen<BleState>(bleControllerProvider, (prev, next) {
      if (_isBluetooth &&
          next.status == BleStatus.connected &&
          !_btAutoAdvanced) {
        _btAutoAdvanced = true;
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted && _isBluetooth) _goToInstall();
        });
      }
    });

    final size = MediaQuery.sizeOf(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding:
          EdgeInsets.symmetric(horizontal: context.r(14), vertical: context.r(24)),
      child: Container(
        width: size.width,
        constraints: BoxConstraints(minHeight: size.height * 0.62),
        padding: EdgeInsets.fromLTRB(
            context.r(24), context.r(12), context.r(24), context.r(24)),
        decoration: cardDecoration(radius: 28, color: Colors.white),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Skip — dismiss the whole flow.
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _finish(OnboardingResult.dismissed),
                child: Text('ข้าม',
                    style: thaiSans(
                        size: context.r(14),
                        weight: FontWeight.w700,
                        color: KColors.navyText.withAlpha(150))),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                child: _buildBody(),
              ),
            ),
            SizedBox(height: context.r(18)),
            _Dots(count: _totalPages, active: _page),
            SizedBox(height: context.r(16)),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isIntro) return _IntroBody(slide: _introSlides[_page]);
    if (_isBluetooth) return _BluetoothBody(ble: ref.watch(bleControllerProvider));
    return const _InstallBody();
  }

  Widget _buildFooter() {
    if (_isIntro) {
      return _PrimaryButton(
        label: 'ถัดไป',
        icon: Icons.arrow_forward_rounded,
        onTap: _next,
      );
    }
    if (_isBluetooth) {
      final ble = ref.watch(bleControllerProvider);
      final busy = ble.status == BleStatus.scanning ||
          ble.status == BleStatus.connecting ||
          ble.status == BleStatus.connected;
      // Require connect or skip — no plain "next".
      return Column(
        children: [
          _PrimaryButton(
            label: ble.status == BleStatus.connected ? 'เชื่อมต่อแล้ว' : 'เชื่อมต่อ',
            icon: Icons.bluetooth_rounded,
            color: KColors.blue,
            onTap: busy
                ? null
                : () => ref.read(bleControllerProvider.notifier).quickConnect(),
          ),
          SizedBox(height: context.r(8)),
          TextButton(
            onPressed: _goToInstall,
            child: Text('ข้าม',
                style: thaiSans(
                    size: context.r(14),
                    weight: FontWeight.w700,
                    color: KColors.navyText.withAlpha(160))),
          ),
        ],
      );
    }
    // Installation stage.
    return Column(
      children: [
        _PrimaryButton(
          label: 'เริ่มติดตั้ง',
          icon: Icons.play_arrow_rounded,
          color: KColors.teal,
          onTap: () => _finish(OnboardingResult.installRequested),
        ),
        SizedBox(height: context.r(8)),
        TextButton(
          onPressed: () => _finish(OnboardingResult.dismissed),
          child: Text('ข้ามไปก่อน',
              style: thaiSans(
                  size: context.r(14),
                  weight: FontWeight.w700,
                  color: KColors.navyText.withAlpha(160))),
        ),
      ],
    );
  }
}

// ── Bodies ───────────────────────────────────────────────────────────────────

class _IntroBody extends StatelessWidget {
  final _IntroSlide slide;
  const _IntroBody({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Framed hero: a soft same-hue panel holding the illustration (or a clean
        // halo-icon fallback), so the popup reads professional even before the art
        // is dropped in. Matches the approved M3 mock.
        _HeroFrame(slide: slide),
        SizedBox(height: context.r(22)),
        Text(slide.title,
            textAlign: TextAlign.center,
            style: thaiSans(
                size: context.r(25),
                weight: FontWeight.w800,
                color: KColors.navyText)),
        SizedBox(height: context.r(14)),
        Text(slide.body,
            textAlign: TextAlign.center,
            style: thaiSans(
                size: context.r(16.5),
                weight: FontWeight.w500,
                color: KColors.navyText.withAlpha(180))),
      ],
    );
  }
}

class _HeroFrame extends StatelessWidget {
  final _IntroSlide slide;
  const _HeroFrame({required this.slide});

  @override
  Widget build(BuildContext context) {
    final c = slide.color;
    return Container(
      height: context.r(190),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.r(22)),
        gradient: RadialGradient(
          center: const Alignment(-0.4, -0.5),
          radius: 1.1,
          colors: [c.withAlpha(38), c.withAlpha(14)],
        ),
        border: Border.all(color: c.withAlpha(36)),
      ),
      alignment: Alignment.center,
      child: slide.imageAsset != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(context.r(18)),
              child: Image.asset(
                slide.imageAsset!,
                height: context.r(150),
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) =>
                    _HaloIcon(icon: slide.icon, color: c),
              ),
            )
          : _HaloIcon(icon: slide.icon, color: c),
    );
  }
}

class _BluetoothBody extends StatelessWidget {
  final BleState ble;
  const _BluetoothBody({required this.ble});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _HaloIcon(icon: Icons.bluetooth_rounded, color: KColors.blue),
        SizedBox(height: context.r(20)),
        Text('เชื่อมต่ออุปกรณ์ Kinex',
            textAlign: TextAlign.center,
            style: thaiSans(
                size: context.r(22),
                weight: FontWeight.w800,
                color: KColors.navyText)),
        SizedBox(height: context.r(10)),
        Text('เชื่อมต่อชุดเซ็นเซอร์ผ่านบลูทูธก่อนเริ่มการฝึก',
            textAlign: TextAlign.center,
            style: thaiSans(
                size: context.r(14),
                weight: FontWeight.w500,
                color: KColors.navyText.withAlpha(150))),
        SizedBox(height: context.r(20)),
        _BtStatus(ble: ble),
      ],
    );
  }
}

class _BtStatus extends StatelessWidget {
  final BleState ble;
  const _BtStatus({required this.ble});

  @override
  Widget build(BuildContext context) {
    if (ble.status == BleStatus.scanning || ble.status == BleStatus.connecting) {
      return Column(children: [
        const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(KColors.blue)),
        SizedBox(height: context.r(10)),
        Text('กำลังค้นหา…',
            style: thaiSans(
                size: context.r(13),
                weight: FontWeight.w600,
                color: KColors.navyText.withAlpha(160))),
      ]);
    }
    if (ble.status == BleStatus.connected) {
      return Column(children: [
        Icon(Icons.check_circle_rounded, color: KColors.teal, size: context.r(40)),
        SizedBox(height: context.r(6)),
        Text('เชื่อมต่อแล้ว',
            style: thaiSans(
                size: context.r(15),
                weight: FontWeight.w700,
                color: KColors.navyText)),
        if (ble.connectedName != null)
          Text(ble.connectedName!,
              style: thaiSans(
                  size: context.r(12),
                  weight: FontWeight.w500,
                  color: KColors.navyText.withAlpha(150))),
      ]);
    }
    if (ble.needsSettings) {
      return Text('กรุณาเปิดสิทธิ์ Bluetooth ในการตั้งค่าของแอป',
          textAlign: TextAlign.center,
          style: thaiSans(
              size: context.r(13),
              weight: FontWeight.w500,
              color: KColors.orangeDark));
    }
    if (ble.lastError != null && ble.status == BleStatus.idle) {
      return Text('ไม่พบอุปกรณ์ ลองอีกครั้ง',
          style: thaiSans(
              size: context.r(13),
              weight: FontWeight.w600,
              color: KColors.orangeDark));
    }
    return const SizedBox.shrink();
  }
}

class _InstallBody extends StatelessWidget {
  const _InstallBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _HaloIcon(icon: Icons.sensors_rounded, color: KColors.teal),
        SizedBox(height: context.r(20)),
        Text('ติดตั้งสายรัดเซ็นเซอร์ EMG',
            textAlign: TextAlign.center,
            style: thaiSans(
                size: context.r(22),
                weight: FontWeight.w800,
                color: KColors.navyText)),
        SizedBox(height: context.r(12)),
        Text(
            'ก่อนเริ่มฝึก มาติดสายรัด EMG ที่ขาของคุณ แล้ววัดค่ากล้ามเนื้อกันก่อน '
            'ใช้เวลาไม่นาน',
            textAlign: TextAlign.center,
            style: thaiSans(
                size: context.r(15),
                weight: FontWeight.w500,
                color: KColors.navyText.withAlpha(170))),
      ],
    );
  }
}

// ── Shared bits ──────────────────────────────────────────────────────────────

class _HaloIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _HaloIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.r(92),
      height: context.r(92),
      decoration: BoxDecoration(shape: BoxShape.circle, color: color.withAlpha(26)),
      child: Icon(icon, size: context.r(46), color: color),
    );
  }
}

class _Dots extends StatelessWidget {
  final int count;
  final int active;
  const _Dots({required this.count, required this.active});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: EdgeInsets.symmetric(horizontal: context.r(4)),
          width: i == active ? context.r(22) : context.r(8),
          height: context.r(8),
          decoration: BoxDecoration(
            color: i == active ? KColors.purple : Colors.grey.withAlpha(90),
            borderRadius: BorderRadius.circular(context.r(6)),
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;
  const _PrimaryButton({
    required this.label,
    required this.icon,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final c = color ?? KColors.purple;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        height: context.r(54),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled ? c : c.withAlpha(90),
          borderRadius: BorderRadius.circular(context.r(18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: thaiSans(
                    size: context.r(17),
                    weight: FontWeight.w800,
                    color: Colors.white)),
            SizedBox(width: context.r(8)),
            Icon(icon, color: Colors.white, size: context.r(22)),
          ],
        ),
      ),
    );
  }
}
