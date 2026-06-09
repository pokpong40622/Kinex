import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class StartPage extends StatelessWidget {
  const StartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // clear room background — no blur
          Image.asset('assets/images/bg_room.png', fit: BoxFit.cover),
          // character — centered, large
          Positioned(
            left: w * 0.52,
            right: -w * 0.03,
            bottom: 0,
            top: h * 0.20,
            child: Image.asset('assets/images/char_main.png',
                fit: BoxFit.contain),
          ),
          // "Welcom to" + KINEX logo — centered upper area
          Positioned(
            top: h * 0.10,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text('Welcom to',
                    style: poppins(size: w * 0.07, color: Colors.white)),
                const SizedBox(height: 8),
                Image.asset('assets/images/kinex_logo.png', width: w * 0.52),
              ],
            ),
          ),
          // "Let's Start!" button — left-aligned per Figma (x:4.6%, y:72.8%)
          Positioned(
            left: w * 0.046,
            bottom: h * 0.185,
            child: GestureDetector(
                onTap: () => context.go('/login'),
                child: Container(
                  width: w * 0.54,
                  height: h * 0.09,
                  decoration: BoxDecoration(
                    gradient: KColors.greenGradient,
                    borderRadius: BorderRadius.circular(40),
                    border:
                        Border.all(color: Colors.white.withAlpha(115), width: 3),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x40000000),
                          blurRadius: 8,
                          offset: Offset(0, 4))
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_arrow_rounded,
                          color: Colors.white, size: w * 0.08),
                      const SizedBox(width: 8),
                      Text("Let's Start!",
                          style: montserrat(
                              size: w * 0.050,
                              weight: FontWeight.w900,
                              color: Colors.white)),
                    ],
                  ),
                ),
              ),
          ),
        ],
      ),
    );
  }
}
