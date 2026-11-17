import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:quran_pro/app/routes/app_routes.dart';
import 'package:quran_pro/core/errors/result.dart';
import 'package:quran_pro/core/services/adhkar_service.dart';
import 'package:quran_pro/core/services/audio_service.dart';
import 'package:quran_pro/core/services/auth_service.dart';
import 'package:quran_pro/core/services/learn_service.dart';
import 'package:quran_pro/core/services/quran_service.dart';
import 'package:quran_pro/core/services/settings_service.dart';
import 'package:quran_pro/core/services/tasbeeh_service.dart';
import 'package:quran_pro/core/utils/hijri.dart';
import 'package:quran_pro/data/models/adhkar.dart';
import 'package:quran_pro/data/models/learn.dart';
import 'package:quran_pro/data/models/quran_index.dart';
import 'package:quran_pro/domain/repositories/quran_audio_repository.dart';
import 'package:quran_pro/domain/repositories/quran_repository.dart';

final class HomeViewModel extends GetxController {
  HomeViewModel(
    this._auth,
    this._settings,
    this._audio,
    this._quranAudio,
    this._tasbeeh,
    this._learn,
    this._quran,
    this._quranRepo,
    this._adhkar,
  );

  final AuthService _auth;
  final SettingsService _settings;
  final AudioService _audio;
  final QuranAudioRepository _quranAudio;
  final TasbeehService _tasbeeh;
  final LearnService _learn;
  final QuranService _quran;
  final QuranRepository _quranRepo;
  final AdhkarService _adhkar;

  /// Ayah of the day: one of these a day, in turn. Short, well-known verses that stand on
  /// their own on a card.
  static const dailyAyahs = <AyahRef>[
    (surah: 2, ayah: 152),
    (surah: 94, ayah: 5),
    (surah: 2, ayah: 186),
    (surah: 13, ayah: 28),
    (surah: 3, ayah: 139),
    (surah: 39, ayah: 53),
    (surah: 2, ayah: 153),
    (surah: 29, ayah: 69),
    (surah: 14, ayah: 7),
    (surah: 40, ayah: 60),
    (surah: 65, ayah: 3),
    (surah: 93, ayah: 5),
    (surah: 16, ayah: 97),
    (surah: 21, ayah: 87),
    (surah: 25, ayah: 63),
    (surah: 49, ayah: 13),
    (surah: 2, ayah: 45),
    (surah: 3, ayah: 31),
    (surah: 7, ayah: 56),
    (surah: 9, ayah: 51),
    (surah: 50, ayah: 16),
    (surah: 64, ayah: 11),
    (surah: 3, ayah: 8),
    (surah: 2, ayah: 201),
    (surah: 25, ayah: 74),
    (surah: 59, ayah: 18),
    (surah: 20, ayah: 114),
    (surah: 17, ayah: 24),
    (surah: 18, ayah: 10),
    (surah: 33, ayah: 41),
    (surah: 3, ayah: 200),
    (surah: 11, ayah: 115),
    (surah: 12, ayah: 87),
    (surah: 15, ayah: 99),
    (surah: 31, ayah: 17),
    (surah: 55, ayah: 13),
  ];

  static AyahRef dailyAyahOn(DateTime day) =>
      dailyAyahs[DateTime.utc(day.year, day.month, day.day).millisecondsSinceEpoch ~/
          Duration.millisecondsPerDay %
          dailyAyahs.length];

  final AyahRef dailyAyah = dailyAyahOn(DateTime.now());
  final Rxn<QuranIndex> _index = Rxn<QuranIndex>();
  final Rxn<SurahText> _dailyText = Rxn<SurahText>();
  final RxBool _kidsMode = false.obs;

  String get _ayahTrack => 'ayah:${dailyAyah.surah}:${dailyAyah.ayah}';

  /// Geocoded town of the stored location. Never the time-zone city: Asia/Karachi covers all of
  /// Pakistan, so it would name the wrong city.
  String get placeLabel => _settings.placeName ?? 'your_location'.tr;
  bool get alertsOn => _settings.prayerAlertsOn;
  String get tasbeehBadge {
    final s = _tasbeeh.state;
    return '${s.count} / ${s.unlimited ? '∞' : s.target}';
  }

  String get tasbeehDhikr => _tasbeeh.state.dhikr.arabic;
  String get tasbeehRound {
    final s = _tasbeeh.state;
    return s.unlimited
        ? 'tasbeeh_free'.tr
        : 'tasbeeh_round'.trParams({'n': '${s.round}', 'total': '${s.rounds}'});
  }

