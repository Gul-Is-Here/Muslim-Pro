import 'package:quran_pro/data/datasources/local/quran_audio_files.dart';
import 'package:quran_pro/domain/repositories/quran_audio_repository.dart';

final class QuranAudioRepositoryImpl implements QuranAudioRepository {
  const QuranAudioRepositoryImpl({this.reciter = defaultReciter, this.files});

  /// Mishary Rashid Alafasy, 128 kbps (the app has no reciter picker yet).
  /// Verified: everyayah's 002152.mp3 carries byte-identical audio frames to the recording
  /// api.alquran.cloud lists for 2:152 in edition `ar.alafasy`.
  static const defaultReciter = 'Alafasy_128kbps';

  /// EveryAyah names files by surah + ayah-in-surah (SSSAAA), so no global-number table is needed.
  static const _base = 'https://everyayah.com/data';

  final String reciter;

  /// Downloaded recitations; a saved ayah plays from here, so it works offline.
  final QuranAudioFiles? files;

  @override
  Uri ayahAudio({required int surah, required int ayah}) {
    final local = files?.file(surah, ayah);
    if (local != null && local.existsSync()) return local.uri;
    return remoteAyahAudio(surah: surah, ayah: ayah);
  }

  /// Always the streaming URL (what a download fetches).
  Uri remoteAyahAudio({required int surah, required int ayah}) {
    // 286 = longest surah (Al-Baqarah); finer checks need per-surah ayah counts.
    if (surah < 1 || surah > 114 || ayah < 1 || ayah > 286) {
      throw ArgumentError('Invalid Quran reference $surah:$ayah');
    }
    String three(int n) => n.toString().padLeft(3, '0');
    return Uri.parse('$_base/$reciter/${three(surah)}${three(ayah)}.mp3');
  }
}
