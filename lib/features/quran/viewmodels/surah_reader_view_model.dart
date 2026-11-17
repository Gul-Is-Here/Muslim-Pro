import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:quran_pro/core/errors/result.dart';
import 'package:quran_pro/core/services/audio_service.dart';
import 'package:quran_pro/core/services/quran_service.dart';
import 'package:quran_pro/core/services/settings_service.dart';
import 'package:quran_pro/core/services/surah_download_service.dart';
import 'package:quran_pro/data/models/quran_index.dart';
import 'package:quran_pro/domain/repositories/quran_audio_repository.dart';
import 'package:quran_pro/domain/repositories/quran_repository.dart';
import 'package:quran_pro/features/quran/viewmodels/surah_playlist.dart';

/// Which surah to open, and optionally where (a juz start or the last-read ayah).
typedef SurahArgs = ({int surah, int? ayah});

final class SurahReaderViewModel extends GetxController {
  SurahReaderViewModel(
    this._repo,
    this._quran,
    this._audio,
    this._quranAudio,
    this._settings,
    this._downloads,
    this._args,
  );

  final QuranRepository _repo;
  final QuranService _quran;
  final AudioService _audio;
  final QuranAudioRepository _quranAudio;
  final SettingsService _settings;
  final SurahDownloadService _downloads;
  final SurahArgs _args;

  static const speeds = [0.75, 1.0, 1.25, 1.5];

  final Rxn<SurahInfo> _info = Rxn<SurahInfo>();
  final Rxn<SurahText> _text = Rxn<SurahText>();
  final RxBool _failed = false.obs;
  final _scrollTo = StreamController<int>.broadcast();
  StreamSubscription<int?>? _indexSub;
  int? _lastScrolled;

  int get surah => _args.surah;
  bool get loading => _text.value == null && !_failed.value;
  bool get failed => _failed.value;
  SurahInfo? get info => _info.value;
  int get ayahCount => _text.value?.length ?? 0;
  bool get showBismillah => opensWithBismillah(surah);
  String get _trackId => surahTrackId(surah);

  /// Ayah numbers the view should bring into sight: the opening target, then each recited ayah.
  Stream<int> get scrollRequests => _scrollTo.stream;

  /// Ayah to show first, once the text is laid out.
  int? get initialAyah => _args.ayah;

  // ---- Text and display ----
  String arabic(int ayah) => _arabic[ayah - 1];

  /// The source puts a space before pause marks (ۖ ۗ ۚ ۛ ۜ); bound to the word before them they
  /// can never wrap onto a line of their own.
  List<String> _arabic = const [];
  static final _spaceBeforeMark = RegExp(r'\s+([\u06D6-\u06DC])');
  int juzOf(int ayah) => _text.value!.juz[ayah - 1];
  bool hasSajda(int ayah) => _text.value!.sajda.contains(ayah);

  /// A new juz starts at this ayah (and it is not the surah's first ayah).
  bool juzStartsAt(int ayah) => ayah > 1 && juzOf(ayah) != juzOf(ayah - 1);

  double get arabicSize => _quran.arabicSize;
  set arabicSize(double v) => _quran.arabicSize = v;

  /// The reader's choice, else the app language: Urdu for Urdu, English otherwise.
  QuranTranslation get translationMode =>
      _quran.translation ??
      (_settings.locale.languageCode == 'ur' ? QuranTranslation.urdu : QuranTranslation.english);
  set translationMode(QuranTranslation t) => _quran.translation = t;

  bool get translationIsUrdu => translationMode == QuranTranslation.urdu;

  String? translation(int ayah) => switch (translationMode) {
    QuranTranslation.english => _text.value!.english[ayah - 1],
    QuranTranslation.urdu => _text.value!.urdu[ayah - 1],
    QuranTranslation.off => null,
  };

  // ---- Bookmarks, copy, reading place ----
  bool isBookmarked(int ayah) => _quran.isBookmarked((surah: surah, ayah: ayah));

  void toggleBookmark(int ayah) {
    final added = _quran.toggleBookmark((surah: surah, ayah: ayah));
    _snack((added ? 'quran_bookmarked' : 'quran_bookmark_removed').tr);
  }

  Future<void> copyAyah(int ayah) async {
    final name = _info.value?.name ?? '';
    final t = translation(ayah);
    await Clipboard.setData(
      ClipboardData(text: '${arabic(ayah)}\n\n${t == null ? '' : '$t\n\n'}— $name $surah:$ayah'),
    );
    _snack('quran_copied'.tr);
  }

