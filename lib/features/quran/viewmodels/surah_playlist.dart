import 'package:get/get.dart';
import 'package:quran_pro/core/services/audio_service.dart';
import 'package:quran_pro/data/models/quran_index.dart';
import 'package:quran_pro/domain/repositories/quran_audio_repository.dart';

/// The Bismillah is recited before ayah 1 everywhere except Al-Fatiha (where it is ayah 1)
/// and At-Tawbah.
bool opensWithBismillah(int surah) => surah != 1 && surah != 9;

/// One id per surah, so the list's play button and the reader control the same recitation.
String surahTrackId(int surah) => 'quran:$surah';

/// Playlist position of [ayah] (1-based) in its surah's recitation.
int trackIndexOf(int surah, int ayah) => ayah - 1 + (opensWithBismillah(surah) ? 1 : 0);

/// Ayah at playlist position [index], or null for the opening Bismillah.
int? ayahAtTrack(int surah, int index) {
  final ayah = index + 1 - (opensWithBismillah(surah) ? 1 : 0);
  return ayah >= 1 ? ayah : null;
}

/// Audio files [s]'s recitation plays, in order: the Bismillah (1:1) where recited, then each ayah.
List<AyahRef> surahAudioRefs(SurahInfo s) => [
  if (opensWithBismillah(s.number)) (surah: 1, ayah: 1),
  for (var a = 1; a <= s.ayahs; a++) (surah: s.number, ayah: a),
];

/// Every ayah of [s] in order, opened by the Bismillah where it is recited.
List<Track> surahPlaylist(QuranAudioRepository audio, SurahInfo s) {
  final reciter = 'quran_reciter_full'.tr;
  final name = 'quran_surah_named'.trParams({'name': s.name});
  return [
    for (final r in surahAudioRefs(s))
      (
        url: audio.ayahAudio(surah: r.surah, ayah: r.ayah),
        info: (
          title: r.surah == s.number
              ? '$name (${s.number}:${r.ayah})'
              : '$name · ${'quran_bismillah'.tr}',
          subtitle: reciter,
        ),
      ),
  ];
}
