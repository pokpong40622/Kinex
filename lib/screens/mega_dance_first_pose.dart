import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../widgets/game_screen_wrapper.dart';

class MegaDanceFirstPosePage extends ConsumerWidget {
  const MegaDanceFirstPosePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    final h = size.height;
    return GameScreenWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              // back button
              Positioned(
                top: 16,
                left: 16,
                child: GestureDetector(
                  onTap: () => context.go('/home'),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 28),
                  ),
                ),
              ),
              // pose card
              Center(
                child: Container(
                  width: w * 0.72,
                  padding: EdgeInsets.symmetric(
                      vertical: h * 0.04, horizontal: w * 0.06),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: const Color(0xFFF5C3A0), width: 3),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x50000000),
                          blurRadius: 20,
                          offset: Offset(0, 6)),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'First pose',
                        style: TextStyle(
                          fontSize: w * 0.075,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          shadows: const [
                            Shadow(
                                color: Color(0x40000000),
                                blurRadius: 2,
                                offset: Offset(1, 1))
                          ],
                        ),
                      ),
                      SizedBox(height: h * 0.008),
                      Text(
                        'Do this pose',
                        style: TextStyle(
                          fontSize: w * 0.048,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: h * 0.03),
                      Image.asset(
                        'assets/images/char_main.png',
                        height: h * 0.32,
                        fit: BoxFit.contain,
                      ),
                      SizedBox(height: h * 0.025),
                      GestureDetector(
                        onTap: () => context.go('/mega-dance/correct'),
                        child: Container(
                          width: double.infinity,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: KColors.greenGradient,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Pose Detected [Mock]',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: w * 0.040,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
