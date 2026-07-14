import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';
import '../../theme/responsive.dart';

// ─── Page ────────────────────────────────────────────────────────────────────

class GameDebugPage extends StatelessWidget {
  const GameDebugPage({super.key});

  @override
  Widget build(BuildContext context) {
    final r = context.r;

    return Scaffold(
      backgroundColor: KColors.cardBg,
      appBar: AppBar(
        backgroundColor: KColors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Game Debug',
          style: montserrat(size: r(18), color: Colors.white),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(r(16)),
        children: [
          _GameCard(
            icon: Icons.music_note_rounded,
            titleTh: 'MEGA DANCE',
            subtitleEn: 'MEGA DANCE',
            r: r,
            // go, not push: these game routes live inside the ShellRoute while this
            // page is top-level — pushing them stacks a second shell page with the
            // same key and trips the navigator's duplicate-key assertion.
            onTap: () => context.go('/mega-dance/game'),
          ),
          SizedBox(height: r(12)),
          _GameCard(
            icon: Icons.self_improvement_rounded,
            titleTh: 'KINEX World',
            subtitleEn: 'KINEX World',
            r: r,
            onTap: () => context.go('/world/game/daily_class'),
          ),
          SizedBox(height: r(12)),
          _GameCard(
            icon: Icons.eco_rounded,
            titleTh: 'สวนผลไม้ — เกมลุกยืน',
            subtitleEn: 'Fruit Header',
            r: r,
            onTap: () => context.go('/fruit-game'),
          ),
          SizedBox(height: r(12)),
          _GameCard(
            icon: Icons.balance_rounded,
            titleTh: 'เส้นทางนักสมดุล — เกมทรงตัว',
            subtitleEn: 'Balance Quest',
            r: r,
            onTap: () => context.go('/balance-quest'),
          ),
          SizedBox(height: r(12)),
          _GameCard(
            icon: Icons.shield_moon_rounded,
            titleTh: 'ผู้พิทักษ์สวนสมดุล — เกมต่อสู้',
            subtitleEn: 'Guardian of Balance',
            r: r,
            onTap: () => context.go('/battle-game'),
          ),
          SizedBox(height: r(12)),
          _GameCard(
            icon: Icons.auto_awesome_rounded,
            titleTh: 'กระจกวิเศษ',
            subtitleEn: 'ทำท่าตามเงาในกระจก',
            r: r,
            onTap: () => context.go('/mirror-game'),
          ),
          SizedBox(height: r(20)),
          Center(
            child: Text(
              'สำหรับทดสอบเกมใหม่ (Debug)',
              style: thaiSans(size: r(13), color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Game Card ───────────────────────────────────────────────────────────────

class _GameCard extends StatelessWidget {
  final IconData icon;
  final String titleTh;
  final String subtitleEn;
  final double Function(double) r;
  final VoidCallback onTap;

  const _GameCard({
    required this.icon,
    required this.titleTh,
    required this.subtitleEn,
    required this.r,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(r(18)),
        onTap: onTap,
        child: Container(
          decoration: cardDecoration(radius: r(18)),
          padding: EdgeInsets.symmetric(horizontal: r(16), vertical: r(16)),
          child: Row(
            children: [
              Container(
                width: r(48),
                height: r(48),
                decoration: BoxDecoration(
                  color: KColors.teal.withAlpha(26), // ~10% opacity
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: KColors.teal, size: r(26)),
              ),
              SizedBox(width: r(14)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titleTh,
                      style: thaiSans(
                        size: r(16),
                        weight: FontWeight.w700,
                        color: KColors.navyText,
                      ),
                    ),
                    SizedBox(height: r(2)),
                    Text(
                      subtitleEn,
                      style: montserrat(
                        size: r(12),
                        weight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey, size: r(24)),
            ],
          ),
        ),
      ),
    );
  }
}
