/// A completed arcade-game session (The Dasher / Hang Glider), persisted to the
/// unified game history. Built from each game's raw Unity results payload plus a
/// local id + timestamp. Mirrors WorldSessionRecord's shape and defensive JSON.
class GameSessionRecord {
  final String id;
  final DateTime dateTime;
  final String gameId;
  final String gameName;
  final String iconAsset;
  final double durationSeconds;
  final String scoreLabel; // human headline shown on the row
  final double percent; // 0..100 — drives band colour + week average

  const GameSessionRecord({
    required this.id,
    required this.dateTime,
    required this.gameId,
    required this.gameName,
    required this.iconAsset,
    required this.durationSeconds,
    required this.scoreLabel,
    required this.percent,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'dateTime': dateTime.toIso8601String(),
        'gameId': gameId,
        'gameName': gameName,
        'iconAsset': iconAsset,
        'durationSeconds': durationSeconds,
        'scoreLabel': scoreLabel,
        'percent': percent,
      };

  factory GameSessionRecord.fromJson(Map<String, dynamic> j) =>
      GameSessionRecord(
        id: j['id'] as String? ?? '',
        dateTime:
            DateTime.tryParse(j['dateTime'] as String? ?? '') ?? DateTime.now(),
        gameId: j['gameId'] as String? ?? '',
        gameName: j['gameName'] as String? ?? '',
        iconAsset: j['iconAsset'] as String? ?? '',
        durationSeconds: (j['durationSeconds'] as num?)?.toDouble() ?? 0,
        scoreLabel: j['scoreLabel'] as String? ?? '',
        percent: (j['percent'] as num?)?.toDouble() ?? 0,
      );

  /// Build a record from The Dasher's raw Unity result JSON. The Dasher has no
  /// natural %, so we map its star rating (0..3) onto a percent band.
  factory GameSessionRecord.fromDasher(
    Map<String, dynamic> j, {
    required String id,
    required DateTime dateTime,
  }) {
    final stars = (j['stars'] as num?)?.toInt() ?? 0;
    return GameSessionRecord(
      id: id,
      dateTime: dateTime,
      gameId: 'thedasher',
      gameName: 'THE DASHER',
      iconAsset: 'assets/images/game_icons/thedasher.png',
      durationSeconds: (j['durationSeconds'] as num?)?.toDouble() ?? 0,
      scoreLabel: '$stars★',
      percent: _starsToPercent(stars),
    );
  }

  /// Build a record from Hang Glider's raw Unity result JSON. Score is the count
  /// of correct answers out of a total, so percent is a natural ratio.
  factory GameSessionRecord.fromHangGlider(
    Map<String, dynamic> j, {
    required String id,
    required DateTime dateTime,
  }) {
    final score = (j['score'] as num?)?.toInt() ?? 0;
    final total = (j['total'] as num?)?.toInt() ?? 0;
    return GameSessionRecord(
      id: id,
      dateTime: dateTime,
      gameId: 'hangglider',
      gameName: 'นักร่อน',
      // No dedicated glider icon in assets/images/game_icons/ yet — fall back to
      // thedasher.png so the row never breaks. Swap when art lands.
      iconAsset: 'assets/images/game_icons/thedasher.png',
      durationSeconds: (j['durationSeconds'] as num?)?.toDouble() ?? 0,
      scoreLabel: '$score/$total',
      percent: total > 0 ? (score / total * 100) : 0,
    );
  }

  static double _starsToPercent(int stars) {
    switch (stars) {
      case 3:
        return 100;
      case 2:
        return 75;
      case 1:
        return 50;
      default:
        return 30;
    }
  }
}
