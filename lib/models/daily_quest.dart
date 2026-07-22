/// The four daily quests. Order here is display order on the quest page.
enum QuestId { playGame, learnPose, assessment, cardGame }

/// One daily quest: a fixed title/target/reward plus today's progress.
/// Frozen shape — another agent codes against this, do not change field names.
class DailyQuest {
  final QuestId id;
  final String title; // Thai
  final int reward; // coins
  final int target;
  final int progress;

  const DailyQuest({
    required this.id,
    required this.title,
    required this.reward,
    required this.target,
    required this.progress,
  });

  bool get done => progress >= target;

  DailyQuest copyWith({int? progress}) => DailyQuest(
        id: id,
        title: title,
        reward: reward,
        target: target,
        progress: progress ?? this.progress,
      );
}
