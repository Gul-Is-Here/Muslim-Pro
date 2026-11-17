import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:quran_pro/core/services/adhkar_service.dart';
import 'package:quran_pro/core/services/audio_service.dart';
import 'package:quran_pro/data/models/adhkar.dart';

final class AdhkarViewModel extends GetxController {
  AdhkarViewModel(this._adhkar, this._audio, AdhkarCategory initial) : _tab = initial.obs;

  final AdhkarService _adhkar;
  final AudioService _audio;
  final Rx<AdhkarCategory> _tab;
  final RxBool _showMeaning = true.obs;

  /// Opened from Home without a choice: the morning & evening set.
  static const AdhkarCategory forNow = AdhkarCategory.morningEvening;

  bool get loading => _adhkar.book == null;
  AdhkarCategory get tab => _tab.value;
  List<Dhikr> get items => _adhkar.book?.of(tab) ?? const [];
  bool get showMeaning => _showMeaning.value;

  // ignore: use_setters_to_change_properties, passed as a chip callback
  void selectTab(AdhkarCategory c) => _tab.value = c;
  void toggleMeaning() => _showMeaning.toggle();

  int countOf(Dhikr d) => _adhkar.countOf(d);
  bool isDone(Dhikr d) => _adhkar.isDone(d);
  int doneIn(AdhkarCategory c) => _adhkar.doneIn(c);
  int totalIn(AdhkarCategory c) => _adhkar.totalIn(c);

  /// One repetition; a firmer buzz when the dhikr is complete.
  void count(Dhikr d) {
    if (isDone(d)) return;
    final finished = _adhkar.count(d);
    unawaited(finished ? HapticFeedback.mediumImpact() : HapticFeedback.selectionClick());
  }

  void resetTab() => _adhkar.reset(items);

  AudioStatus statusOf(Dhikr d) => _audio.statusOf('dhikr:${d.number}');

  Future<void> play(Dhikr d) async {
    if (!d.hasAudio) return;
    await _audio.toggle(
      'dhikr:${d.number}',
      d.audioUrl,
      start: d.start,
      info: (title: 'adhkar_item'.trParams({'n': '${d.number}'}), subtitle: 'hisnul_muslim'.tr),
    );
    if (statusOf(d) == AudioStatus.error) {
      Get
        ..closeAllSnackbars()
        ..snackbar(
          'hisnul_muslim'.tr,
          (_audio.error == AudioError.offline ? 'audio_offline' : 'audio_unavailable').tr,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
        );
    }
  }
}
