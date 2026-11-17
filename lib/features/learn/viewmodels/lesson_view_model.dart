import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:quran_pro/core/services/audio_service.dart';
import 'package:quran_pro/core/services/learn_service.dart';
import 'package:quran_pro/core/services/settings_service.dart';
import 'package:quran_pro/data/models/learn.dart';

/// `lessonId` null = today's quiz. `review` = replay of a finished lesson (no hearts at stake).
typedef LessonArgs = ({String? lessonId, bool review});

enum LessonPhase { loading, cards, question, finished, outOfHearts, unavailable }

/// A question with its options in display order.
typedef _Asked = ({LearnQuestion q, List<int> order});

final class LessonViewModel extends GetxController {
  LessonViewModel(this._learn, this._settings, this._audio, this._args, {Random? random})
    : _rng = random ?? Random();

  final LearnService _learn;
  final SettingsService _settings;
  final AudioService _audio;
  final LessonArgs _args;
  final Random _rng;

  static const reviewXp = 5;
  static const quizSize = 5;
  static const quizXpPerAnswer = 8; // 4 XP, doubled

  final Rx<LessonPhase> _phase = LessonPhase.loading.obs;
  final RxInt _card = 0.obs;
  final RxList<_Asked> _queue = <_Asked>[].obs;
  final Rxn<int> _selected = Rxn<int>();
  final RxBool _checked = false.obs;
  final RxInt _solved = 0.obs;

  LearnLesson? _lesson;
  List<LearnCard> _cards = const [];
  int _questionCount = 0;
  final Set<LearnQuestion> _missed = {};
  int _xpEarned = 0;

  String get _lang => _settings.locale.languageCode;
  bool get isQuiz => _args.lessonId == null;
  bool get isReview => _args.review;
  bool get costsHearts => !isReview;

  LessonPhase get phase => _phase.value;
  String get title => isQuiz ? 'daily_quiz'.tr : pick(_lesson?.title ?? const {}, _lang);
  int get hearts => _learn.progress.heartsAt(DateTime.now());

  /// Cards read plus questions answered correctly, out of everything in the session.
  double get progress {
    final total = _cards.length + _questionCount;
    if (total == 0) return 0;
    final seen = phase == LessonPhase.cards ? _card.value : _cards.length;
    return ((seen + _solved.value) / total).clamp(0, 1).toDouble();
  }

  // ---- Cards ----
  int get cardIndex => _card.value;
  int get cardCount => _cards.length;
  LearnCard? get card => _cards.isEmpty ? null : _cards[_card.value];
  String text(L10nText t) => pick(t, _lang);

  void nextCard() {
    if (_card.value < _cards.length - 1) {
      _card.value++;
    } else {
      if (_queue.isEmpty) {
        _finish();
      } else {
        _phase.value = LessonPhase.question;
      }
    }
  }

  /// Arabic text → the card that has its recording, so quiz questions reuse card audio.
  late final Map<String, LearnCard> _recordings = {
    for (final u in _learn.curriculum?.units ?? const <LearnUnit>[])
      for (final l in u.lessons)
        for (final c in l.cards)
          if (c.arabic != null && c.audio != null) c.arabic!: c,
  };

  /// Exact match, else the card whose full text a question quotes part of.
  LearnCard? _recordingFor(String arabic) =>
      _recordings[arabic] ??
      _recordings.entries.where((e) => e.key.contains(arabic)).firstOrNull?.value;

  bool canPlay(String arabic) => _recordingFor(arabic) != null;

  void playArabic(String arabic) {
    final card = _recordingFor(arabic);
    final audio = card?.audio;
    if (card == null || audio == null) return;
    final info = (title: text(card.title), subtitle: title);
    unawaited(_audio.play('card:$audio', Uri.parse('asset:///$audio'), info: info));
  }

  void previousCard() {
    if (_card.value > 0) _card.value--;
  }

  // ---- Questions ----
  LearnQuestion? get question => _queue.isEmpty ? null : _queue.first.q;
  List<String> get options {
    if (_queue.isEmpty) return const [];
    final a = _queue.first;
    return [for (final i in a.order) pick(a.q.options[i], _lang)];
  }

  int? get selected => _selected.value;
  bool get checked => _checked.value;

