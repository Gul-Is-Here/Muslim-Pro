/// Preset adhkar. Arabic and transliteration are fixed; the meaning is translated
/// (`dhikr_<name>` key).
enum Dhikr {
  subhanallah('سُبْحَانَ ٱللَّٰهِ', 'SubhanAllah', postSalah: true),
  alhamdulillah('ٱلْحَمْدُ لِلَّٰهِ', 'Alhamdulillah', postSalah: true),
  allahuakbar('ٱللَّٰهُ أَكْبَرُ', 'Allahu Akbar', postSalah: true),
  astaghfirullah('أَسْتَغْفِرُ ٱللَّٰهَ', 'Astaghfirullah'),
  lailahaillallah('لَا إِلَٰهَ إِلَّا ٱللَّٰهُ', 'La ilaha illallah'),
  durood('ٱللَّٰهُمَّ صَلِّ عَلَىٰ مُحَمَّدٍ', 'Durood Sharif');

  Dhikr(this.arabic, this.transliteration, {this.postSalah = false});

  final String arabic;
  final String transliteration;

  /// Said after every prayer (the 33 × SubhanAllah / Alhamdulillah / Allahu Akbar Sunnah).
  final bool postSalah;

  String get meaningKey => 'dhikr_$name';
}

/// What a tap did, so the UI can give stronger feedback at milestones.
enum TasbeehStep { counted, roundDone, setDone }

typedef TasbeehSession = ({int count, DateTime at});

/// Counter state, persisted on every change. Daily totals feed "Today", the goal and the streak.
final class TasbeehState {
  const TasbeehState({
    this.dhikr = Dhikr.subhanallah,
    this.target = 33,
    this.count = 0,
    this.round = 1,
    this.session = 0,
    this.daily = const {},
    this.sessions = const [],
    this.haptics = true,
    this.sound = true,
  });

  factory TasbeehState.fromJson(Map<String, dynamic> j) => TasbeehState(
    dhikr: Dhikr.values.asNameMap()[j['dhikr']] ?? Dhikr.subhanallah,
    target: targets.contains(j['target']) ? j['target'] as int : 33,
    count: _nat(j['count']),
    round: _nat(j['round']).clamp(1, 3),
    session: _nat(j['session']),
    daily: {
      if (j['daily'] case final Map<dynamic, dynamic> m)
        for (final MapEntry(:key, :value) in m.entries)
          if (key is String) key: _nat(value),
    },
    sessions: [
      if (j['sessions'] case final List<dynamic> list)
        for (final s in list)
          if (s is Map && DateTime.tryParse('${s['at']}') != null)
            (count: _nat(s['count']), at: DateTime.parse('${s['at']}')),
    ],
    haptics: j['haptics'] != false,
    sound: j['sound'] != false,
  );

  static const targets = [33, 99, 100, 0]; // 0 = no limit
  static const dailyGoal = 300;
  static const _keepDays = 60;
  static const _keepSessions = 30;

  final Dhikr dhikr;
  final int target;
  final int count;
  final int round;
  final int session;
  final Map<String, int> daily; // 'yyyy-mm-dd' (local) → count
  final List<TasbeehSession> sessions; // newest first
  final bool haptics;
  final bool sound;

  bool get unlimited => target == 0;

  /// 33 is said three times (once per post-salah dhikr round); 99 and 100 are one set.
  int get rounds => target == 33 ? 3 : 1;

  /// Fraction of the current round, for the ring.
  double get progress => unlimited ? (count % 33) / 33 : (count / target).clamp(0, 1);

  static String dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  int totalOn(DateTime day) => daily[dayKey(day)] ?? 0;

  /// Consecutive days with any dhikr, ending today (or yesterday, so the streak survives
  /// until the user counts today).
  int streak(DateTime now) {
    var day = DateTime(now.year, now.month, now.day);
    if (totalOn(day) == 0) day = day.subtract(const Duration(days: 1));
    var n = 0;
    while (totalOn(day) > 0) {
      n++;
      day = DateTime(day.year, day.month, day.day - 1);
    }
    return n;
  }

  (TasbeehState, TasbeehStep) increment(DateTime now) {
    final next = count + 1;
    final daily = _bump(now, 1);
    if (unlimited || next < target) {
      return (_copy(count: next, session: session + 1, daily: daily), TasbeehStep.counted);
    }
    final setDone = round >= rounds;
    return (
      _copy(count: 0, round: setDone ? 1 : round + 1, session: session + 1, daily: daily),
      setDone ? TasbeehStep.setDone : TasbeehStep.roundDone,
    );
  }

  /// Takes back the last tap of the current round.
  TasbeehState undo(DateTime now) =>
      count == 0 ? this : _copy(count: count - 1, session: session - 1, daily: _bump(now, -1));

  TasbeehState reset() => _copy(count: 0, round: 1);

  TasbeehState select({Dhikr? dhikr, int? target}) =>
      _copy(dhikr: dhikr ?? this.dhikr, target: target ?? this.target, count: 0, round: 1);

  TasbeehState toggles({bool? haptics, bool? sound}) =>
      _copy(haptics: haptics ?? this.haptics, sound: sound ?? this.sound);

  /// Logs the session total and starts a new session. No-op when nothing was counted.
  TasbeehState finish(DateTime now) => session == 0
      ? this
      : _copy(
          session: 0,
          count: 0,
          round: 1,
          sessions: [(count: session, at: now), ...sessions].take(_keepSessions).toList(),
        );

  Map<String, dynamic> toJson() => {
    'dhikr': dhikr.name,
    'target': target,
    'count': count,
    'round': round,
    'session': session,
    'daily': daily,
    'sessions': [
      for (final s in sessions) {'count': s.count, 'at': s.at.toIso8601String()},
    ],
    'haptics': haptics,
    'sound': sound,
  };

  Map<String, int> _bump(DateTime now, int by) {
    final key = dayKey(now);
    final cutoff = dayKey(now.subtract(const Duration(days: _keepDays)));
    return {
      for (final e in daily.entries)
        if (e.key.compareTo(cutoff) > 0) e.key: e.value,
      key: ((daily[key] ?? 0) + by).clamp(0, 1 << 31),
    };
  }

  TasbeehState _copy({
    Dhikr? dhikr,
    int? target,
    int? count,
    int? round,
    int? session,
    Map<String, int>? daily,
    List<TasbeehSession>? sessions,
    bool? haptics,
    bool? sound,
  }) => TasbeehState(
    dhikr: dhikr ?? this.dhikr,
    target: target ?? this.target,
    count: count ?? this.count,
    round: round ?? this.round,
    session: session ?? this.session,
    daily: daily ?? this.daily,
    sessions: sessions ?? this.sessions,
    haptics: haptics ?? this.haptics,
    sound: sound ?? this.sound,
  );

  static int _nat(Object? v) => v is int && v > 0 ? v : 0;
}
