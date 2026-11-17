import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_pro/app/routes/app_routes.dart';
import 'package:quran_pro/core/errors/result.dart';
import 'package:quran_pro/core/services/audio_service.dart';
import 'package:quran_pro/core/services/quran_service.dart';
import 'package:quran_pro/core/services/surah_download_service.dart';
import 'package:quran_pro/data/models/quran_index.dart';
import 'package:quran_pro/domain/repositories/quran_audio_repository.dart';
import 'package:quran_pro/domain/repositories/quran_repository.dart';
import 'package:quran_pro/features/quran/viewmodels/surah_playlist.dart';

enum QuranTab { surah, juz }

/// A surah recommended by the Sunnah, shown in the hero card with its opening ayah.
typedef Featured = ({int surah, String badgeKey, String arabic, String translation});

final class QuranViewModel extends GetxController {
  QuranViewModel(this._repo, this._audio, this._quranAudio, this._quran, this._downloads);

  final QuranRepository _repo;
  final AudioService _audio;
  final QuranAudioRepository _quranAudio;
  final QuranService _quran;
  final SurahDownloadService _downloads;

  final searchController = TextEditingController();
  final Rxn<QuranIndex> _index = Rxn<QuranIndex>();
  final RxBool _failed = false.obs;
  final RxString _query = ''.obs;
  final Rx<QuranTab> _tab = QuranTab.surah.obs;

  // Opening ayahs: Uthmani text and Saheeh International, from api.alquran.cloud.
  static const Featured _kahf = (
    surah: 18,
    badgeKey: 'quran_friday_sunnah',
    arabic: 'ٱلْحَمْدُ لِلَّهِ ٱلَّذِىٓ أَنزَلَ عَلَىٰ عَبْدِهِ ٱلْكِتَٰبَ وَلَمْ يَجْعَل لَّهُۥ عِوَجَا',
    translation:
        '[All] praise is [due] to Allah, who has sent down upon His Servant the Book and has '
        'not made therein any deviance.',
  );
  static const Featured _mulk = (
    surah: 67,
    badgeKey: 'quran_night_sunnah',
    arabic: 'تَبَٰرَكَ ٱلَّذِى بِيَدِهِ ٱلْمُلْكُ وَهُوَ عَلَىٰ كُلِّ شَىْءٍۢ قَدِيرٌ',
    translation: 'Blessed is He in whose hand is dominion, and He is over all things competent.',
  );

  bool get loading => _index.value == null && !_failed.value;
  bool get failed => _failed.value;
  QuranTab get tab => _tab.value;
  String get query => _query.value;

  /// Al-Kahf on Fridays (Sunnah); Al-Mulk, recited before sleeping, every other day.
  Featured get featured => DateTime.now().weekday == DateTime.friday ? _kahf : _mulk;
  SurahInfo? get featuredSurah => _index.value?.surah(featured.surah);

  List<SurahInfo> get surahs {
    final all = _index.value?.surahs ?? const <SurahInfo>[];
    if (_query.value.trim().isEmpty) return all;
    final (:latin, :arabic) = _terms(_query.value);
    return [
      for (final s in all)
        if ('${s.number}' == latin ||
            (latin.isNotEmpty &&
                (_norm(s.name).contains(latin) || _norm(s.meaning).contains(latin))) ||
            (arabic.isNotEmpty && _normAr(s.arabic).contains(arabic)))
          s,
    ];
  }

  List<JuzInfo> get juz {
    final all = _index.value?.juz ?? const <JuzInfo>[];
    if (_query.value.trim().isEmpty) return all;
    final (:latin, :arabic) = _terms(_query.value);
    return [
      for (final j in all)
        if ('${j.number}' == latin ||
            (latin.isNotEmpty && _norm(j.name).contains(latin)) ||
            (arabic.isNotEmpty && _normAr(j.arabic).contains(arabic)))
          j,
    ];
  }

  String surahName(int number) => _index.value?.surah(number).name ?? '';

  static ({String latin, String arabic}) _terms(String q) => (latin: _norm(q), arabic: _normAr(q));

