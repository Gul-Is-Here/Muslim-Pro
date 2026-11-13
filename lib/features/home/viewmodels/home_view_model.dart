import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:quran_pro/app/routes/app_routes.dart';
import 'package:quran_pro/core/services/audio_service.dart';
import 'package:quran_pro/core/services/auth_service.dart';
import 'package:quran_pro/core/services/settings_service.dart';
import 'package:quran_pro/core/services/tasbeeh_service.dart';
import 'package:quran_pro/core/utils/hijri.dart';
import 'package:quran_pro/domain/repositories/quran_audio_repository.dart';

final class HomeViewModel extends GetxController {
  HomeViewModel(this._auth, this._settings, this._audio, this._quranAudio, this._tasbeeh);

  final AuthService _auth;
  final SettingsService _settings;
  final AudioService _audio;
  final QuranAudioRepository _quranAudio;
  final TasbeehService _tasbeeh;

  static const ayahArabic = 'فَاذْكُرُونِي أَذْكُرْكُمْ وَاشْكُرُوا لِي وَلَا تَكْفُرُونِ';
  // The ayah above (Al-Baqarah 2:152); `ayah_ref` / `ayah_location` must name the same verse.
  static const ayahSurah = 2;
  static const ayahNumber = 152;
  static const _ayahTrack = 'ayah:$ayahSurah:$ayahNumber';

  final RxBool _ayahBookmarked = false.obs;
  final RxBool _kidsMode = false.obs;

  /// Geocoded town of the stored location. Never the time-zone city: Asia/Karachi covers all of
  /// Pakistan, so it would name the wrong city.
  String get placeLabel => _settings.placeName ?? 'your_location'.tr;
  bool get alertsOn => _settings.prayerAlertsOn;
  String get tasbeehBadge {
    final s = _tasbeeh.state;
    return '${s.count} / ${s.unlimited ? '∞' : s.target}';
  }

  String get tasbeehDhikr => _tasbeeh.state.dhikr.arabic;
  bool get ayahBookmarked => _ayahBookmarked.value;
  bool get kidsMode => _kidsMode.value;
  AudioStatus get reciteStatus => _audio.statusOf(_ayahTrack);

  HijriDate get _hijri => Hijri.fromGregorian(DateTime.now());
  String get hijriLabel =>
      '${_hijri.day} ${'hijri_${_hijri.month}'.tr} ${_hijri.year} ${'hijri_era'.tr}';
  String get hijriShortLabel => '${_hijri.day} ${'hijri_${_hijri.month}'.tr}';
  String get gregorianLabel => DateFormat.MMMd(Get.locale?.languageCode).format(DateTime.now());

  /// Up to two initials, or empty for guests (the view shows a person icon).
  String get initials {
    final user = _auth.user;
    final source = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!
        : (user?.email ?? '');
    final parts = source.split(RegExp(r'[\s@._]+')).where((p) => p.isNotEmpty).take(2);
    return parts.map((p) => p[0].toUpperCase()).join();
  }

  String? get ayahTranslation {
    final t = 'ayah_translation'.tr;
    return t.isEmpty ? null : t; // Arabic UI shows the verse alone
  }

  String get adhkarKey => DateTime.now().hour < 12 ? 'morning_adhkar' : 'evening_adhkar';

  // Placeholder values until the Tracker (streak), Learn and Quran features land.
  // Self-consistent demo data: every day up to today counts as done.
  int get streakDays => DateTime.now().weekday;
  static const streakXp = 15;
  static const lessonProgress = 0.7;
  static const lessonTitleKey = 'lesson_wudu';
  static const quranProgress = 0.48;

  /// Monday-first week for the streak row: (narrow day label, done, isToday, locked).
  List<({String label, bool done, bool today, bool locked})> get week {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    final fmt = DateFormat.EEEEE(Get.locale?.languageCode);
    return [
      for (var i = 0; i < 7; i++)
        (
          label: fmt.format(monday.add(Duration(days: i))),
          done: i < now.weekday,
          today: i == now.weekday - 1,
          locked: i >= now.weekday,
        ),
    ];
  }

  void openNotificationSettings() => Get.toNamed<void>(AppRoutes.prayerNotifications);

  /// Play, pause or resume the ayah of the day; on failure, offer a retry.
  Future<void> toggleRecite() async {
    await _audio.toggle(_ayahTrack, _quranAudio.ayahAudio(surah: ayahSurah, ayah: ayahNumber));
    if (reciteStatus != AudioStatus.error) return;
    Get
      ..closeAllSnackbars()
      ..showSnackbar(
        GetSnackBar(
          message: (_audio.error == AudioError.offline ? 'audio_offline' : 'audio_unavailable').tr,
          duration: const Duration(seconds: 5),
          margin: const EdgeInsets.all(16),
          borderRadius: 16,
          mainButton: TextButton(
            onPressed: () {
              Get.closeAllSnackbars();
              unawaited(toggleRecite());
            },
            child: Text('retry'.tr),
          ),
        ),
      );
  }

  void toggleAyahBookmark() => _ayahBookmarked.toggle();
  set kidsMode(bool on) => _kidsMode.value = on;

  void openPrayerTimes() => Get.toNamed<void>(AppRoutes.prayerTimes);
  void openQibla() => Get.toNamed<void>(AppRoutes.qibla);
  void openTasbeeh() => Get.toNamed<void>(AppRoutes.tasbeeh);

  void comingSoon() => Get
    ..closeAllSnackbars()
    ..showSnackbar(
      GetSnackBar(
        message: 'coming_soon'.tr,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
        borderRadius: 16,
      ),
    );
}
