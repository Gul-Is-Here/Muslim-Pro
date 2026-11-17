/// Where recitation audio for a Quran reference lives.
abstract interface class QuranAudioRepository {
  /// Audio of a single ayah ([surah] 1–114, [ayah] numbered within that surah).
  Uri ayahAudio({required int surah, required int ayah});
}
