import 'package:flutter/material.dart';
import '../data/content.dart';
import '../models/models.dart';
import '../services/daily_progress_store.dart';
import '../theme/app_theme.dart';
import '../widgets/kawaii_widgets.dart';
import '../widgets/mascot_painter.dart';
import 'mode_select_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DailyProgress _progress = const DailyProgress(
    points: 0,
    goal: DailyProgressStore.dailyGoal,
  );

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final progress = await DailyProgressStore.today();
    if (!mounted) return;
    setState(() => _progress = progress);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CenteredGameArea(
          maxWidth: 1120,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 1100
                  ? 3
                  : constraints.maxWidth > 720
                  ? 2
                  : 1;
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 88),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _HomeHero(),
                    const SizedBox(height: 14),
                    _DailyProgressCard(progress: _progress),
                    const SizedBox(height: 48),
                    const _TopicSectionHeader(),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: crossAxisCount,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: constraints.maxWidth > 1100
                          ? 1.12
                          : 1.18,
                      children: topics
                          .map(
                            (topic) => _TopicCard(
                              topic: topic,
                              onReturn: _loadProgress,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HomeHero extends StatelessWidget {
  const _HomeHero();

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 154),
      child: KawaiiCard(
        borderColor: AppColors.lavenderDark,
        borderWidth: 7,
        radius: 30,
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
        fillColor: Colors.white.withValues(alpha: .97),
        child: Row(
          children: [
            const MascotIcon(
              type: MascotType.buddy,
              size: 82,
              accent: AppColors.lavenderDark,
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'การ์ดเรียนรู้ ทรงตัวดี ไม่หกล้ม',
                    style: AppTheme.heading(size: 36),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'เลือกหัวข้อ แล้วเริ่มเล่นแบบสบาย ๆ ได้เลยค่ะ',
                    style: AppTheme.body(
                      size: 17,
                      weight: FontWeight.w700,
                      color: AppColors.inkLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.happyGreen.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.happyGreen, width: 4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.touch_app_rounded,
                    color: AppColors.happyGreen,
                    size: 26,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'แตะการ์ดเพื่อเริ่ม',
                    style: AppTheme.body(
                      size: 16,
                      weight: FontWeight.w800,
                      color: AppColors.happyGreen,
                    ),
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

class _TopicSectionHeader extends StatelessWidget {
  const _TopicSectionHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.orange,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            'เลือกหัวข้อเพื่อเริ่มเล่น',
            style: AppTheme.heading(size: 26, color: AppColors.ink),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .96),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.orange, width: 4),
          ),
          child: Text(
            '${topics.length} หัวข้อ',
            style: AppTheme.body(
              size: 15,
              weight: FontWeight.w800,
              color: AppColors.orange,
            ),
          ),
        ),
      ],
    );
  }
}

class _DailyProgressCard extends StatelessWidget {
  final DailyProgress progress;

  const _DailyProgressCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    final remaining = (progress.goal - progress.points).clamp(0, progress.goal);
    final message = progress.isComplete
        ? 'ครบเป้าหมายวันนี้แล้ว เก่งมากค่ะ!'
        : 'อีก $remaining แต้ม จะครบเป้าหมายรายวัน';

    return KawaiiCard(
      borderColor: AppColors.happyGreen,
      borderWidth: 7,
      radius: 28,
      padding: const EdgeInsets.all(16),
      fillColor: Colors.white.withValues(alpha: .96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  color: AppColors.lavenderSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: AppColors.happyGreen,
                  size: 30,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('แต้มสุขภาพวันนี้', style: AppTheme.heading(size: 21)),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: AppTheme.body(
                        size: 16,
                        weight: FontWeight.w700,
                        color: AppColors.inkLight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Text(
                '${progress.points} / ${progress.goal}',
                style: AppTheme.heading(size: 22, color: AppColors.happyGreen),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: LinearProgressIndicator(
              value: progress.ratio,
              minHeight: 18,
              backgroundColor: AppColors.happyGreen.withValues(alpha: .16),
              valueColor: const AlwaysStoppedAnimation(AppColors.happyGreen),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ตอบถูก 1 ข้อ ได้ ${DailyProgressStore.pointsPerCorrectAnswer} แต้ม',
            style: AppTheme.body(size: 14, color: AppColors.inkLight),
          ),
        ],
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  final Topic topic;
  final VoidCallback onReturn;

  const _TopicCard({required this.topic, required this.onReturn});

  @override
  Widget build(BuildContext context) {
    return KawaiiCard(
      borderColor: topic.color,
      borderWidth: 7,
      radius: 28,
      padding: const EdgeInsets.all(14),
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ModeSelectScreen(topic: topic)),
        );
        onReturn();
      },
      child: Column(
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: topic.color.withValues(alpha: .12),
              shape: BoxShape.circle,
              border: Border.all(color: topic.color, width: 4),
            ),
            child: Center(
              child: MascotIcon(
                type: topic.mascot,
                size: 62,
                accent: topic.color,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            topic.title,
            textAlign: TextAlign.center,
            style: AppTheme.body(size: 18, weight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            topic.subtitle,
            textAlign: TextAlign.center,
            style: AppTheme.body(
              size: 14,
              weight: FontWeight.w700,
              color: AppColors.inkLight,
            ),
          ),
          const Spacer(),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: topic.color,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: topic.color.withValues(alpha: .35),
                  blurRadius: 0,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'แตะเริ่ม',
                  style: AppTheme.body(
                    size: 16,
                    weight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
