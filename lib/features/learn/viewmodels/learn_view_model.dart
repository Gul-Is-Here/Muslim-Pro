import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:quran_pro/app/routes/app_routes.dart';
import 'package:quran_pro/core/services/audio_service.dart';
import 'package:quran_pro/core/services/learn_service.dart';
import 'package:quran_pro/core/services/settings_service.dart';
import 'package:quran_pro/core/utils/formatters.dart';
import 'package:quran_pro/data/models/learn.dart';
import 'package:quran_pro/data/models/learn_progress.dart';

enum LearnNodeState { done, active, chest, chestOpen, chestLocked, locked }

/// One stop on the path: a unit, or the reward chest that follows it.
final class LearnNode {
  const LearnNode({
    required this.unit,
    required this.title,
    required this.subtitle,
    required this.state,
  });

  final LearnUnit unit;
  final String title;
  final String subtitle;
  final LearnNodeState state;

  bool get isChest =>
      state == LearnNodeState.chest ||
      state == LearnNodeState.chestOpen ||
      state == LearnNodeState.chestLocked;
}

/// A Noorani Qaida letter and where it is pronounced from (makhraj).
typedef QaidaLetter = ({String glyph, String name, String makhraj, String? audio});

final class LearnViewModel extends GetxController {
  LearnViewModel(this._learn, this._settings, this._audio);

  final LearnService _learn;
  final SettingsService _settings;
  final AudioService _audio;

  static const chestXp = 50;

  final RxBool _kidsOnly = false.obs;
  final Rxn<QaidaLetter> _letter = Rxn<QaidaLetter>();
  final Rx<DateTime> _now = DateTime.now().obs; // refreshes heart regeneration
  Timer? _letterTimer;
  Timer? _ticker;

  String get _lang => _settings.locale.languageCode;
  LearnProgress get _p => _learn.progress;
  bool get loaded => _learn.curriculum != null;
  bool get kidsOnly => _kidsOnly.value;
  QaidaLetter? get letter => _letter.value;
  String get languageCode => _lang;

  // ---- Stats ----
  int get level => _p.level;
  String get rank => switch (level) {
    <= 2 => 'rank_1',
    <= 4 => 'rank_2',
    <= 7 => 'rank_3',
    _ => 'rank_4',
  }.tr;
  int get xp => _p.xp;
  int get streak => _p.streak(_now.value);
  int get hearts => _p.heartsAt(_now.value);
  String? get nextHeartLabel {
    final d = _p.nextHeartIn(_now.value);
    return d == null ? null : Formatters.countdown(d).substring(3); // mm:ss
  }

  // ---- Path ----
  List<LearnUnit> get _units =>
      _learn.curriculum?.units.where((u) => !kidsOnly || u.kids).toList() ?? const [];

  List<LearnUnit> get allUnits => _units;

  void heartsInfo() => _toast(
    nextHeartLabel == null ? 'hearts_full'.tr : 'next_heart_in'.trParams({'time': nextHeartLabel!}),
  );

  List<LearnNode> get path {
    final units = _units;
    final status = unitStatuses(units, _p.completed);
    return [
      for (var i = 0; i < units.length; i++) ...[
        _unitNode(units[i], status[i]),
        if (i < units.length - 1) _chestNode(units[i], status[i]),
      ],
    ];
  }

  LearnNode _unitNode(LearnUnit u, UnitStatus s) {
    final done = u.lessons.where((l) => _p.completed.contains(l.id)).length;
    return LearnNode(
      unit: u,
      title: pick(u.title, _lang),
      subtitle: switch (s) {
        UnitStatus.done => 'node_completed'.trParams({
          'n': '$done',
          'total': '${u.lessons.length}',
        }),
        _ => pick(u.tag, _lang),
      },
      state: switch (s) {
        UnitStatus.done => LearnNodeState.done,
        UnitStatus.active => LearnNodeState.active,
        UnitStatus.locked => LearnNodeState.locked,
      },
    );
  }

  LearnNode _chestNode(LearnUnit after, UnitStatus s) {
    final opened = _p.chests.contains(after.id);
    return LearnNode(
      unit: after,
      title: 'node_chest'.tr,
      subtitle: opened ? 'chest_opened'.tr : 'node_chest_sub'.trParams({'n': '$chestXp'}),
      state: opened
          ? LearnNodeState.chestOpen
          : s == UnitStatus.done
          ? LearnNodeState.chest
          : LearnNodeState.chestLocked,
    );
  }

