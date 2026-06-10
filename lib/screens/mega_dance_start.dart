import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../widgets/game_screen_wrapper.dart';

class MegaDanceStartPage extends ConsumerWidget {
  const MegaDanceStartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GameScreenWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              // back button top-left
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
              // "MEGA DANCE" centered
              const Center(
                child: Text(
                  'MEGA\nDANCE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    height: 1.1,
                    shadows: [
                      Shadow(
                          color: Color(0x80000000),
                          blurRadius: 12,
                          offset: Offset(0, 4))
                    ],
                  ),
                ),
              ),
              // Start button bottom center
              Positioned(
                bottom: 40,
                left: 40,
                right: 40,
                child: GestureDetector(
                  onTap: () => context.go('/mega-dance/game'),
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: KColors.greenGradient,
                      borderRadius: BorderRadius.circular(30),
                      border:
                          Border.all(color: Colors.white.withAlpha(115), width: 2),
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x40000000),
                            blurRadius: 8,
                            offset: Offset(0, 4))
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Start',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900),
                    ),
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
