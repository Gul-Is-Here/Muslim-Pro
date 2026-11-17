/// Everything the learner has earned, saved locally. Pure: every change returns a new value.
final class LearnProgress {
  const LearnProgress({
    this.completed = const {},
    this.xp = 0,
    this.hearts = maxHearts,
    this.heartsSince,
    this.daily = const {},
    this.chests = const {},
    this.quizDay,
  });

  factory LearnProgress.fromJson(Map<String, dynamic> j) => LearnProgress(
    completed: {
      if (j['completed'] case final List<dynamic> l)
        for (final id in l)
          if (id is String) id,
    },
    xp: _nat(j['xp']),
    hearts: _nat(j['hearts']).clamp(0, maxHearts),
    heartsSince: DateTime.tryParse('${j['heartsSince']}'),
    daily: {
      if (j['daily'] case final Map<dynamic, dynamic> m)
        for (final MapEntry(:key, :value) in m.entries)
          if (key is String) key: _nat(value),
    },
    chests: {
      if (j['chests'] case final List<dynamic> l)
        for (final id in l)
          if (id is String) id,
    },
    quizDay: j['quizDay'] as String?,
  );

  static const maxHearts = 10;
  static const heartEvery = Duration(minutes: 30);
  static const _keepDays = 60;

  final Set<String> completed;
  final int xp;

  /// Hearts at [heartsSince]; one regenerates every [heartEvery] after that.
  final int hearts;
  final DateTime? heartsSince;

  /// 'yyyy-mm-dd' → XP earned that day. Any entry counts as an active day for the streak.
  final Map<String, int> daily;
  final Set<String> chests;
  final String? quizDay;

  static String dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  int heartsAt(DateTime now) {
    final since = heartsSince;
    // No timer means no heart was ever lost: full, even if saved under an older, smaller cap.
    if (since == null || hearts >= maxHearts) return maxHearts;
    final regen = now.difference(since).inMinutes ~/ heartEvery.inMinutes;
    return (hearts + regen).clamp(0, maxHearts);
  }

  /// Time until the next heart, or null when full.
  Duration? nextHeartIn(DateTime now) {
    final since = heartsSince;
    if (heartsAt(now) >= maxHearts || since == null) return null;
    final elapsed = now.difference(since).inSeconds % heartEvery.inSeconds;
    return Duration(seconds: heartEvery.inSeconds - elapsed);
  }

  LearnProgress loseHeart(DateTime now) {
    final current = heartsAt(now);
    if (current == 0) return this;
    // Keep partial regeneration progress when already below max.
    final since = heartsSince;
    final carried = current < maxHearts && since != null
        ? now.subtract(Duration(seconds: now.difference(since).inSeconds % heartEvery.inSeconds))
        : now;
    return _copy(hearts: current - 1, heartsSince: carried);
  }

  /// Level n starts at 50·n·(n−1) XP: 0, 100, 300, 600, 1000, …
  static int levelFor(int xp) {
    var n = 1;
    while (xp >= 50 * (n + 1) * n) {
      n++;
    }
    return n;
  }

  int get level => levelFor(xp);
  int get levelStart => 50 * level * (level - 1);
  int get levelEnd => 50 * (level + 1) * level;
  double get levelProgress => (xp - levelStart) / (levelEnd - levelStart);

  int xpOn(DateTime day) => daily[dayKey(day)] ?? 0;
  bool activeOn(DateTime day) => daily.containsKey(dayKey(day));

  /// Consecutive active days ending today (or yesterday, so it survives until today's lesson).
  int streak(DateTime now) {
    var day = DateTime(now.year, now.month, now.day);
    if (!activeOn(day)) day = DateTime(day.year, day.month, day.day - 1);
    var n = 0;
    while (activeOn(day)) {
      n++;
      day = DateTime(day.year, day.month, day.day - 1);
    }
    return n;
  }

  LearnProgress earn(int amount, DateTime now) {
    final key = dayKey(now);
    final cutoff = dayKey(now.subtract(const Duration(days: _keepDays)));
    return _copy(
      xp: xp + amount,
      daily: {
        for (final e in daily.entries)
          if (e.key.compareTo(cutoff) > 0) e.key: e.value,
        key: (daily[key] ?? 0) + amount,
      },
    );
  }

  LearnProgress complete(String lessonId, int amount, DateTime now) =>
      earn(amount, now)._copy(completed: {...completed, lessonId});

  LearnProgress claimChest(String unitId, int amount, DateTime now) =>
      chests.contains(unitId) ? this : earn(amount, now)._copy(chests: {...chests, unitId});

  bool quizDoneOn(DateTime now) => quizDay == dayKey(now);

  LearnProgress finishQuiz(int amount, DateTime now) =>
      earn(amount, now)._copy(quizDay: dayKey(now));

  Map<String, dynamic> toJson() => {
    'completed': completed.toList(),
    'xp': xp,
    'hearts': hearts,
    'heartsSince': heartsSince?.toIso8601String(),
    'daily': daily,
    'chests': chests.toList(),
    'quizDay': quizDay,
  };

  LearnProgress _copy({
    Set<String>? completed,
    int? xp,
    int? hearts,
    DateTime? heartsSince,
    Map<String, int>? daily,
    Set<String>? chests,
    String? quizDay,
  }) => LearnProgress(
    completed: completed ?? this.completed,
    xp: xp ?? this.xp,
    hearts: hearts ?? this.hearts,
    heartsSince: heartsSince ?? this.heartsSince,
    daily: daily ?? this.daily,
    chests: chests ?? this.chests,
    quizDay: quizDay ?? this.quizDay,
  );

  static int _nat(Object? v) => v is int && v > 0 ? v : 0;
}
