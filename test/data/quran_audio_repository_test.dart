import 'package:flutter_test/flutter_test.dart';
import 'package:quran_pro/data/repositories/quran_audio_repository_impl.dart';

void main() {
  const repo = QuranAudioRepositoryImpl();
  String url(int s, int a) => repo.ayahAudio(surah: s, ayah: a).toString();

  test('builds EveryAyah SSSAAA file names for the default reciter', () {
    // 2:152 checked against api.alquran.cloud (ar.alafasy, global ayah 159): same audio frames.
    expect(url(2, 152), 'https://everyayah.com/data/Alafasy_128kbps/002152.mp3');
    expect(url(1, 1), 'https://everyayah.com/data/Alafasy_128kbps/001001.mp3');
    expect(url(114, 6), 'https://everyayah.com/data/Alafasy_128kbps/114006.mp3');
  });

  test('rejects references outside the Quran', () {
    for (final (s, a) in [(0, 1), (115, 1), (1, 0), (2, 287)]) {
      expect(
        () => repo.ayahAudio(surah: s, ayah: a),
        throwsArgumentError,
        reason: '$s:$a',
      );
    }
  });
}
