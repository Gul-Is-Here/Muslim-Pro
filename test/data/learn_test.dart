import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_pro/data/models/learn.dart';
import 'package:quran_pro/data/models/learn_progress.dart';

void main() {
  group('curriculum asset', () {
    final c = Curriculum.fromJson(
      jsonDecode(File('assets/data/learn_curriculum.json').readAsStringSync())
          as Map<String, dynamic>,
    );

    test('parses, ids are unique, every lesson teaches and tests', () {
      expect(c.units, isNotEmpty);
      final ids = [for (final u in c.units) ...u.lessons.map((l) => l.id)];
      expect(ids.toSet().length, ids.length);
      for (final u in c.units) {
        expect(u.lessons, isNotEmpty, reason: u.id);
        for (final l in u.lessons) {
          expect(l.cards, isNotEmpty, reason: l.id);
          expect(l.questions.length, greaterThanOrEqualTo(4), reason: l.id);
          expect(pick(l.title, 'ur'), isNot(pick(l.title, 'en')), reason: '${l.id} has Urdu');
        }
      }
    });

    test('every question has a valid answer and distinct options', () {
      for (final u in c.units) {
        for (final l in u.lessons) {
          for (final q in l.questions) {
            expect(q.answer, inInclusiveRange(0, q.options.length - 1), reason: l.id);
            final labels = q.options.map((o) => pick(o, 'en')).toSet();
            expect(labels.length, q.options.length, reason: '${l.id}: ${pick(q.prompt, 'en')}');
          }
        }
      }
    });

    test('Qaida covers all 28 letters', () {
      final qaida = c.units.firstWhere((u) => u.id == 'qaida');
      final letters = {for (final l in qaida.lessons) ...l.cards.map((c) => c.arabic)};
      expect(letters.length, 28);
    });
  });

  group('unitStatuses', () {
    LearnUnit unit(String id, int n) => LearnUnit(
      id: id,
      icon: id,
      kids: false,
      title: const {'en': ''},
      tag: const {'en': ''},
      lessons: [
        for (var i = 0; i < n; i++)
          LearnLesson(
            id: '${id}_$i',
            title: const {},
            xp: 15,
            cards: const [],
            questions: const [],
          ),
      ],
    );
    final units = [unit('a', 2), unit('b', 1), unit('c', 1)];

    test('first unfinished unit is active, later ones locked', () {
      expect(unitStatuses(units, {}), [UnitStatus.active, UnitStatus.locked, UnitStatus.locked]);
      expect(unitStatuses(units, {'a_0', 'a_1'}), [
        UnitStatus.done,
        UnitStatus.active,
        UnitStatus.locked,
      ]);
      expect(unitStatuses(units, {'a_0', 'a_1', 'b_0', 'c_0'}), everyElement(UnitStatus.done));
    });
  });

  group('LearnProgress', () {
    final t0 = DateTime(2026, 11, 13, 10);

    test('levels start at 0, 100, 300, 600, 1000 XP', () {
      expect([0, 99, 100, 299, 300, 600, 999, 1000].map(LearnProgress.levelFor), [
        1,
        1,
        2,
        2,
        3,
        4,
        4,
        5,
      ]);
    });

    test('hearts drop, then come back one every 30 minutes', () {
      const max = LearnProgress.maxHearts;
      expect(const LearnProgress().heartsAt(t0), 10);
      var p = const LearnProgress().loseHeart(t0).loseHeart(t0);
      expect(p.heartsAt(t0), max - 2);
      expect(p.nextHeartIn(t0), const Duration(minutes: 30));
      expect(p.heartsAt(t0.add(const Duration(minutes: 31))), max - 1);
      expect(p.heartsAt(t0.add(const Duration(hours: 5))), LearnProgress.maxHearts);
      expect(p.nextHeartIn(t0.add(const Duration(hours: 5))), isNull);

      // Losing another heart keeps the regeneration already under way.
      p = p.loseHeart(t0.add(const Duration(minutes: 40)));
      expect(p.heartsAt(t0.add(const Duration(minutes: 40))), max - 2);
      expect(p.nextHeartIn(t0.add(const Duration(minutes: 40))), const Duration(minutes: 20));
    });

    test('a full bar saved under the old cap of 5 counts as full', () {
      final old = LearnProgress.fromJson({'hearts': 5});
      expect(old.heartsAt(t0), LearnProgress.maxHearts);
      expect(old.loseHeart(t0).heartsAt(t0), LearnProgress.maxHearts - 1);
    });

    test('hearts never go below zero', () {
      var p = const LearnProgress();
      for (var i = 0; i < LearnProgress.maxHearts + 4; i++) {
        p = p.loseHeart(t0);
      }
      expect(p.heartsAt(t0), 0);
    });

    test('completing, chests and the daily quiz earn XP once', () {
      var p = const LearnProgress().complete('a_0', 15, t0);
      expect(p.xp, 15);
      expect(p.completed, {'a_0'});
      p = p.claimChest('a', 50, t0).claimChest('a', 50, t0);
      expect(p.xp, 65);
      expect(p.quizDoneOn(t0), isFalse);
      p = p.finishQuiz(40, t0);
      expect(p.quizDoneOn(t0), isTrue);
      expect(p.quizDoneOn(t0.add(const Duration(days: 1))), isFalse);
      expect(p.xpOn(t0), 105);
    });

    test('streak counts consecutive active days, surviving until today', () {
      var p = const LearnProgress();
      for (final d in [10, 11, 12]) {
        p = p.earn(5, DateTime(2026, 11, d));
      }
      expect(p.streak(DateTime(2026, 11, 13)), 3); // yesterday still counts
      expect(p.streak(DateTime(2026, 11, 14)), 0);
      expect(p.earn(5, t0).streak(t0), 4);
    });

    test('JSON round-trip, and junk data falls back to defaults', () {
      final p = const LearnProgress()
          .complete('a_0', 15, t0)
          .loseHeart(t0)
          .claimChest('a', 50, t0)
          .finishQuiz(8, t0);
      final back = LearnProgress.fromJson(
        jsonDecode(jsonEncode(p.toJson())) as Map<String, dynamic>,
      );
      expect(back.toJson(), p.toJson());

      final junk = LearnProgress.fromJson({
        'completed': 3,
        'xp': -5,
        'hearts': 99,
        'daily': 'x',
        'chests': [1, 'a'],
      });
      expect(junk.completed.isEmpty, true);
      expect(junk.xp, 0);
      expect(junk.hearts, LearnProgress.maxHearts);
      expect(junk.daily.isEmpty, true);
      expect(junk.chests, {'a'});
    });
  });
}
