import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../widgets/game_screen_wrapper.dart';

class MegaDanceCorrectPage extends ConsumerWidget {
  const MegaDanceCorrectPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final w = MediaQuery.sizeOf(context).width;
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
              // content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'First pose',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: w * 0.052,
                          fontWeight: FontWeight.w700,
                          shadows: const [
                            Shadow(color: Color(0x80000000), blurRadius: 8)
                          ]),
                    ),
                    SizedBox(height: w * 0.04),
                    Text(
                      'Correct!',
                      style: TextStyle(
                        color: const Color(0xFF4ADE80),
                        fontSize: w * 0.14,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        shadows: const [
                          Shadow(
                              color: Color(0x80000000),
                              blurRadius: 12,
                              offset: Offset(0, 4))
                        ],
                      ),
                    ),
                    SizedBox(height: w * 0.1),
                    GestureDetector(
                      onTap: () => context.go('/mega-dance/first-pose'),
                      child: Container(
                        width: w * 0.55,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: KColors.greenGradient,
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(color: Colors.white.withAlpha(115), width: 2),
                          boxShadow: const [
                            BoxShadow(color: Color(0x40000000), blurRadius: 8, offset: Offset(0, 4))
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Text('Next Pose',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900)),
                      ),
                    ),
                    SizedBox(height: w * 0.04),
                    GestureDetector(
                      onTap: () => context.go('/home'),
                      child: Text('Finish',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: w * 0.045,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