  /// The lesson to resume, with its position in the unit.
  ({LearnUnit unit, LearnLesson lesson, int index})? get current =>
      _learn.nextLesson(kidsOnly: kidsOnly);
  int get currentUnitNumber {
    final c = current;
    return c == null ? 0 : (_learn.curriculum?.units.indexOf(c.unit) ?? 0) + 1;
  }

  String text(L10nText t) => pick(t, _lang);
  bool isDone(LearnLesson l) => _p.completed.contains(l.id);
  bool isUnlocked(LearnUnit u) {
    final units = _units;
    final i = units.indexOf(u);
    return i >= 0 && unitStatuses(units, _p.completed)[i] != UnitStatus.locked;
  }

  // ---- Qaida pad ----
  List<QaidaLetter> get letters {
    final qaida = _learn.curriculum?.units.firstWhereOrNull((u) => u.id == 'qaida');
    return [
      for (final l in qaida?.lessons ?? const <LearnLesson>[])
        for (final c in l.cards)
          (
            glyph: c.arabic ?? '',
            name: c.translit ?? '',
            makhraj: pick(c.body, _lang),
            audio: c.audio,
          ),
    ];
  }

  void tapLetter(QaidaLetter l) {
    _letter.value = l;
    unawaited(HapticFeedback.selectionClick());
    final audio = l.audio;
    // A missing clip (files are git-ignored) just stays silent; the makhraj still shows.
    if (audio != null) {
      final info = (title: '${l.glyph}  ${l.name}', subtitle: 'qaida_title'.tr);
      unawaited(_audio.play('letter:${l.glyph}', Uri.parse('asset:///$audio'), info: info));
    }
    _letterTimer?.cancel();
    _letterTimer = Timer(const Duration(seconds: 4), () => _letter.value = null);
  }

  // ---- Daily quiz ----
  bool get quizDone => _p.quizDoneOn(_now.value);

  // ---- Actions ----
  void toggleKids() => _kidsOnly.toggle();

  void tapNode(LearnNode n) {
    switch (n.state) {
      case LearnNodeState.active:
        resume();
      case LearnNodeState.done:
        break; // the view opens the unit's lesson list
      case LearnNodeState.chest:
        _learn.progress = _p.claimChest(n.unit.id, chestXp, DateTime.now());
        unawaited(HapticFeedback.mediumImpact());
        _toast('chest_claimed'.trParams({'n': '$chestXp'}));
      case LearnNodeState.chestOpen:
        _toast('chest_opened'.tr);
      case LearnNodeState.chestLocked:
        _toast('chest_locked'.trParams({'unit': pick(n.unit.title, _lang)}));
      case LearnNodeState.locked:
        _toast('unit_locked'.tr);
    }
  }

  void resume() {
    final c = current;
    if (c != null) openLesson(c.lesson);
  }

  /// New lessons need a heart; finished ones can always be reviewed.
  void openLesson(LearnLesson l) {
    final review = isDone(l);
    if (!review && hearts == 0) return _outOfHearts();
    unawaited(Get.toNamed<void>(AppRoutes.lesson, arguments: (lessonId: l.id, review: review)));
  }

  void startQuiz() {
    if (quizDone) return _toast('quiz_done_today'.tr);
    if (hearts == 0) return _outOfHearts();
    unawaited(Get.toNamed<void>(AppRoutes.lesson, arguments: (lessonId: null, review: false)));
  }

  void _outOfHearts() =>
      _toast('out_of_hearts_msg'.trParams({'time': nextHeartLabel ?? '--:--'}), seconds: 4);

  Future<void> setLanguage(String code) async {
    Get.back<void>();
    await _settings.setLanguage(code);
  }

  void _toast(String message, {int seconds = 2}) => Get
    ..closeAllSnackbars()
    ..showSnackbar(
      GetSnackBar(
        message: message,
        duration: Duration(seconds: seconds),
        margin: const EdgeInsets.all(16),
        borderRadius: 16,
      ),
    );

  @override
  void onInit() {
    super.onInit();
    unawaited(_learn.load());
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _now.value = DateTime.now());
  }

  @override
  void onClose() {
    _letterTimer?.cancel();
    _ticker?.cancel();
    super.onClose();
  }
}
