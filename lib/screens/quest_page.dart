import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/daily_quest.dart';
import '../state/quest_providers.dart';
import '../theme/app_theme.dart';

/// ภารกิจ — the full list of daily quests, driven by [dailyQuestsProvider].
/// Home shows only the first few (see `_homePanelQuests`); this page shows all
/// of them, so it scrolls.
///
/// This used to be the second bottom-nav tab, and it drew three fixed PNG cards
/// with hardcoded progress. It now reads real progress that auto-completes as
/// the user plays a game, learns a pose, finishes an assessment, or plays the
/// card game — and pays coins into the shop balance on completion. Quests moved
/// off the nav bar to a Home card + this pushed route; เรียนรู้ owns the slot.
class QuestPage extends ConsumerWidget {
  const QuestPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    final h = size.height;
    final quests = ref.watch(dailyQuestsProvider);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/bg_room.png', fit: BoxFit.cover),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(w * 0.03, h * 0.012, w * 0.06, 0),
                  child: Row(
                    children: [
                      // Pushed route now, so it owns its own way back.
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, size: 28),
                        color: KColors.navyText,
                        tooltip: 'กลับ',
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding:
                      EdgeInsets.fromLTRB(w * 0.06, h * 0.005, w * 0.06, h * 0.02),
                  child: Text(
                    'Complete\nYour Quest',
                    textAlign: TextAlign.left,
                    style: nunito(size: w * 0.085, weight: FontWeight.w900),
                  ),
                ),
                Expanded(
                  child: quests.when(
                    loading: () => const Center(
                        child: CircularProgressIndicator(color: Colors.white)),
                    error: (_, _) => Center(
                      child: Text('โหลดภารกิจไม่สำเร็จ',
                          style: thaiSans(size: w * 0.04, color: Colors.white)),
                    ),
                    data: (list) {
                      final done = list.where((q) => q.done).length;
                      return ListView(
                        padding: EdgeInsets.fromLTRB(
                            w * 0.05, 0, w * 0.05, h * 0.03),
                        children: [
                          _QuestSummary(done: done, total: list.length),
                          SizedBox(height: h * 0.02),
                          for (final q in list) ...[
                            _QuestRow(quest: q),
                            SizedBox(height: h * 0.016),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A short "N of 4 done today" banner above the list, with an overall bar so the
/// day's progress reads at a glance before scanning the individual quests.
class _QuestSummary extends StatelessWidget {
  final int done;
  final int total;
  const _QuestSummary({required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final allDone = done >= total && total > 0;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.05, vertical: w * 0.045),
      decoration: cardDecoration(radius: 22, color: Colors.white),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(w * 0.03),
            decoration: BoxDecoration(
              color: (allDone ? KColors.greenDark : KColors.blue)
                  .withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              allDone ? Icons.emoji_events_rounded : Icons.today_rounded,
              color: allDone ? KColors.greenDark : KColors.blue,
              size: w * 0.07,
            ),
          ),
          SizedBox(width: w * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ภารกิจวันนี้',
                    style: thaiSans(
                        size: w * 0.045,
                        weight: FontWeight.w800,
                        color: KColors.navyText)),
                SizedBox(height: w * 0.015),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0 : done / total,
                    minHeight: w * 0.022,
                    backgroundColor: const Color(0xFFE7EAF2),
                    valueColor: AlwaysStoppedAnimation(
                        allDone ? KColors.greenDark : KColors.blue),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: w * 0.04),
          Text('$done/$total',
              style: montserrat(
                  size: w * 0.05,
                  weight: FontWeight.w900,
                  color: allDone ? KColors.greenDark : KColors.navyText)),
        ],
      ),
    );
  }
}

/// One quest as a flat white card: state icon, Thai title + progress bar, and a
/// coin-reward pill that flips to a "รับแล้ว" tick once the quest is complete.
class _QuestRow extends StatelessWidget {
  final DailyQuest quest;
  const _QuestRow({required this.quest});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final done = quest.done;
    final accent = done ? KColors.greenDark : KColors.blue;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.045, vertical: w * 0.04),
      decoration: cardDecoration(radius: 20, color: Colors.white),
      child: Row(
        children: [
          Icon(
            done
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: done ? KColors.greenDark : const Color(0xFFB9C0D0),
            size: w * 0.075,
          ),
          SizedBox(width: w * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(quest.title,
                    style: thaiSans(
                        size: w * 0.042,
                        weight: FontWeight.w700,
                        color: done
                            ? const Color(0xFF8A93A6)
                            : KColors.navyText)),
                SizedBox(height: w * 0.02),
                _QuestProgressBar(
                  progress: quest.target == 0 ? 0 : quest.progress / quest.target,
                  fillColors: [accent],
                ),
              ],
            ),
          ),
          SizedBox(width: w * 0.035),
          _RewardPill(reward: quest.reward, claimed: done),
        ],
      ),
    );
  }
}

/// Coin reward. Shows "+N 🪙" while pending, a green รับแล้ว tick when earned.
class _RewardPill extends StatelessWidget {
  final int reward;
  final bool claimed;
  const _RewardPill({required this.reward, required this.claimed});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final bg = claimed ? KColors.greenDark : KColors.orange;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.03, vertical: w * 0.018),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: claimed ? 0.15 : 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            claimed ? Icons.check_rounded : Icons.monetization_on_rounded,
            size: w * 0.045,
            color: claimed ? KColors.greenDark : KColors.orangeDark,
          ),
          SizedBox(width: w * 0.012),
          Text(
            claimed ? 'รับแล้ว' : '+$reward',
            style: montserrat(
                size: w * 0.035,
                weight: FontWeight.w800,
                color: claimed ? KColors.greenDark : KColors.orangeDark),
          ),
        ],
      ),
    );
  }
}

/// Thin rounded progress bar, unchanged from the old quest cards so the page
/// keeps its visual language.
class _QuestProgressBar extends StatelessWidget {
  final double progress;
  final List<Color> fillColors;

  const _QuestProgressBar({required this.progress, required this.fillColors});

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: h * 0.012,
        color: const Color(0xFFE7EAF2),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              decoration: fillColors.length > 1
                  ? BoxDecoration(gradient: LinearGradient(colors: fillColors))
                  : BoxDecoration(color: fillColors.first),
            ),
          ),
        ),
      ),
    );
  }
}
