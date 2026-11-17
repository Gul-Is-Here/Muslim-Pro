import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_pro/core/services/surah_download_service.dart';
import 'package:quran_pro/data/datasources/local/quran_audio_files.dart';
import 'package:quran_pro/data/models/quran_index.dart';
import 'package:quran_pro/data/repositories/quran_audio_repository_impl.dart';

void main() {
  late Directory dir;
  late List<Uri> fetched;
  late QuranAudioFiles files;
  var failAt = -1;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('recitations');
    fetched = [];
    failAt = -1;
    files = QuranAudioFiles(
      dir,
      fetch: (url) async {
        if (fetched.length == failAt) throw const SocketException('offline');
        fetched.add(url);
        return [1, 2, 3];
      },
    );
  });
  tearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  // Al-Ikhlas: Bismillah (1:1) + 4 ayahs.
  const ikhlas = <AyahRef>[
    (surah: 1, ayah: 1),
    (surah: 112, ayah: 1),
    (surah: 112, ayah: 2),
    (surah: 112, ayah: 3),
    (surah: 112, ayah: 4),
  ];

  test('a downloaded ayah plays from the device; others still stream', () async {
    final repo = QuranAudioRepositoryImpl(files: files);
    final service = SurahDownloadService(files, (s, a) => repo.remoteAyahAudio(surah: s, ayah: a));
    expect(repo.ayahAudio(surah: 112, ayah: 1).scheme, 'https');

    expect(await service.download(112, ikhlas), isTrue);
    expect(service.isDownloaded(112), isTrue);
    expect(fetched, hasLength(5));
    expect(repo.ayahAudio(surah: 112, ayah: 1).scheme, 'file');
    expect(repo.ayahAudio(surah: 1, ayah: 1).scheme, 'file', reason: 'Bismillah saved too');
    expect(repo.ayahAudio(surah: 113, ayah: 1).scheme, 'https');
    expect(service.bytes, 15);

    // Survives a restart: state comes from the marker files.
    expect(SurahDownloadService(files, (s, a) => Uri()).isDownloaded(112), isTrue);
  });

  test('a failed download is not marked complete and resumes without refetching', () async {
    final service = SurahDownloadService(files, (s, a) => Uri.parse('https://x/$s/$a'));
    failAt = 3;
    expect(await service.download(112, ikhlas), isFalse);
    expect(service.isDownloaded(112), isFalse);
    expect(dir.listSync().where((f) => f.path.endsWith('.part')), isEmpty);

    failAt = -1;
    expect(await service.download(112, ikhlas), isTrue);
    expect(fetched, hasLength(5), reason: 'the 3 saved files are not fetched again');
  });

  test('deleting a surah keeps the Bismillah other downloads still use', () async {
    final service = SurahDownloadService(files, (s, a) => Uri());
    await service.download(112, ikhlas);
    await service.download(1, [for (var a = 1; a <= 7; a++) (surah: 1, ayah: a)]);

    await service.delete(1);
    expect(service.isDownloaded(1), isFalse);
    expect(files.has(1, 1), isTrue, reason: 'Al-Ikhlas still opens with it');
    expect(files.has(1, 2), isFalse);

    await service.deleteAll();
    expect(service.downloadedCount, 0);
    expect(files.has(112, 1), isFalse);
  });

  test('download all skips saved surahs, stops on error, and can be resumed', () async {
    final service = SurahDownloadService(files, (s, a) => Uri.parse('https://x/$s/$a'));
    final all = {
      112: ikhlas,
      113: [(surah: 1, ayah: 1), for (var a = 1; a <= 5; a++) (surah: 113, ayah: a)],
      114: [(surah: 1, ayah: 1), for (var a = 1; a <= 6; a++) (surah: 114, ayah: a)],
    };
    await service.download(112, ikhlas); // 5 fetches
    failAt = 10; // Al-Falaq's 5 new ayahs (fetches 6–10) succeed, An-Nas fails
    expect(await service.downloadAll(all), isFalse);
    expect(service.downloadingAll, isFalse);
    expect([for (final s in all.keys) service.isDownloaded(s)], [true, true, false]);

    failAt = -1;
    expect(await service.downloadAll(all), isTrue);
    expect(service.downloadedCount, 3);
    expect(fetched.toSet(), hasLength(fetched.length), reason: 'nothing fetched twice');
  });
}