  /// The ayah at the top of the screen when scrolling settles: "continue reading" lands there.
  void readingAt(int ayah) => _quran.lastRead = (surah: surah, ayah: ayah);

  // ---- Recitation ----
  AudioStatus get status => _audio.statusOf(_trackId);
  bool get isPlaying => status == AudioStatus.playing;

  /// Ayah being recited (or paused on), null when idle or on the opening Bismillah.
  int? get playingAyah => switch (_audio.indexOf(_trackId)) {
    final i? when status != AudioStatus.idle => ayahAtTrack(surah, i),
    _ => null,
  };
  bool get onBismillah =>
      status != AudioStatus.idle && _audio.indexOf(_trackId) != null && playingAyah == null;

  double get speed => _audio.speed;
  AudioRepeat get repeat => _audio.repeat;

  List<Track> get _tracks {
    final i = _info.value;
    return i == null ? const [] : surahPlaylist(_quranAudio, i);
  }

  /// Play/pause; starting fresh begins where the reader is, else at the top.
  Future<void> togglePlay() async {
    if (status == AudioStatus.idle || status == AudioStatus.error) {
      final from = _quran.lastRead?.surah == surah ? _quran.lastRead!.ayah : null;
      await playAyah(from ?? 1, withBismillah: from == null || from == 1);
      return;
    }
    await _audio.togglePlaylist(_trackId, _tracks);
  }

  // ---- Offline download ----
  bool get downloaded => _downloads.isDownloaded(surah);

  /// 0..1 while this surah is downloading, else null.
  double? get downloadProgress => _downloads.progressOf(surah);

  /// Download, or cancel one in progress. Deleting goes through [deleteDownload] (the view
  /// confirms first).
  Future<void> toggleDownload() async {
    final i = _info.value;
    if (i == null) return;
    if (downloadProgress != null) return _downloads.cancel(surah);
    if (!await _downloads.download(surah, surahAudioRefs(i))) {
      _snack(
        'download_failed'.tr,
        action: (label: 'retry'.tr, onTap: () => unawaited(toggleDownload())),
      );
    } else if (downloaded) {
      _snack('download_done'.tr);
    }
  }

  Future<void> deleteDownload() => _downloads.delete(surah);

  Future<void> playAyah(int ayah, {bool withBismillah = false}) async {
    final index = withBismillah && showBismillah ? 0 : trackIndexOf(surah, ayah);
    await _audio.playFrom(_trackId, _tracks, index);
    if (status == AudioStatus.error) {
      _snack(
        (_audio.error == AudioError.offline ? 'audio_offline' : 'audio_unavailable').tr,
        action: (label: 'retry'.tr, onTap: () => unawaited(playAyah(ayah))),
      );
    }
  }

  Future<void> next() => _audio.next();
  Future<void> previous() => _audio.previous();

  Future<void> cycleSpeed() {
    final i = speeds.indexOf(speed);
    return _audio.setSpeed(speeds[(i + 1) % speeds.length]);
  }

  /// Off → repeat this ayah → repeat the surah → off.
  Future<void> cycleRepeat() =>
      _audio.setRepeat(AudioRepeat.values[(repeat.index + 1) % AudioRepeat.values.length]);

  // ---- Lifecycle ----
  Future<void> load() async {
    _failed.value = false;
    final (index, text) = (await _repo.index(), await _repo.surah(surah));
    if ((index, text) case (Ok(value: final i), Ok(value: final t))) {
      _info.value = i.surah(surah);
      _arabic = [for (final a in t.arabic) a.replaceAllMapped(_spaceBeforeMark, (m) => m[1]!)];
      _text.value = t;
    } else {
      _failed.value = true;
    }
  }

  void _onTrackChanged(int? _) {
    final ayah = playingAyah;
    if (ayah == null || ayah == _lastScrolled) return;
    _lastScrolled = ayah;
    _quran.lastRead = (surah: surah, ayah: ayah);
    _scrollTo.add(ayah);
  }

  void _snack(String message, {({String label, VoidCallback onTap})? action}) => Get
    ..closeAllSnackbars()
    ..showSnackbar(
      GetSnackBar(
        message: message,
        duration: Duration(seconds: action == null ? 2 : 5),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 120), // above the player
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
    _indexSub = _audio.indexChanges.listen(_onTrackChanged);
  }

  @override
  void onClose() {
    unawaited(_indexSub?.cancel());
    unawaited(_scrollTo.close());
    super.onClose();
  }
}
