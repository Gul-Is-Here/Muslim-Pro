import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_pro/core/network/connectivity_service.dart';
import 'package:quran_pro/core/services/audio_service.dart';
import 'package:quran_pro/core/services/quran_service.dart';
import 'package:quran_pro/core/services/surah_download_service.dart';
import 'package:quran_pro/data/datasources/local/quran_audio_files.dart';
import 'package:quran_pro/data/datasources/local/quran_local_ds.dart';
import 'package:quran_pro/data/repositories/quran_audio_repository_impl.dart';
import 'package:quran_pro/data/repositories/quran_repository_impl.dart';
import 'package:quran_pro/features/quran/viewmodels/quran_view_model.dart';
import 'package:quran_pro/features/quran/viewmodels/surah_playlist.dart';

class _Player extends Mock implements AudioPlayer;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final dir = Directory.systemTemp.createTempSync('quran_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => dir.path,
    );
    await GetStorage.init();
  });

  late QuranViewModel vm;
  setUp(() async {
    vm = QuranViewModel(
      const QuranRepositoryImpl(QuranLocalDataSource()),
      AudioService(ConnectivityService(), _Player()),
      const QuranAudioRepositoryImpl(),
      QuranService(GetStorage()),
      SurahDownloadService(
        QuranAudioFiles(Directory.systemTemp.createTempSync('dl')),
        (s, a) => Uri(),
      ),
    );
    await vm.load();
  });

  List<int> surahsFor(String q) {
    vm.search(q);
    return [for (final s in vm.surahs) s.number];
  }

  test('bundled index has every surah and juz, adding up to 6236 ayahs', () {
    expect(vm.failed, isFalse);
    expect(vm.surahs, hasLength(114));
    expect(vm.juz, hasLength(30));
    expect(vm.surahs.fold<int>(0, (sum, s) => sum + s.ayahs), 6236);
    expect(vm.juz[14].surah, 17); // Juz 15 opens Al-Isra
  });

  test('search forgives spelling: "fatihah", "Al Fatiha" and "faatiha" all find surah 1', () {
    expect(surahsFor('fatihah'), [1]);
    expect(surahsFor('Al Fatiha'), [1]);
    expect(surahsFor('faatiha'), [1]);
  });

  test('search by number, meaning and Arabic name', () {
    expect(surahsFor('18'), [18]);
    expect(surahsFor('the cave'), [18]);
    expect(surahsFor('الكَهۡفِ'), [18]);
    expect(surahsFor('الكهف'), [18], reason: 'typed without vowel marks');
    expect(surahsFor('zzz'), isEmpty);
    vm.search('amma');
    expect([for (final j in vm.juz) j.number], [20, 30]); // Amman Khalaq, Amma
  });

  test('a surah plays every ayah, opened by the Bismillah except Al-Fatiha and At-Tawbah', () {
    String file(Uri u) => u.pathSegments.last;
    final fatiha = vm.surahTracks(1);
    expect(fatiha.map((t) => file(t.url)), [for (var a = 1; a <= 7; a++) '00100$a.mp3']);

    final kahf = vm.surahTracks(18);
    expect(kahf, hasLength(111));
    expect(file(kahf.first.url), '001001.mp3'); // Bismillah
    expect(file(kahf[1].url), '018001.mp3');
    expect(file(kahf.last.url), '018110.mp3');

    final tawbah = vm.surahTracks(9);
    expect(tawbah, hasLength(129));
    expect(file(tawbah.first.url), '009001.mp3');
  });

  test('every bundled surah text matches the index ayah count, Bismillah not prefixed', () async {
    for (final info in vm.surahs) {
      final text = await const QuranLocalDataSource().surah(info.number);
      expect(text.length, info.ayahs, reason: 'surah ${info.number}');
      expect(text.english.length, info.ayahs);
      expect(text.urdu.length, info.ayahs);
      if (info.number != 1) expect(text.arabic.first, isNot(startsWith('بِسْمِ')));
    }
  });

  test('playlist positions map to ayahs around the opening Bismillah', () {
    expect(trackIndexOf(1, 1), 0); // Al-Fatiha: the Bismillah is ayah 1
    expect(trackIndexOf(18, 1), 1);
    expect(ayahAtTrack(18, 0), isNull); // Bismillah
    expect(ayahAtTrack(18, 5), 5);
    expect(trackIndexOf(9, 1), 0); // At-Tawbah has none
    expect(ayahAtTrack(9, 0), 1);
  });

  test('reader state survives a restart: last read, bookmarks, text size', () async {
    final box = GetStorage();
    final first = QuranService(box)
      ..lastRead = (surah: 18, ayah: 23)
      ..arabicSize =
          99 // clamped
      ..translation = QuranTranslation.urdu;
    expect(first.toggleBookmark((surah: 2, ayah: 255)), isTrue);
    await Future<void>.delayed(Duration.zero);

    final again = QuranService(box);
    expect(again.lastRead, (surah: 18, ayah: 23));
    expect(again.arabicSize, QuranService.maxArabicSize);
    expect(again.translation, QuranTranslation.urdu);
    expect(again.isBookmarked((surah: 2, ayah: 255)), isTrue);
    expect(again.toggleBookmark((surah: 2, ayah: 255)), isFalse);
    expect(again.isBookmarked((surah: 2, ayah: 255)), isFalse);
  });
}
