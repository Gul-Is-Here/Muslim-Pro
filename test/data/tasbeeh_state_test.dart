import 'package:flutter_test/flutter_test.dart';
import 'package:quran_pro/data/models/tasbeeh.dart';

void main() {
  final day = DateTime(2026, 11, 12, 20);

  test('33 runs three rounds, then starts over; totals keep counting', () {
    var s = const TasbeehState();
    final steps = <TasbeehStep>[];
    for (var i = 0; i < 99; i++) {
      final (next, step) = s.increment(day);
      s = next;
      steps.add(step);
    }
    expect(steps.where((x) => x == TasbeehStep.roundDone), hasLength(2));
    expect(steps.last, TasbeehStep.setDone);
    expect((s.count, s.round, s.session, s.totalOn(day)), (0, 1, 99, 99));
  });

  test('no-limit target never wraps', () {
    var s = const TasbeehState().select(target: 0);
    for (var i = 0; i < 150; i++) {
      s = s.increment(day).$1;
    }
    expect((s.count, s.round), (150, 1));
  });

  test('undo, reset and finish', () {
    var s = const TasbeehState().increment(day).$1.increment(day).$1.undo(day);
    expect((s.count, s.session, s.totalOn(day)), (1, 1, 1));
    expect(s.reset().count, 0);
    expect(s.reset().totalOn(day), 1, reason: "reset keeps today's total");
    s = s.finish(day);
    expect((s.session, s.sessions.single.count), (0, 1));
    expect(identical(s.finish(day), s), isTrue, reason: 'empty session is not logged');
  });

  test('streak counts back from today, or yesterday when today is empty', () {
    var s = const TasbeehState();
    for (final d in [12, 11, 10, 8]) {
      s = s.increment(DateTime(2026, 11, d)).$1;
    }
    expect(s.streak(day), 3);
    expect(s.streak(DateTime(2026, 11, 13)), 3);
    expect(s.streak(DateTime(2026, 11, 14)), 0);
  });

  test('json round-trips and survives bad data', () {
    final s = const TasbeehState()
        .select(dhikr: Dhikr.durood, target: 100)
        .increment(day)
        .$1
        .finish(day);
    final back = TasbeehState.fromJson(s.toJson());
    expect(
      (back.dhikr, back.target, back.totalOn(day), back.sessions.single.count),
      (Dhikr.durood, 100, 1, 1),
    );
    final junk = TasbeehState.fromJson({
      'dhikr': 'x',
      'target': 7,
      'count': -3,
      'daily': 5,
      'sessions': [
        {'at': 'no'},
      ],
    });
    expect(
      (junk.dhikr, junk.target, junk.count, junk.daily.isEmpty, junk.sessions.isEmpty),
      (Dhikr.subhanallah, 33, 0, true, true),
    );
  });
}
