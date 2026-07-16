// "The Dasher" mission-briefing screen (Unity scene id stays "astrostance" —
// UI name only). Shown once between the tutorial and the embedded Unity game,
// replacing the start/mission screen Unity used to render itself.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';

class TheDasherStartPage extends StatelessWidget {
  const TheDasherStartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(
            child: Image(
              image: AssetImage('assets/images/the_dasher/start_bg.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: context.r(20), vertical: context.r(12)),
              child: Column(
                children: [
                  Row(
                    children: [
                      _NavButton(
                        icon: Icons.arrow_back_rounded,
                        onTap: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/home');
                          }
                        },
                      ),
                      const Spacer(),
                      const _StarBadge(),
                    ],
                  ),
                  SizedBox(height: context.r(8)),
                  Image.asset(
                    'assets/images/the_dasher/wordmark.png',
                    height: context.r(120),
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: context.r(6)),
                  Text(
                    'ภารกิจเก็บสมบัติในสวน',
                    textAlign: TextAlign.center,
                    style: thaiSans(
                      size: context.r(19),
                      weight: FontWeight.w800,
                      color: const Color(0xFF1F3A17),
                    ).copyWith(shadows: const [
                      Shadow(blurRadius: 4, color: Colors.white),
                      Shadow(blurRadius: 8, color: Colors.white),
                      Shadow(blurRadius: 12, color: Colors.white),
                    ]),
                  ),
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _InstructionCard(
                          badgeColor: const Color(0xFFE0559E),
                          icon: Icons.directions_walk_rounded,
                          caption: 'ก้าวข้าง\nหลบก้อนหิน',
                        ),
                      ),
                      SizedBox(width: context.r(10)),
                      Expanded(
                        child: _InstructionCard(
                          badgeColor: const Color(0xFF5FAE4E),
                          icon: Icons.airline_seat_legroom_normal_rounded,
                          caption: 'นั่งแล้วลุก\nเก็บสมบัติ',
                        ),
                      ),
                      SizedBox(width: context.r(10)),
                      Expanded(
                        child: _InstructionCard(
                          badgeColor: const Color(0xFF3E9BDB),
                          icon: Icons.sports_martial_arts_rounded,
                          caption: 'เตะวงแหวน\nจากเลนข้าง ๆ',
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  _StartMissionButton(
                    onTap: () =>
                        context.pushReplacement('/astro-stance'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Decorative gold-star badge shown in the top-right corner. Not tappable.
class _StarBadge extends StatelessWidget {
  const _StarBadge();

  @override
  Widget build(BuildContext context) {
    final s = context.r(52);
    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        color: const Color(0xFF9BC96B),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: context.r(3)),
        boxShadow: const [
          BoxShadow(color: Color(0x22000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Icon(Icons.star_rounded, color: Colors.amber, size: s * 0.55),
    );
  }
}

/// Small white circular nav button (back/close), matches learn_library_page's
/// _BackButton styling.
class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: context.r(44),
        height: context.r(44),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(color: Color(0x22000000), blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Icon(icon, size: context.r(22), color: KColors.navyText),
      ),
    );
  }
}

/// One of the 3 white instruction cards (icon badge + 2-line caption).
class _InstructionCard extends StatelessWidget {
  final Color badgeColor;
  final IconData icon;
  final String caption;
  const _InstructionCard({
    required this.badgeColor,
    required this.icon,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    final badgeSize = context.r(52);
    return Container(
      padding: EdgeInsets.all(context.r(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x22000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: badgeSize,
            height: badgeSize,
            decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: badgeSize * 0.55),
          ),
          SizedBox(height: context.r(8)),
          Text(
            caption,
            textAlign: TextAlign.center,
            style: thaiSans(
              size: context.r(12.5),
              weight: FontWeight.w700,
              color: KColors.navyText,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom-of-screen green gradient pill CTA — "เริ่มภารกิจ".
class _StartMissionButton extends StatelessWidget {
  final VoidCallback onTap;
  const _StartMissionButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: context.r(58),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(context.r(29)),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6FCF52), Color(0xFF3FA332)],
              ),
              borderRadius: BorderRadius.circular(context.r(29)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3FA332).withValues(alpha: 0.45),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'เริ่มภารกิจ',
                style: thaiSans(
                  size: context.r(18),
                  weight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