  /// Lower-case letters only, doubled vowels and a final "h" dropped,
  /// so "fatihah", "Al-Faatiha" and "al fatiha" all match.
  static String _norm(String s) => s
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9]'), '')
      .replaceAllMapped(RegExp(r'([aeiou])\1+'), (m) => m[1]!)
      .replaceAll(RegExp(r'h$'), '');

  /// Arabic letters only: vowel marks, Quranic signs and tatweel removed, alif forms unified,
  /// so a plain "الكهف" finds "الكَهۡفِ".
  static String _normAr(String s) => s
      .replaceAll(RegExp('[\u064B-\u065F\u0670\u06D6-\u06ED\u0640]'), '')
      .replaceAll(RegExp('[ٱأإآ]'), 'ا')
      .replaceAll(RegExp('[^\u0621-\u064A]'), '');

  Future<void> load() async {
    _failed.value = false;
    switch (await _repo.index()) {
      case Ok(:final value):
        _index.value = value;
      case Err():
        _failed.value = true;
    }
  }

  // ignore: use_setters_to_change_properties, passed as an onChanged tear-off
  void search(String q) => _query.value = q;

  void clearSearch() {
    searchController.clear();
    _query.value = '';
  }

  // ignore: use_setters_to_change_properties, passed as a segmented-control callback
  void selectTab(QuranTab t) => _tab.value = t;

  // ---- Recitation: the whole surah, ayah by ayah ----
  bool isDownloaded(int surah) => _downloads.isDownloaded(surah);

  // ---- Download all ----
  bool get downloadingAll => _downloads.downloadingAll;
  int get downloadedCount => _downloads.downloadedCount;
  int get surahCount => _index.value?.surahs.length ?? 114;
  bool get allDownloaded => downloadedCount >= surahCount;

  /// Surah currently downloading in a "download all" run, with its 0..1 progress.
  ({int surah, double progress})? get currentDownload {
    for (final s in _index.value?.surahs ?? const <SurahInfo>[]) {
      if (_downloads.progressOf(s.number) case final p?) return (surah: s.number, progress: p);
    }
    return null;
  }

  Future<void> downloadAll() async {
    final index = _index.value;
    if (index == null) return;
    final ok = await _downloads.downloadAll({
      for (final s in index.surahs) s.number: surahAudioRefs(s),
    });
    if (!ok) {
      Get
        ..closeAllSnackbars()
        ..showSnackbar(
          GetSnackBar(
            message: 'download_failed'.tr,
            duration: const Duration(seconds: 4),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 110),
            borderRadius: 16,
          ),
        );
    }
  }

  void cancelDownloadAll() => _downloads.cancelAll();

  AudioStatus previewStatus(int surah) => _audio.statusOf(surahTrackId(surah));

  List<Track> surahTracks(int surah) {
    final info = _index.value?.surah(surah);
    return info == null ? const [] : surahPlaylist(_quranAudio, info);
  }

  Future<void> togglePreview(int surah) async {
    await _audio.togglePlaylist(surahTrackId(surah), surahTracks(surah));
    if (previewStatus(surah) != AudioStatus.error) return;
    _snack(
      (_audio.error == AudioError.offline ? 'audio_offline' : 'audio_unavailable').tr,
      action: (label: 'retry'.tr, onTap: () => unawaited(togglePreview(surah))),
    );
  }

  /// Opens the reader, at [ayah] when given (a juz start, the last-read place).
  void openSurah(int surah, {int? ayah}) =>
      Get.toNamed<void>(AppRoutes.surah, arguments: (surah: surah, ayah: ayah));

  /// Where the reader stopped, if anywhere.
  AyahRef? get lastRead => _quran.lastRead;

  void _snack(String message, {({String label, VoidCallback onTap})? action}) => Get
    ..closeAllSnackbars()
    ..showSnackbar(
      GetSnackBar(
        message: message,
        duration: Duration(seconds: action == null ? 2 : 5),
        margin: const EdgeInsets.all(16),
        borderRadius: 16,
        mainButton: action == null
            ? null
            : TextButton(
                onPressed: () {
                  Get.closeAllSnackbars();
                  action.onTap();
                },
                child: Text(action.label),
              ),
      ),
    );

  @override
  void onInit() {
    super.onInit();
    unawaited(load());
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
