import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

/// Entry point for the embedded "การ์ดเรียนรู้ ทรงตัวดี ไม่หกล้ม" card game.
///
/// The card game was originally its own [MaterialApp]; inside Kinex it is a
/// single screen reached from the Home tab. This wrapper restores the two
/// things the standalone app used to provide: the image backdrop and the card
/// game's own [ThemeData] (Kanit font, transparent scaffolds, warm palette).
/// A back button is added since the game no longer owns the app root.
class CardGameScreen extends StatelessWidget {
  const CardGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.theme,
      child: _ImageBackdrop(
        child: Stack(
          children: [
            const HomeScreen(),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    color: Colors.white.withValues(alpha: .92),
                    shape: const CircleBorder(),
                    elevation: 2,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: AppColors.ink),
                      tooltip: 'กลับ',
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageBackdrop extends StatelessWidget {
  final Widget child;
  const _ImageBackdrop({required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const RepaintBoundary(
          child: Image(
            image: AssetImage('assets/fonts/Background.png'),
            fit: BoxFit.cover,
            filterQuality: FilterQuality.low,
          ),
        ),
        child,
      ],
    );
  }
}
