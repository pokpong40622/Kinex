import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/kawaii_widgets.dart';

/// Entry point for the embedded "การ์ดเรียนรู้ ทรงตัวดี ไม่หกล้ม" card game.
///
/// The card game was originally its own [MaterialApp]; inside Kinex it is a
/// single screen reached from the Home tab. This wrapper restores the two
/// things the standalone app used to provide: the image backdrop and the card
/// game's own [ThemeData] (Kanit font, transparent scaffolds, warm palette).
/// A back button is added since the game no longer owns the app root.
///
/// Unlike the rest of the app (locked portrait in main.dart, since the other
/// screens' layouts are portrait-only), the card game is comfortable in
/// landscape too, so orientation is unlocked on entry and restored to the
/// app default on exit.
class CardGameScreen extends StatefulWidget {
  const CardGameScreen({super.key});

  @override
  State<CardGameScreen> createState() => _CardGameScreenState();
}

class _CardGameScreenState extends State<CardGameScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    // Restore the app-wide portrait lock (see main.dart) on the way out.
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.theme,
      child: CardGameBackground(
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
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.ink,
                      ),
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