  /// "9 beads remaining" in the current round; empty for a free count.
  String get tasbeehLeft {
    final s = _tasbeeh.state;
    return s.unlimited ? '' : 'beads_left'.trParams({'n': '${s.target - s.count}'});
  }

  /// Quick +1 from the home tile, without opening the counter.
  void tasbeehTap() {
    final (next, _) = _tasbeeh.state.increment(DateTime.now());
    _tasbeeh.state = next;
    if (next.haptics) unawaited(HapticFeedback.selectionClick());
  }

  bool get ayahBookmarked => _quran.isBookmarked(dailyAyah);
  bool get kidsMode => _kidsMode.value;
  AudioStatus get reciteStatus => _audio.statusOf(_ayahTrack);

  HijriDate get _hijri => Hijri.fromGregorian(DateTime.now());
  String get hijriLabel =>
      '${_hijri.day} ${'hijri_${_hijri.month}'.tr} ${_hijri.year} ${'hijri_era'.tr}';

  /// "Day 14 • Fasting" in Ramadan, otherwise the short Hijri date.
  String get ramadanBadge => _hijri.month == 9
      ? 'fasting_day'.trParams({'n': '${_hijri.day}'})
      : '${_hijri.day} ${'hijri_${_hijri.month}'.tr}';
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

  // ---- Ayah of the day (bundled text, so it shows offline) ----
  String? get ayahArabic => _dailyText.value?.arabic[dailyAyah.ayah - 1];

  /// In the app language; the Arabic UI shows the verse alone.
  String? get ayahTranslation => switch ((_dailyText.value, _settings.locale.languageCode)) {
    (null, _) || (_, 'ar') => null,
    (final t?, 'ur') => t.urdu[dailyAyah.ayah - 1],
    (final t?, _) => t.english[dailyAyah.ayah - 1],
  };

  String get ayahShortRef => '${dailyAyah.surah}:${dailyAyah.ayah}';

  /// "Surah Al-Baqara (2:152)".
  String get ayahRef {
    final name = _index.value?.surah(dailyAyah.surah).name ?? '';
    return '${'quran_surah_named'.trParams({'name': name})} ($ayahShortRef)';
  }

  /// "Juz 2 · Madani".
  String get ayahLocation {
    final t = _dailyText.value;
    final info = _index.value?.surah(dailyAyah.surah);
    if (t == null || info == null) return '';
    final juz = 'quran_juz_n'.trParams({'n': '${t.juz[dailyAyah.ayah - 1]}'});
    return '$juz · ${(info.makki ? 'quran_makki' : 'quran_madani').tr}';
  }

  void toggleAyahBookmark() {
    final added = _quran.toggleBookmark(dailyAyah);
    _snack((added ? 'quran_bookmarked' : 'quran_bookmark_removed').tr);
  }

  Future<void> copyAyah() async {
    final arabic = ayahArabic;
    if (arabic == null) return;
    final t = ayahTranslation;
    await Clipboard.setData(
      ClipboardData(text: '$arabic\n\n${t == null ? '' : '$t\n\n'}— $ayahRef'),
    );
    _snack('quran_copied'.tr);
  }

  /// The verse in the reader, with what comes before and after it.
  void readAyahInContext() => unawaited(
    Get.toNamed<void>(AppRoutes.surah, arguments: (surah: dailyAyah.surah, ayah: dailyAyah.ayah)),
  );

  // ---- Quran: continue where the reader stopped ----
  AyahRef? get lastRead => _quran.lastRead;

  String get lastReadLabel {
    final r = lastRead;
    final index = _index.value;
    if (r == null || index == null) return 'quran_start_reading'.tr;
    return 'quran_continue_at'.trParams({'name': index.surah(r.surah).name, 'n': '${r.ayah}'});
  }

  /// How far into the mushaf the last-read ayah is (0..1).
  double get quranProgress {
    final r = lastRead;
    final index = _index.value;
    if (r == null || index == null) return 0;
    final before = index.surahs.take(r.surah - 1).fold<int>(0, (n, s) => n + s.ayahs);
    return (before + r.ayah) / 6236;
  }

  void openQuranCard() {
    final r = lastRead;
    if (r == null) return openQuran();
    unawaited(Get.toNamed<void>(AppRoutes.surah, arguments: (surah: r.surah, ayah: r.ayah)));
  }

  // ---- Adhkar ----
  /// "Morning routine" until today's adhkar are started, then "7 / 24".
  String get adhkarBadge {
    const c = AdhkarCategory.morningEvening;
    final done = _adhkar.doneIn(c);
    return done == 0 ? adhkarRoutine : '$done / ${_adhkar.totalIn(c)}';
  }

