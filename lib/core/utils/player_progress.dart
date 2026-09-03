class LevelProgress {
  const LevelProgress({
    required this.level,
    required this.points,
    required this.currentFloor,
    required this.nextThreshold,
  });

  final int level;
  final int points;
  final int currentFloor;
  final int? nextThreshold;

  int get pointsIntoLevel => points - currentFloor;
  int? get pointsNeededForNext =>
      nextThreshold == null ? null : nextThreshold! - points;

  double get progressToNext {
    final cap = nextThreshold;
    if (cap == null) return 1;
    final span = cap - currentFloor;
    if (span <= 0) return 1;
    return (pointsIntoLevel / span).clamp(0.0, 1.0);
  }
}

abstract final class PlayerProgress {
  static const int correctAnswerPoints = 75;

  static LevelProgress forPoints(int points) {
    final safePoints = points < 0 ? 0 : points;

    // 1. Calculate Level (matches getLevel logic exactly)
    int level;
    if (safePoints <= 200) {
      level = 0;
    } else if (safePoints <= 1000) {
      level = 1;
    } else if (safePoints <= 2000) {
      level = 2;
    } else if (safePoints <= 3300) {
      level = 3;
    } else if (safePoints <= 5000) {
      level = 4;
    } else if (safePoints <= 8500) {
      level = 5;
    } else if (safePoints <= 12600) {
      level = 6;
    } else if (safePoints <= 16000) {
      level = 7;
    } else if (safePoints <= 21000) {
      level = 8;
    } else if (safePoints <= 28000) {
      level = 9;
    } else if (safePoints <= 40000) {
      level = 10;
    } else if (safePoints <= 60000) {
      level = 11;
    } else if (safePoints <= 80000) {
      level = 12;
    } else if (safePoints <= 100000) {
      level = 13;
    } else if (safePoints <= 130000) {
      level = 14;
    } else if (safePoints <= 170000) {
      level = 15;
    } else if (safePoints <= 220000) {
      level = 16;
    } else if (safePoints <= 280000) {
      level = 17;
    } else if (safePoints <= 350000) {
      level = 18;
    } else if (safePoints <= 430000) {
      level = 19;
    } else if (safePoints <= 520000) {
      level = 20;
    } else {
      level = 20 + ((safePoints - 520000) ~/ 25000);
    }

    // 2. Define floors / next thresholds (matches getLevel boundaries)
    final thresholds = [
      0,      // Level 0 starts at 0
      201,    // Level 1 starts at 201 (since <= 200 is level 0)
      1001,   // Level 2 starts at 1001
      2001,   // Level 3 starts at 2001
      3301,   // Level 4 starts at 3301
      5001,   // Level 5 starts at 5001
      8501,   // Level 6 starts at 8501
      12601,  // Level 7 starts at 12601
      16001,  // Level 8 starts at 16001
      21001,  // Level 9 starts at 21001
      28001,  // Level 10 starts at 28001
      40001,  // Level 11 starts at 40001
      60001,  // Level 12 starts at 60001
      80001,  // Level 13 starts at 80001
      100001, // Level 14 starts at 100001
      130001, // Level 15 starts at 130001
      170001, // Level 16 starts at 170001
      220001, // Level 17 starts at 220001
      280001, // Level 18 starts at 280001
      350001, // Level 19 starts at 350001
      430001, // Level 20 starts at 430001
      520001, // Level 21 starts at 520001 (since <= 520000 is level 20)
    ];

    int currentFloor;
    int? nextThreshold;

    if (level < thresholds.length - 1) {
      currentFloor = thresholds[level];
      nextThreshold = thresholds[level + 1] - 1; // back to <= threshold mapping
    } else {
      // Level 20+ progression
      final extraLevels = level - 20;
      currentFloor = 520001 + (extraLevels * 25000);
      nextThreshold = 520000 + ((extraLevels + 1) * 25000);
    }

    return LevelProgress(
      level: level,
      points: safePoints,
      currentFloor: currentFloor,
      nextThreshold: nextThreshold,
    );
  }
}
