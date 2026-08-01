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
//
// The "do it twice" tiers are deliberately worth LESS than their first tier
// even though they are harder: clearing every quest in one day now pays 580,
// still under the cheapest game unlock (600), so a shop unlock stays a
// multi-day goal rather than something a single big session buys outright.
const List<DailyQuest> _questDefinitions = [
  DailyQuest(
      id: QuestId.playGame,
      title: 'เล่นเกมฝึก 1 ครั้ง',
      target: 1,
      reward: 80,
      progress: 0),
  // Same event as playGame, counted to a higher target — see DailyQuest.trigger.
  DailyQuest(
      id: QuestId.playTwoGames,
      title: 'เล่นเกมฝึกให้ครบ 2 ครั้ง',
      target: 2,
      reward: 60,
      progress: 0,
      trigger: QuestId.playGame),
  DailyQuest(
      id: QuestId.learnPose,
      title: 'เรียนท่าฝึก 1 ท่า',
      target: 1,
      reward: 50,
      progress: 0),
  DailyQuest(
      id: QuestId.learnTwoPoses,
      title: 'เรียนท่าฝึก 2 ท่า',
      target: 2,
      reward: 40,
      progress: 0,
      trigger: QuestId.learnPose),
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
  // Bumped by the number of CORRECT answers, so it rewards doing well rather
  // than just finishing a round (which QuestId.cardGame already covers).
  DailyQuest(
      id: QuestId.cardGameScore,
      title: 'ตอบการ์ดเรียนรู้ถูก 5 ข้อ',
      target: 5,
      reward: 60,
      progress: 0),
  DailyQuest(
      id: QuestId.emgCheck,
      title: 'ตรวจกล้ามเนื้อด้วยสายรัด EMG',
      target: 1,
      reward: 60,
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

  /// Records that the [id] action happened, advancing EVERY quest triggered by
  /// it by [by] (clamped to each target) — so one "played a game" call
  /// advances both the 1-game and the 2-game quest. Each quest awards its coins
  /// into [coinsProvider] only on its own not-done → done transition, and
  /// already-done quests are skipped, so repeat calls never double-pay.
  Future<void> bump(QuestId id, {int by = 1}) async {
    if (by <= 0) return;
    final current = await future;

    final next = [...current];
    final rewards = <int>[];
    for (var i = 0; i < next.length; i++) {
      final quest = next[i];
      if (quest.triggerId != id || quest.done) continue;

      final updated =
          quest.copyWith(progress: (quest.progress + by).clamp(0, quest.target));
      next[i] = updated;
      if (updated.done) rewards.add(updated.reward);
    }
    if (rewards.isEmpty && _sameProgress(current, next)) return;

    state = AsyncData(next);
    await _persist(next);

    for (final reward in rewards) {
      ref.read(coinsProvider.notifier).state += reward;
    }
  }

  static bool _sameProgress(List<DailyQuest> a, List<DailyQuest> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i].progress != b[i].progress) return false;
    }
    return true;
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