  void openAdhkar() =>
      Get.toNamed<void>(AppRoutes.adhkar, arguments: AdhkarCategory.morningEvening);

  bool get isMorning => DateTime.now().hour < 12;
  String get adhkarRoutine => (isMorning ? 'morning_routine' : 'evening_routine').tr;

  /// "Evening Adhkar (أذكار المساء)"; the Arabic UI shows the Arabic name once.
  String get adhkarLabel {
    final name = (isMorning ? 'morning_adhkar' : 'evening_adhkar').tr;
    final arabic = isMorning ? 'أذكار الصباح' : 'أذكار المساء';
    return name == arabic ? name : '$name ($arabic)';
  }

  // ---- Learning streak & goal (shared with the Learn tab) ----
  int get streakDays => _learn.progress.streak(DateTime.now());
  int get xpToday => _learn.progress.xpOn(DateTime.now());

  /// Next lesson to take, or null once everything is finished.
  ({LearnUnit unit, LearnLesson lesson, int index})? get nextLesson => _learn.nextLesson();
  String get lessonTitle {
    final n = nextLesson;
    if (n == null) return 'all_done_title'.tr;
    final unit = (_learn.curriculum?.units.indexOf(n.unit) ?? 0) + 1;
    return 'lesson_goal_title'.trParams({
      'unit': '$unit',
      'title': pick(n.lesson.title, _settings.locale.languageCode),
    });
  }

  int get lessonXp => nextLesson?.lesson.xp ?? 0;

  /// Share of the current unit finished (1 when everything is done).
  double get lessonProgress {
    final n = nextLesson;
    if (n == null) return _learn.curriculum == null ? 0 : 1;
    return n.index / n.unit.lessons.length;
  }

  /// Monday-first week for the streak row: (narrow day label, active, isToday, future).
  List<({String label, bool done, bool today, bool locked})> get week {
    final now = DateTime.now();
    final p = _learn.progress;
    final monday = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    final fmt = DateFormat.EEEEE(Get.locale?.languageCode);
    return [
      for (var i = 0; i < 7; i++)
        (
          label: fmt.format(monday.add(Duration(days: i))),
          done: p.activeOn(DateTime(monday.year, monday.month, monday.day + i)),
          today: i == now.weekday - 1,
          locked: i >= now.weekday,
        ),
    ];
  }

  /// Straight into the next lesson when a heart is available, otherwise to the path.
  void continueLearning() {
    final n = nextLesson;
    if (n == null || _learn.progress.heartsAt(DateTime.now()) == 0) return openLearn();
    unawaited(
      Get.toNamed<void>(AppRoutes.lesson, arguments: (lessonId: n.lesson.id, review: false)),
    );
  }

  void openNotificationSettings() => Get.toNamed<void>(AppRoutes.prayerNotifications);

  /// Play, pause or resume the ayah of the day; on failure, offer a retry.
  Future<void> toggleRecite() async {
    await _audio.toggle(
      _ayahTrack,
      _quranAudio.ayahAudio(surah: dailyAyah.surah, ayah: dailyAyah.ayah),
      info: (title: ayahRef, subtitle: 'quran_reciter_full'.tr),
    );
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

  set kidsMode(bool on) => _kidsMode.value = on;

  void openPrayerTimes() => _openTab(AppRoutes.prayerTimes);
  void openQibla() => Get.toNamed<void>(AppRoutes.qibla);
  void openTasbeeh() => Get.toNamed<void>(AppRoutes.tasbeeh);
  void openRamadan() => Get.toNamed<void>(AppRoutes.ramadan);
  // Tabs sit directly on Home, so switching tabs never stacks screens.
  void openLearn() => _openTab(AppRoutes.learn);
  void openQuran() => _openTab(AppRoutes.quran);
  void _openTab(String route) =>
      Get.offNamedUntil<void>(route, (r) => r.settings.name == AppRoutes.home);
  void openMore() => _openTab(AppRoutes.more);
  void openHome() => Get.until((r) => r.settings.name == AppRoutes.home);

  void _snack(String message) => Get
    ..closeAllSnackbars()
    ..showSnackbar(
      GetSnackBar(
        message: message,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
        borderRadius: 16,
      ),
    );

  @override
  void onInit() {
    super.onInit();
    unawaited(_loadDailyAyah());
  }

  Future<void> _loadDailyAyah() async {
    if (await _quranRepo.index() case Ok(:final value)) _index.value = value;
    if (await _quranRepo.surah(dailyAyah.surah) case Ok(:final value)) _dailyText.value = value;
  }
}
