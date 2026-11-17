import 'dart:async';

import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:quran_pro/app/routes/app_routes.dart';
import 'package:quran_pro/core/services/auth_service.dart';
import 'package:quran_pro/core/services/learn_service.dart';
import 'package:quran_pro/core/services/quran_service.dart';
import 'package:quran_pro/core/services/settings_service.dart';
import 'package:quran_pro/core/services/surah_download_service.dart';
import 'package:quran_pro/data/models/adhkar.dart';

typedef LanguageOption = ({String code, String label});

final class MoreViewModel extends GetxController {
  MoreViewModel(this._auth, this._settings, this._learn, this._quran, this._downloads);

  final AuthService _auth;
  final SettingsService _settings;
  final LearnService _learn;
  final QuranService _quran;
  final SurahDownloadService _downloads;

  static const languages = <LanguageOption>[
    (code: 'en', label: 'English'),
    (code: 'ur', label: 'اردو'),
    (code: 'ar', label: 'العربية'),
  ];

  final RxString _lang = ''.obs;

  bool get isGuest => _auth.user?.isGuest ?? true;
  String get name {
    final u = _auth.user;
    if (u == null || u.isGuest) return 'more_guest'.tr;
    final display = u.displayName?.trim() ?? '';
    return display.isNotEmpty ? display : (u.email ?? '');
  }

  String? get email => isGuest ? null : _auth.user?.email;

  String get initials {
    final parts = name.split(RegExp(r'[\s@._]+')).where((p) => p.isNotEmpty).take(2);
    return isGuest ? '' : parts.map((p) => p[0].toUpperCase()).join();
  }

  // Profile stats; each reads an Rx, so an Obx around them stays live.
  int get streakDays => _learn.progress.streak(DateTime.now());
  int get lessonsDone => _learn.progress.completed.length;
  int get savedAyahs => _quran.bookmarkCount;
  int get totalXp => _learn.progress.xp;
  int get level => _learn.progress.level;
  int get xpToNextLevel => _learn.progress.levelEnd - _learn.progress.xp;
  double get levelProgress => _learn.progress.levelProgress.clamp(0, 1).toDouble();

  /// The last seven days, oldest first, ending today: narrow weekday label and whether any
  /// lesson or practice happened that day.
  List<({String label, bool active, bool today})> get lastSevenDays {
    final now = DateTime.now();
    final p = _learn.progress;
    final narrow = DateFormat('EEEEE', languageCode);
    return [
      for (var i = 6; i >= 0; i--)
        if (DateTime(now.year, now.month, now.day - i) case final d)
          (label: narrow.format(d), active: p.activeOn(d), today: i == 0),
    ];
  }

  // Offline recitations.
  int get downloadedSurahs => _downloads.downloadedCount;
  String get downloadsLabel => _downloads.downloadedCount == 0
      ? 'downloads_none'.tr
      : 'downloads_value'.trParams({
          'n': '${_downloads.downloadedCount}',
          'mb': (_downloads.bytes / (1024 * 1024)).toStringAsFixed(0),
        });
  Future<void> deleteAllDownloads() => _downloads.deleteAll();

  String get languageCode => _lang.value.isEmpty ? _settings.locale.languageCode : _lang.value;
  String get languageLabel =>
      languages.firstWhere((l) => l.code == languageCode, orElse: () => languages.first).label;

  Future<void> setLanguage(String code) async {
    _lang.value = code;
    await _settings.setLanguage(code);
  }

  /// Signing out returns to the welcome screen (SessionController watches the account).
  Future<void> signOut() => _auth.signOut();

  void openQibla() => unawaited(Get.toNamed<void>(AppRoutes.qibla));
  void openTasbeeh() => unawaited(Get.toNamed<void>(AppRoutes.tasbeeh));
  void openRamadan() => unawaited(Get.toNamed<void>(AppRoutes.ramadan));
  void openAdhkar([AdhkarCategory c = AdhkarCategory.morningEvening]) =>
      unawaited(Get.toNamed<void>(AppRoutes.adhkar, arguments: c));
  void openPrayerAlerts() => unawaited(Get.toNamed<void>(AppRoutes.prayerNotifications));
}