  /// Display index of the right answer.
  int get answerIndex => _queue.isEmpty ? -1 : _queue.first.order.indexOf(_queue.first.q.answer);
  bool get isCorrect => _selected.value == answerIndex;
  String get correctAnswer => answerIndex < 0 ? '' : options[answerIndex];

  void select(int i) {
    if (!_checked.value) _selected.value = i;
  }

  void check() {
    if (_selected.value == null || _checked.value) return;
    _checked.value = true;
    if (isCorrect) {
      unawaited(HapticFeedback.lightImpact());
      return;
    }
    unawaited(HapticFeedback.mediumImpact());
    _missed.add(_queue.first.q);
    if (costsHearts) _learn.progress = _learn.progress.loseHeart(DateTime.now());
  }

  /// After feedback: a right answer leaves the queue, a wrong one comes back at the end.
  void next() {
    if (!_checked.value) return;
    final current = _queue.removeAt(0);
    if (_isCorrectFor(current)) {
      _solved.value++;
    } else {
      _queue.add((q: current.q, order: _shuffled(current.q.options.length)));
    }
    _selected.value = null;
    _checked.value = false;
    if (costsHearts && hearts == 0 && _queue.isNotEmpty) {
      _phase.value = LessonPhase.outOfHearts;
    } else if (_queue.isEmpty) {
      _finish();
    }
  }

  bool _isCorrectFor(_Asked a) => _selected.value == a.order.indexOf(a.q.answer);

  // ---- Result ----
  int get xpEarned => _xpEarned;
  int get accuracy => _questionCount == 0
      ? 100
      : (100 * (_questionCount - _missed.length) / _questionCount).round();
  int get streak => _learn.progress.streak(DateTime.now());
  String? get nextHeartLabel {
    final d = _learn.progress.nextHeartIn(DateTime.now());
    if (d == null) return null;
    return '${d.inMinutes.toString().padLeft(2, '0')}:'
        '${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  /// Leaving mid-session loses its progress; worth confirming only once something is done.
  bool get hasProgress =>
      (phase == LessonPhase.cards && _card.value > 0) || phase == LessonPhase.question;

  void _finish() {
    final now = DateTime.now();
    final p = _learn.progress;
    final lesson = _lesson;
    if (isQuiz) {
      _xpEarned = (_questionCount - _missed.length) * quizXpPerAnswer;
      _learn.progress = p.finishQuiz(_xpEarned, now);
    } else if (lesson != null) {
      final firstTime = !p.completed.contains(lesson.id);
      _xpEarned = firstTime ? lesson.xp : reviewXp;
      _learn.progress = p.complete(lesson.id, _xpEarned, now);
    }
    _phase.value = LessonPhase.finished;
    unawaited(HapticFeedback.heavyImpact());
  }

  List<int> _shuffled(int n) => List<int>.generate(n, (i) => i)..shuffle(_rng);

  Future<void> _start() async {
    await _learn.load();
    final c = _learn.curriculum;
    if (c == null) {
      _phase.value = LessonPhase.unavailable;
      return;
    }
    final List<LearnQuestion> questions;
    if (isQuiz) {
      questions = _quizPool(c)..shuffle(_rng);
    } else {
      _lesson = c.lesson(_args.lessonId!);
      final l = _lesson;
      if (l == null) {
        _phase.value = LessonPhase.unavailable;
        return;
      }
      _cards = l.cards;
      questions = [...l.questions]..shuffle(_rng);
    }
    final picked = isQuiz ? questions.take(quizSize).toList() : questions;
    _questionCount = picked.length;
    _queue.assignAll([for (final q in picked) (q: q, order: _shuffled(q.options.length))]);
    _phase.value = _cards.isNotEmpty ? LessonPhase.cards : LessonPhase.question;
  }

  /// Questions from finished lessons; before any are finished, from the first lesson.
  List<LearnQuestion> _quizPool(Curriculum c) {
    final done = [
      for (final u in c.units)
        for (final l in u.lessons)
          if (_learn.progress.completed.contains(l.id)) ...l.questions,
    ];
    return done.isNotEmpty ? done : [...c.units.first.lessons.first.questions];
  }

  @override
  void onInit() {
    super.onInit();
    unawaited(_start());
  }
}
