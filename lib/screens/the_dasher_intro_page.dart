// Tutorial popups for "The Dasher" (Unity scene id "thedasher" — UI
// name only). Shown once before the game screen so the player sees the 3
// pre-designed instruction graphics before launching Unity.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';

class TheDasherIntroPage extends StatefulWidget {
  const TheDasherIntroPage({super.key});

  @override
  State<TheDasherIntroPage> createState() => _TheDasherIntroPageState();
}

class _TheDasherIntroPageState extends State<TheDasherIntroPage> {
  final _controller = PageController();
  int _page = 0;

  static const _images = [
    'assets/images/the_dasher/intro_move.png',
    'assets/images/the_dasher/intro_treasure.png',
    'assets/images/the_dasher/intro_kick.png',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _exit() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  void _onBack() {
    if (_page == 0) {
      _exit();
    } else {
      _goTo(_page - 1);
    }
  }

  void _onNext() {
    if (_page == _images.length - 1) {
      context.pushReplacement('/the-dasher-start');
    } else {
      _goTo(_page + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _images.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F3FA),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: context.r(8)),
            // Top row: close button + small logo header.
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.r(16)),
              child: Row(
                children: [
                  _NavButton(
                    icon: Icons.close_rounded,
                    onTap: _exit,
                    size: context.r(44),
                  ),
                  Expanded(
                    child: Center(
                      child: Image.asset(
                        'assets/images/the_dasher/logo.png',
                        height: context.r(40),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  SizedBox(width: context.r(44)),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _images.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, index) => Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: context.r(24), vertical: context.r(12)),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(context.r(18)),
                    child: Image.asset(
                      _images[index],
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: context.r(24), vertical: context.r(20)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _NavButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: _onBack,
                  ),
                  Row(
                    children: List.generate(
                      _images.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: EdgeInsets.symmetric(horizontal: context.r(4)),
                        width: i == _page ? context.r(22) : context.r(8),
                        height: context.r(8),
                        decoration: BoxDecoration(
                          color: i == _page
                              ? KColors.deepPurple
                              : Colors.grey.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(context.r(6)),
                        ),
                      ),
                    ),
                  ),
                  isLast
                      ? _StartButton(onTap: _onNext)
                      : _NavButton(
                          icon: Icons.arrow_forward_ios_rounded,
                          onTap: _onNext,
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Circular back/next control used on the intro pager.
class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double? size;
  const _NavButton({required this.icon, required this.onTap, this.size});

  @override
  Widget build(BuildContext context) {
    final s = size ?? context.r(52);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: s,
        height: s,
        decoration: BoxDecoration(
          color: KColors.deepPurple,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: KColors.deepPurple.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: s * 0.4),
      ),
    );
  }
}

/// Wide pill "play" button shown on the last intro page.
class _StartButton extends StatelessWidget {
  final VoidCallback onTap;
  const _StartButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: context.r(52),
        padding: EdgeInsets.symmetric(horizontal: context.r(22)),
        decoration: BoxDecoration(
          color: KColors.deepPurple,
          borderRadius: BorderRadius.circular(context.r(26)),
          boxShadow: [
            BoxShadow(
              color: KColors.deepPurple.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_arrow_rounded,
                color: Colors.white, size: context.r(22)),
            SizedBox(width: context.r(6)),
            Text('เริ่มเล่น',
                style: thaiSans(
                    size: context.r(16),
                    weight: FontWeight.w700,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
