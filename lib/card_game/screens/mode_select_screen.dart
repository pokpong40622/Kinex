import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/kawaii_widgets.dart';
import '../widgets/mascot_painter.dart';
import 'multiple_choice_screen.dart';
import 'true_false_screen.dart';
import 'matching_screen.dart';

class ModeSelectScreen extends StatelessWidget {
  final Topic topic;
  const ModeSelectScreen({super.key, required this.topic});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CenteredGameArea(
          maxWidth: 1100,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KawaiiTopBar(
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AppColors.ink,
                          size: 34,
                        ),
                      ),
                      MascotIcon(
                        type: topic.mascot,
                        size: 78,
                        accent: topic.color,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              topic.title.replaceAll('\n', ' '),
                              style: AppTheme.heading(size: 32),
                            ),
                            Text(
                              'อยากเล่นแบบไหนดีคะ?',
                              style: AppTheme.body(
                                size: 23,
                                color: AppColors.inkLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 700;
                      final cards = [
                        _ModeCard(
                          title: 'ข้อ ก ข ค ง',
                          subtitle: 'เลือกคำตอบที่ใช่ 1 ใน 4',
                          icon: Icons.check_box_rounded,
                          color: topic.color,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  MultipleChoiceScreen(topic: topic),
                            ),
                          ),
                        ),
                        _ModeCard(
                          title: 'ถูก หรือ ผิด',
                          subtitle: 'ตอบง่ายๆ แค่ถูกกับผิด',
                          icon: Icons.thumb_up_alt_rounded,
                          color: topic.color,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => TrueFalseScreen(topic: topic),
                            ),
                          ),
                        ),
                        _ModeCard(
                          title: 'จับคู่การ์ด',
                          subtitle: 'โยงเรื่องกับวิธีดูแล',
                          icon: Icons.link_rounded,
                          color: topic.color,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => MatchingScreen(topic: topic),
                            ),
                          ),
                        ),
                      ];
                      if (isWide) {
                        return Row(
                          children: cards
                              .map(
                                (c) => Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: c,
                                  ),
                                ),
                              )
                              .toList(),
                        );
                      }
                      return ListView.separated(
                        itemCount: cards.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 14),
                        itemBuilder: (_, i) => cards[i],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return KawaiiCard(
      borderColor: color,
      borderWidth: 9,
      onTap: onTap,
      padding: const EdgeInsets.all(28),
      child: SizedBox(
        height: 220,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 42),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTheme.body(size: 27, weight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTheme.body(size: 21, color: AppColors.inkLight),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
