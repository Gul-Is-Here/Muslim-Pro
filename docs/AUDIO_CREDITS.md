# Audio credits

Every bundled recording, where it came from, and its license. Keep this file and the in-app
"Sound credits" sheet (`azan_credits_*` translation keys) in sync when adding or replacing audio.

## Azan notification sounds

Short excerpts (under 30 s, the iOS limit for notification sounds) of full recordings. Processing:
trimmed at the first natural pause, fades added, mixed down to mono, loudness-normalised to about
-16 LUFS, re-encoded (MP3 96 kbps for Android and the in-app preview, IMA4 CAF for iOS).

| App name | Files | Source | License |
|---|---|---|---|
| Makkah · Masjid al-Haram (default) | `assets/audio/azan_makkah.mp3`, `android/app/src/main/res/raw/azan_makkah.mp3`, `ios/Runner/azan_makkah.caf` | Full recording supplied by the project owner (`tool/audio_src/azanmakkah.mp3`, 215 s); excerpt 0.45 s–23.7 s (the opening takbir) | **Not stated** |
| Madinah · Masjid an-Nabawi | `assets/audio/azan_madinah.mp3`, `android/app/src/main/res/raw/azan_madinah.mp3`, `ios/Runner/azan_madinah.caf` | Full recording supplied by the project owner (`tool/audio_src/azanmadina.mp3`, 231 s); excerpt 0.55 s–22.3 s | **Not stated** |

**Before any public release:** confirm who recorded these and that the app may redistribute them
(Haramain broadcast recordings are usually copyrighted by the broadcaster), then fill in the
license column and the in-app credit (`AzanSound.credit`).

Removed on 2026-11-16 at the owner's request: "Tatarstan Village" (Freesound #168775, CC0) and
"Hamtramck, Michigan" (Freesound #255231, CC BY 3.0). Saved choices of either fall back to Makkah,
and their Android notification channels are deleted on startup.

## Quran recitation (streamed, not bundled)

Ayah audio streams from EveryAyah (`https://everyayah.com/data/Alafasy_128kbps/`, Mishary Rashid
Alafasy). It is not bundled; EveryAyah's usage terms still need a review before release.

## Arabic letter names (Learn → Noorani Qaida)

`assets/audio/letters/letter_01.mp3` … `letter_28.mp3`, alif to yaa in alphabet order.

- Source: Al-Bustan Seeds "Learn the Arabic letters" game,
  https://projects.albustanseeds.org/game/letters_sound/ (files `<id>s.mp3`).
- Licence: **none stated.** Bundled in the app at the owner's request.
- **Before any public release:** replace with recordings you have the right to distribute
  (or written permission from Al-Bustan Seeds). Without the files the letters stay silent;
  nothing else breaks.

## Kalima, dua and salah recitations (Learn lessons)

`assets/audio/phrases/*.mp3`, one clip per Arabic card in `assets/data/learn_curriculum.json`
(the card's `audio` field). Quiz questions quoting part of a card play that card's clip.

- Kalimas 1 and 3–6: the opening Arabic recitation cut from nooresunnat.com's kalima MP3s
  (the full files go on to English/Urdu translation).
- Everything else (spoken chapter title and "yaqool" trimmed off): Hisnul Muslim recordings from hisnmuslim.com (`/audio/ar/<id>.mp3`):
  2nd Kalima/after wudu 13, Bismillah 12, tawwabin 14, takbir 241, thana 28, ruku 33,
  sami'allah 38 + first phrase of 39, sujood 41, tashahhud 52, durood 53, sleep 105, waking 1,
  after eating 180, leaving home 16, entering masjid (last phrase of 20), leaving masjid
  (middle phrase of 21); Ramadan tracker: iftar 176, iftar as a guest 184, "inni sa'im" 186.
- No recording yet: the closing salam and "Bismillahi awwalahu wa akhirahu".
- Licence: **none stated** by either site. Committed and bundled in the app at the owner's request.
- **Before any public release:** replace or get permission. Missing files only make cards silent.

## Quran text and translations (Quran tab → reader)

`assets/quran/NNN.json`, one file per surah, built from api.alquran.cloud editions:

- Arabic: `quran-uthmani` (Tanzil Uthmani text). Tanzil allows verbatim redistribution with
  attribution; the text must not be altered. The only change is that the Bismillah is taken off
  the front of ayah 1 (surahs 2–114 except 9) so the reader shows it once above the surah.
- English: `en.sahih` (Saheeh International). Translation copyright stays with the publisher;
  check terms before a public release.
- Urdu: `ur.jalandhry` (Fateh Muhammad Jalandhry).
- Surah/juz index (`assets/data/quran_index.json`): api.alquran.cloud metadata.
