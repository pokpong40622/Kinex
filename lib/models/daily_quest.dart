/// The daily quests. Order here is display order on the quest page.
enum QuestId {
  playGame,
  playTwoGames,
  learnPose,
  learnTwoPoses,
  assessment,
  cardGame,
  cardGameScore,
  emgCheck,
}

/// One daily quest: a fixed title/target/reward plus today's progress.
/// Frozen shape — another agent codes against this, do not change field names.
class DailyQuest {
  final QuestId id;
  final String title; // Thai
  final int reward; // coins
  final int target;
  final int progress;

  /// Which action advances this quest. Defaults to the quest's own [id], so a
  /// quest normally advances when something calls `bump(itsOwnId)`.
  ///
  /// Setting it to ANOTHER quest's id lets several quests share one action —
  /// "play a game" and "play two games" are the same event counted to
  /// different targets. That keeps the tiering in this one file instead of
  /// making every call site remember to bump a second quest (and it means new
  /// tiers need no call-site edits at all).
  final QuestId? trigger;

  const DailyQuest({
    required this.id,
    required this.title,
    required this.reward,
    required this.target,
    required this.progress,
    this.trigger,
  });

  QuestId get triggerId => trigger ?? id;

  bool get done => progress >= target;

  DailyQuest copyWith({int? progress}) => DailyQuest(
        id: id,
        title: title,
        reward: reward,
        target: target,
        progress: progress ?? this.progress,
        trigger: trigger,
      );
}
