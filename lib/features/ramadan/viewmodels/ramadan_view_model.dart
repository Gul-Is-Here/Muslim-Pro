import 'dart:async';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:quran_pro/app/routes/app_routes.dart';
import 'package:quran_pro/core/config/flavor_config.dart';
import 'package:quran_pro/core/errors/result.dart';
import 'package:quran_pro/core/services/audio_service.dart';
import 'package:quran_pro/core/services/ramadan_service.dart';
import 'package:quran_pro/core/services/settings_service.dart';
import 'package:quran_pro/core/utils/hijri.dart';
import 'package:quran_pro/data/models/day_prayer_times.dart';
import 'package:quran_pro/data/models/prayer.dart';
import 'package:quran_pro/data/models/quran_index.dart';
import 'package:quran_pro/data/models/ramadan_progress.dart';
import 'package:quran_pro/domain/repositories/prayer_times_repository.dart';
import 'package:quran_pro/domain/repositories/quran_repository.dart';

/// A Ramadan dua: authentic text, its source, and a bundled recitation when there is one.
typedef RamadanDua = ({
  String id,
  String titleKey,
  String arabic,
  String meaningKey,
  String ref,
  String? audio,
});

/// What the countdown is counting to.
enum FastEvent { suhoorEnds, iftar }

final class RamadanViewModel extends GetxController {
  RamadanViewModel(this._ramadan, this._prayers, this._settings, this._audio, this._quran);

  final RamadanService _ramadan;
  final PrayerTimesRepository _prayers;
  final SettingsService _settings;
  final AudioService _audio;
  final QuranRepository _quran;

  static const days = 30;

  static const List<RamadanDua> duas = [
    (
      id: 'iftar',
      titleKey: 'ramadan_dua_iftar',
      arabic: 'ذَهَبَ الظَّمَأُ وَابْتَلَّتِ الْعُرُوقُ وَثَبَتَ الْأَجْرُ إِنْ شَاءَ اللّٰهُ',
      meaningKey: 'ramadan_dua_iftar_meaning',
      ref: 'Abu Dawud 2357',
      audio: 'assets/audio/phrases/dua_iftar.mp3',
    ),
    (
      id: 'host',
      titleKey: 'ramadan_dua_host',
      arabic: 'أَفْطَرَ عِنْدَكُمُ الصَّائِمُونَ وَأَكَلَ طَعَامَكُمُ الْأَبْرَارُ وَصَلَّتْ عَلَيْكُمُ الْمَلَائِكَةُ',
      meaningKey: 'ramadan_dua_host_meaning',
      ref: 'Abu Dawud 3854',
      audio: 'assets/audio/phrases/dua_iftar_host.mp3',
    ),
    (
      id: 'saim',
      titleKey: 'ramadan_dua_saim',
      arabic: 'إِنِّي صَائِمٌ، إِنِّي صَائِمٌ',
      meaningKey: 'ramadan_dua_saim_meaning',
      ref: 'Bukhari 1894',
      audio: 'assets/audio/phrases/inni_saim.mp3',
    ),
    (
      id: 'qadr',
      titleKey: 'ramadan_dua_qadr',
      arabic: 'اللّٰهُمَّ إِنَّكَ عَفُوٌّ تُحِبُّ الْعَفْوَ فَاعْفُ عَنِّي',
      meaningKey: 'ramadan_dua_qadr_meaning',
      ref: 'Tirmidhi 3513',
      audio: null, // no recording found yet
    ),
  ];

  final Rx<DateTime> _now = DateTime.now().obs;
  final RxBool _preview = false.obs;
  Timer? _ticker;
  final Rxn<QuranIndex> _index = Rxn<QuranIndex>();
  final Map<DateTime, DayPrayerTimes?> _times = {};

  // ---- Calendar ----
  HijriDate get _hijri => Hijri.fromGregorian(_now.value);

  /// Dev builds can show Ramadan mode on any day, since the real one is months away.
  bool get canPreview => FlavorConfig.instance.isDev;
  bool get previewing => _preview.value;
  void togglePreview() => _preview.toggle();

  bool get inRamadan => _hijri.month == 9 || _preview.value;

  /// The Ramadan being tracked: this one, or the next.
  int get year {
    final h = _hijri;
    if (h.month == 9) return h.year;
    return h.month < 9 ? h.year : h.year + 1;
  }

  /// Day of Ramadan today (1–30), null outside it. The preview pretends it is day 12.
  int? get today => _hijri.month == 9 ? _hijri.day : (_preview.value ? 12 : null);

  DateTime dateOf(int day) => Hijri.toGregorian(year, 9, day);
  DateTime get startDate => dateOf(1);
  int get daysUntil => startDate.difference(_dateOnly(_now.value)).inDays;
  bool isLastTen(int day) => day >= 21;
  bool isOddNight(int day) => day >= 21 && day.isOdd;

