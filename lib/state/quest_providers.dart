import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_quest.dart';
import 'shop_providers.dart';

/// ภารกิจ — four fixed daily quests. Progress resets at midnight, same
/// self-reset-on-new-day idea as card_game's DailyProgressStore
/// (lib/card_game/services/daily_progress_store.dart): a stored "last seen
/// date" key gates whether the stored progress is still today's.
///
/// Fixed quest definitions: id, Thai title, target, coin reward. Order is the
/// display order on the quest page.
// Rewards scaled up so a few days of daily quests can afford a shop game
// unlock (600-1000 coins, see shop_page.dart's _GameUnlock prices): ~360
// coins/day total, keeping the original 2:1:4:2 ratio between quests.
const List<DailyQuest> _questDefinitions = [
  DailyQuest(
      id: QuestId.playGame,
      title: 'เล่นเกมฝึก 1 ครั้ง',
      target: 1,
      reward: 80,
      progress: 0),
  DailyQuest(
      id: QuestId.learnPose,
      title: 'เรียนท่าฝึก 1 ท่า',
      target: 1,
      reward: 50,
      progress: 0),
  DailyQuest(
      id: QuestId.assessment,
      title: 'ทำแบบประเมิน',
      target: 1,
      reward: 150,
      progress: 0),
  DailyQuest(
      id: QuestId.cardGame,
      title: 'เล่นการ์ดเรียนรู้',
      target: 1,
      reward: 80,
      progress: 0),
];

final dailyQuestsProvider =
    AsyncNotifierProvider<DailyQuestsNotifier, List<DailyQuest>>(
        DailyQuestsNotifier.new);

class DailyQuestsNotifier extends AsyncNotifier<List<DailyQuest>> {
  static const _dateKey = 'daily_quests_date';
  static const _progressKey = 'daily_quests_progress';

  @override
  Future<List<DailyQuest>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();

    final storedProgress = <String, int>{};
    if (prefs.getString(_dateKey) == today) {
      final raw = prefs.getString(_progressKey);
      if (raw != null) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        for (final entry in decoded.entries) {
          storedProgress[entry.key] = (entry.value as num).toInt();
        }
      }
    } else {
      // New day (or first run ever) — today's slate starts clean on disk too.
      await prefs.setString(_dateKey, today);
      await prefs.remove(_progressKey);
    }

    return _questDefinitions
        .map((q) => q.copyWith(progress: storedProgress[q.id.name] ?? 0))
        .toList();
  }

  /// Bumps [id]'s progress by [by] (clamped to target) and — only on the
  /// transition from not-done to done — awards its coin reward into
  /// [coinsProvider]. Already-done quests are a no-op, so repeat bumps (e.g.
  /// playing a second game the same day) never double-pay.
  Future<void> bump(QuestId id, {int by = 1}) async {
    final current = await future;
    final index = current.indexWhere((q) => q.id == id);
    if (index == -1) return;

    final quest = current[index];
    if (quest.done) return;

    final updated =
        quest.copyWith(progress: (quest.progress + by).clamp(0, quest.target));
    final next = [...current]..[index] = updated;
    state = AsyncData(next);
    await _persist(next);

    if (updated.done) {
      ref.read(coinsProvider.notifier).state += updated.reward;
    }
  }

  Future<void> _persist(List<DailyQuest> quests) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dateKey, _todayKey());
    final map = {for (final q in quests) q.id.name: q.progress};
    await prefs.setString(_progressKey, jsonEncode(map));
  }

  static String _todayKey() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }
}
