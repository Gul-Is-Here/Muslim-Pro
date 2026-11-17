import 'package:flutter_test/flutter_test.dart';
import 'package:quran_pro/data/models/ramadan_progress.dart';

void main() {
  test('a day cycles: not marked → fasted → missed → not marked', () {
    var p = const RamadanProgress();
    p = p.cycleFast(1448, 3);
    expect(p.fastOn(1448, 3), FastStatus.fasted);
    p = p.cycleFast(1448, 3);
    expect(p.fastOn(1448, 3), FastStatus.missed);
    p = p.cycleFast(1448, 3);
    expect(p.fastOn(1448, 3), FastStatus.none);
    expect(p.fasts, isEmpty);
  });

  test('make-up fasts: missed days plus earlier years, minus those kept, never below zero', () {
    var p = const RamadanProgress().cycleFast(1448, 1).cycleFast(1448, 1); // missed
    p = p.cycleFast(1448, 2).cycleFast(1448, 2).withOwedBefore(3);
    expect(p.owed, 5);
    p = p.withMadeUp(2);
    expect(p.owed, 3);
    expect(p.withMadeUp(99).madeUp, 5, reason: 'cannot make up more than owed');
    expect(p.countIn(1448, FastStatus.missed), 2);
    expect(p.countIn(1449, FastStatus.missed), 0);
  });

  test('deeds toggle per day and everything survives JSON, junk ignored', () {
    final p = const RamadanProgress()
        .toggleDeed(1448, 5, RamadanDeed.taraweeh)
        .toggleDeed(1448, 5, RamadanDeed.quran)
        .toggleDeed(1448, 5, RamadanDeed.quran)
        .cycleFast(1448, 5)
        .withOwedBefore(2);
    expect(p.deedsOn(1448, 5), {RamadanDeed.taraweeh});
    final back = RamadanProgress.fromJson(p.toJson());
    expect(back.deedsOn(1448, 5), {RamadanDeed.taraweeh});
    expect(back.fastOn(1448, 5), FastStatus.fasted);
    expect(back.owedBefore, 2);
    final junk = RamadanProgress.fromJson({
      'fasts': {'1448:1': 'eaten', 7: 3},
      'deeds': {
        '1448:1': ['dance'],
      },
      'owedBefore': -4,
    });
    expect(junk.fasts, isEmpty);
    expect(junk.deedsOn(1448, 1), isEmpty);
    expect(junk.owedBefore, 0);
  });
}