  String get startDateLabel => DateFormat.yMMMMEEEEd(_lang).format(startDate);
  String shortDate(int day) => DateFormat.MMMd(_lang).format(dateOf(day));
  String get _lang => _settings.locale.languageCode;

  // ---- Suhoor / iftar ----
  /// Calculated once per day (the countdown asks every second).
  DayPrayerTimes? _timesOn(DateTime day) {
    final at = _settings.lastLocation;
    if (at == null) return null;
    return _times.putIfAbsent(
      _dateOnly(day),
      () => switch (_prayers.timesFor(day, at, _settings.prayerSettings)) {
        Ok(:final value) => value,
        Err() => null,
      },
    );
  }

  bool get hasLocation => _settings.lastLocation != null;
  DateTime? get suhoorEnds => _timesOn(_now.value)?.times[Prayer.fajr];
  DateTime? get iftar => _timesOn(_now.value)?.times[Prayer.maghrib];
  String timeLabel(DateTime? t) => t == null ? '--:--' : DateFormat.jm(_lang).format(t);

  /// Next suhoor end or iftar; after maghrib, tomorrow's suhoor.
  ({FastEvent event, DateTime at})? get next {
    final now = _now.value;
    final fajr = suhoorEnds;
    final maghrib = iftar;
    if (fajr == null || maghrib == null) return null;
    if (now.isBefore(fajr)) return (event: FastEvent.suhoorEnds, at: fajr);
    if (now.isBefore(maghrib)) return (event: FastEvent.iftar, at: maghrib);
    final tomorrow = _timesOn(now.add(const Duration(days: 1)))?.times[Prayer.fajr];
    return tomorrow == null ? null : (event: FastEvent.suhoorEnds, at: tomorrow);
  }

  String get countdown {
    final n = next;
    if (n == null) return '--:--:--';
    final d = n.at.difference(_now.value);
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
  }

  /// 0..1 of the fasting day gone (fajr → maghrib), for the hero ring.
  double get fastFraction {
    final fajr = suhoorEnds;
    final maghrib = iftar;
    if (fajr == null || maghrib == null) return 0;
    final total = maghrib.difference(fajr).inSeconds;
    return (_now.value.difference(fajr).inSeconds / total).clamp(0, 1).toDouble();
  }

  // ---- Fasting log ----
  RamadanProgress get _p => _ramadan.progress;
  FastStatus statusOf(int day) => _p.fastOn(year, day);
  int get fasted => _p.countIn(year, FastStatus.fasted);
  int get missed => _p.countIn(year, FastStatus.missed);

  /// Only days that have begun can be marked.
  bool canMark(int day) => (today ?? 0) >= day;

  void cycleDay(int day) {
    if (!canMark(day)) return;
    unawaited(HapticFeedback.selectionClick());
    _ramadan.progress = _p.cycleFast(year, day);
  }

  // ---- Today's deeds ----
  bool isDone(RamadanDeed d) => today != null && _p.deedsOn(year, today!).contains(d);
  int get deedsDone => today == null ? 0 : _p.deedsOn(year, today!).length;

  void toggleDeed(RamadanDeed d) {
    final t = today;
    if (t == null) return;
    unawaited(HapticFeedback.selectionClick());
    _ramadan.progress = _p.toggleDeed(year, t, d);
  }

  // ---- Quran: one juz a day finishes it in Ramadan ----
  int get todaysJuz => (today ?? 1).clamp(1, 30);

  void openJuz(int juz) {
    final j = _index.value?.juz[juz - 1];
    if (j == null) return;
    unawaited(Get.toNamed<void>(AppRoutes.surah, arguments: (surah: j.surah, ayah: j.ayah)));
  }

  String juzStart(int juz) {
    final index = _index.value;
    final j = index?.juz[juz - 1];
    if (index == null || j == null) return '';
    return '${index.surah(j.surah).name} ${j.surah}:${j.ayah}';
  }

  // ---- Make-up fasts ----
  int get owed => _p.owed;
  int get owedBefore => _p.owedBefore;
  int get madeUp => _p.madeUp;
  void changeOwedBefore(int by) => _ramadan.progress = _p.withOwedBefore(owedBefore + by);
  void changeMadeUp(int by) => _ramadan.progress = _p.withMadeUp(madeUp + by);

  // ---- Duas ----
  AudioStatus duaStatus(RamadanDua d) => _audio.statusOf('ramadan:${d.id}');

  Future<void> toggleDua(RamadanDua d) async {
    final audio = d.audio;
    if (audio == null) return;
    await _audio.toggle(
      'ramadan:${d.id}',
      Uri.parse('asset:///$audio'),
      info: (title: d.titleKey.tr, subtitle: 'ramadan_title'.tr),
    );
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void onInit() {
    super.onInit();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _now.value = DateTime.now());
    unawaited(_loadIndex());
  }

  Future<void> _loadIndex() async {
    if (await _quran.index() case Ok(:final value)) _index.value = value;
  }

  @override
  void onClose() {
    _ticker?.cancel();
    super.onClose();
  }
}
