import 'dart:async';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:quran_pro/core/services/tasbeeh_service.dart';
import 'package:quran_pro/data/models/tasbeeh.dart';

final class TasbeehViewModel extends GetxController {
  TasbeehViewModel(this._tasbeeh);

  final TasbeehService _tasbeeh;
  final RxBool _logged = false.obs;
  Timer? _loggedTimer;

  TasbeehState get state => _tasbeeh.state;
  Dhikr get dhikr => state.dhikr;
  int get todayTotal => state.totalOn(DateTime.now());
  int get streak => state.streak(DateTime.now());
  double get goalProgress => (todayTotal / TasbeehState.dailyGoal).clamp(0, 1);

  /// True for a moment after "Finish & log", to confirm the save on the button.
  bool get justLogged => _logged.value;

  String get targetLabel => state.unlimited ? '∞' : '${state.target}';
  String get roundLabel => state.unlimited
      ? 'tasbeeh_free'.tr
      : 'tasbeeh_round'.trParams({'n': '${state.round}', 'total': '${state.rounds}'});

  /// Last seven days, oldest first: (narrow weekday, total).
  List<({String label, int total})> get week {
    final now = DateTime.now();
    final fmt = DateFormat.E(Get.locale?.languageCode);
    return [
      for (var i = 6; i >= 0; i--)
        (
          label: fmt.format(DateTime(now.year, now.month, now.day - i)),
          total: state.totalOn(DateTime(now.year, now.month, now.day - i)),
        ),
    ];
  }

  String sessionTime(DateTime at) =>
      DateFormat('MMM d, h:mm a', Get.locale?.languageCode).format(at);

  void count() {
    final (next, step) = state.increment(DateTime.now());
    _tasbeeh.state = next;
    _feedback(step);
  }

  void undo() {
    if (state.count == 0) return;
    _tasbeeh.state = state.undo(DateTime.now());
    _feedback(TasbeehStep.counted);
  }

  void reset() {
    _tasbeeh.state = state.reset();
    _feedback(TasbeehStep.counted);
  }

  void selectDhikr(Dhikr d) {
    if (d != dhikr) _tasbeeh.state = state.select(dhikr: d);
  }

  void selectTarget(int t) {
    if (t != state.target) _tasbeeh.state = state.select(target: t);
  }

  void toggleHaptics() {
    _tasbeeh.state = state.toggles(haptics: !state.haptics);
    if (state.haptics) unawaited(HapticFeedback.selectionClick());
  }

  void toggleSound() {
    _tasbeeh.state = state.toggles(sound: !state.sound);
    if (state.sound) unawaited(SystemSound.play(SystemSoundType.click));
  }

  void finishSession() {
    if (state.session == 0) return;
    _tasbeeh.state = state.finish(DateTime.now());
    _feedback(TasbeehStep.setDone);
    _logged.value = true;
    _loggedTimer?.cancel();
    _loggedTimer = Timer(const Duration(milliseconds: 2500), () => _logged.value = false);
  }

  // shortcut: the platform click (Android plays it only when system "Touch sounds" is on);
  // ship a bundled chime if users ask for sound regardless of that setting.
  void _feedback(TasbeehStep step) {
    if (state.sound) unawaited(SystemSound.play(SystemSoundType.click));
    if (!state.haptics) return;
    unawaited(switch (step) {
      TasbeehStep.counted => HapticFeedback.selectionClick(),
      TasbeehStep.roundDone => HapticFeedback.mediumImpact(),
      TasbeehStep.setDone => HapticFeedback.heavyImpact(),
    });
  }

  @override
  void onClose() {
    _loggedTimer?.cancel();
    super.onClose();
  }
}
