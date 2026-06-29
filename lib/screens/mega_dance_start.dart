import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

/// MEGA DANCE start screen — matches the Figma "MegaDanceStart" frame:
/// the room background, a big white italic "MEGA DANCE" wordmark (centred),
/// a red back button (top-left) and a green "Start" pill (bottom-centre).
/// English only, no gradient — like a standard game start screen.
class MegaDanceStartPage extends ConsumerWidget {
  const MegaDanceStartPage({super.key});

  static const _green = Color(0xFF6DDB2A);
  static const _red = Color(0xFFF5333A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final w = MediaQuery.sizeOf(context).width;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/bg_room.png', fit: BoxFit.cover),
          // Subtle dark scrim so the white wordmark stays readable over the room.
          Container(color: Colors.black.withAlpha(46)),
          SafeArea(
            child: Stack(
              children: [
                // ── Back button (top-left): red rounded square, white arrow ──
                Positioned(
                  left: w * 0.05,
                  top: w * 0.04,
                  child: GestureDetector(
                    onTap: () => context.go('/home'),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: w * 0.15,
                      height: w * 0.15,
                      decoration: BoxDecoration(
                        color: _red,
                        borderRadius: BorderRadius.circular(w * 0.045),
                        boxShadow: const [
                          BoxShadow(
                              color: Color(0x40000000),
                              blurRadius: 10,
                              offset: Offset(0, 4)),
                        ],
                      ),
                      child: Icon(Icons.arrow_back_rounded,
                          color: Colors.white, size: w * 0.09),
                    ),
                  ),
                ),

                // ── Wordmark (centred) ──────────────────────────────────────
                Align(
                  alignment: const Alignment(0, -0.12),
                  child: Text(
                    'MEGA\nDANCE',
                    textAlign: TextAlign.center,
                    style: montserrat(
                            size: w * 0.17,
                            weight: FontWeight.w900,
                            color: Colors.white)
                        .copyWith(
                      fontStyle: FontStyle.italic,
                      height: 0.95,
                      letterSpacing: -1,
                      shadows: const [
                        Shadow(
                            color: Color(0x73000000),
                            blurRadius: 14,
                            offset: Offset(2, 5)),
                      ],
                    ),
                  ),
                ),

                // ── Mode badge (under the wordmark): this game = REHAB ──────
                Align(
                  alignment: const Alignment(0, 0.22),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: w * 0.05, vertical: w * 0.022),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(64),
                      borderRadius: BorderRadius.circular(w * 0.08),
                      border:
                          Border.all(color: Colors.white.withAlpha(140), width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.healing_rounded,
                            color: Colors.white, size: w * 0.05),
                        SizedBox(width: w * 0.025),
                        Text(
                          'REHAB · ฟื้นฟูร่างกาย',
                          style: montserrat(
                              size: w * 0.04,
                              weight: FontWeight.w800,
                              color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Start button (bottom-centre): green pill ────────────────
                Align(
                  alignment: const Alignment(0, 0.84),
                  child: GestureDetector(
                    onTap: () => context.go('/mega-dance/game'),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: w * 0.56,
                      height: w * 0.16,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _green,
                        borderRadius: BorderRadius.circular(w * 0.08),
                        border: Border.all(
                            color: Colors.white.withAlpha(170), width: 2),
                        boxShadow: const [
                          BoxShadow(
                              color: Color(0x4D000000),
                              blurRadius: 14,
                              offset: Offset(0, 6)),
                        ],
                      ),
                      child: Text(
                        'เริ่ม',
                        style: montserrat(
                            size: w * 0.072,
                            weight: FontWeight.w800,
                            color: Colors.white),
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
