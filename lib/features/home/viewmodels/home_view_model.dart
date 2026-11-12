import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:quran_pro/app/routes/app_routes.dart';
import 'package:quran_pro/core/services/auth_service.dart';
import 'package:quran_pro/core/services/location_service.dart';
import 'package:quran_pro/core/services/notification_service.dart';
import 'package:quran_pro/core/services/settings_service.dart';
import 'package:quran_pro/core/utils/hijri.dart';

final class HomeViewModel extends GetxController {
  HomeViewModel(this._auth, this._settings, this._location, this._notifications);

  final AuthService _auth;
  final SettingsService _settings;
  final LocationService _location;
  final NotificationService _notifications;

  static const tasbeehTarget = 33;
  static const ayahArabic = 'فَاذْكُرُونِي أَذْكُرْكُمْ وَاشْكُرُوا لِي وَلَا تَكْفُرُونِ';

  final RxString _place = ''.obs;
  late final RxBool _alertsOn = _settings.prayerAlertsOn.obs;
  final RxInt _tasbeeh = 0.obs;
  final RxBool _ayahBookmarked = false.obs;
  final RxBool _kidsMode = false.obs;

  String get placeLabel => _place.value;
  bool get alertsOn => _alertsOn.value;
  int get tasbeehCount => _tasbeeh.value;
  bool get ayahBookmarked => _ayahBookmarked.value;
  bool get kidsMode => _kidsMode.value;

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

  @override
  void onInit() {
    super.onInit();
    unawaited(_location.approximatePlaceName().then((name) => _place.value = name));
  }

  Future<void> toggleAlerts() async {
    final on = !_alertsOn.value;
    if (on) await _notifications.requestPermission();
    _alertsOn.value = on;
    await _settings.setPrayerAlerts(on: on); // PrayerScheduleService reschedules on change
  }

  void tapTasbeeh() => _tasbeeh.value = _tasbeeh.value >= tasbeehTarget ? 1 : _tasbeeh.value + 1;
  void toggleAyahBookmark() => _ayahBookmarked.toggle();
  set kidsMode(bool on) => _kidsMode.value = on;

  void openPrayerTimes() => Get.toNamed<void>(AppRoutes.prayerTimes);

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
