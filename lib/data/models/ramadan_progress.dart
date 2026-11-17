enum FastStatus { none, fasted, missed }

/// Good deeds checked off on each Ramadan day.
enum RamadanDeed { taraweeh, quran, sadaqah, adhkar, iftarDua }

/// Everything tracked for Ramadan, per Hijri year, plus make-up fasts. Pure: every change
/// returns a new value.
final class RamadanProgress {
  const RamadanProgress({
    this.fasts = const {},
    this.deeds = const {},
    this.owedBefore = 0,
    this.madeUp = 0,
  });

  factory RamadanProgress.fromJson(Map<String, dynamic> j) => RamadanProgress(
    fasts: {
      if (j['fasts'] case final Map<dynamic, dynamic> m)
        for (final MapEntry(:key, :value) in m.entries)
          if (FastStatus.values.asNameMap()[value] case final s? when s != FastStatus.none)
            '$key': s,
    },
    deeds: {
      if (j['deeds'] case final Map<dynamic, dynamic> m)
        for (final MapEntry(:key, :value) in m.entries)
          if (value is List) '$key': {for (final d in value) ?RamadanDeed.values.asNameMap()[d]},
    },
    owedBefore: _nat(j['owedBefore']),
    madeUp: _nat(j['madeUp']),
  );

  /// 'year:day' → how that fast went.
  final Map<String, FastStatus> fasts;

  /// 'year:day' → deeds done that day.
  final Map<String, Set<RamadanDeed>> deeds;

  /// Fasts missed in earlier years, entered by hand.
  final int owedBefore;

  /// Make-up fasts already kept.
  final int madeUp;

  static String _key(int year, int day) => '$year:$day';

  FastStatus fastOn(int year, int day) => fasts[_key(year, day)] ?? FastStatus.none;
  Set<RamadanDeed> deedsOn(int year, int day) => deeds[_key(year, day)] ?? const {};

  int countIn(int year, FastStatus s) =>
      fasts.entries.where((e) => e.value == s && e.key.startsWith('$year:')).length;

  /// Missed fasts still to be made up, across every year.
  int get owed {
    final missed = fasts.values.where((s) => s == FastStatus.missed).length;
    return (missed + owedBefore - madeUp).clamp(0, 9999);
  }

  /// Not marked → fasted → missed → not marked.
  RamadanProgress cycleFast(int year, int day) {
    final next = FastStatus.values[(fastOn(year, day).index + 1) % FastStatus.values.length];
    return _copy(
      fasts: {
        for (final e in fasts.entries)
          if (e.key != _key(year, day)) e.key: e.value,
        if (next != FastStatus.none) _key(year, day): next,
      },
    );
  }

  RamadanProgress toggleDeed(int year, int day, RamadanDeed deed) {
    final current = deedsOn(year, day);
    final updated = current.contains(deed) ? ({...current}..remove(deed)) : {...current, deed};
    return _copy(deeds: {...deeds, _key(year, day): updated});
  }

  RamadanProgress withOwedBefore(int n) => _copy(owedBefore: n.clamp(0, 999));

  /// Never more made up than was owed.
  RamadanProgress withMadeUp(int n) {
    final missed = fasts.values.where((s) => s == FastStatus.missed).length;
    return _copy(madeUp: n.clamp(0, missed + owedBefore));
  }

  Map<String, dynamic> toJson() => {
    'fasts': {for (final e in fasts.entries) e.key: e.value.name},
    'deeds': {
      for (final e in deeds.entries)
        if (e.value.isNotEmpty) e.key: [for (final d in e.value) d.name],
    },
    'owedBefore': owedBefore,
    'madeUp': madeUp,
  };

  RamadanProgress _copy({
    Map<String, FastStatus>? fasts,
    Map<String, Set<RamadanDeed>>? deeds,
    int? owedBefore,
    int? madeUp,
  }) => RamadanProgress(
    fasts: fasts ?? this.fasts,
    deeds: deeds ?? this.deeds,
    owedBefore: owedBefore ?? this.owedBefore,
    madeUp: madeUp ?? this.madeUp,
  );

  static int _nat(Object? v) => v is int && v > 0 ? v : 0;
}
