# Audio credits

Every bundled recording, where it came from, and its license. Keep this file and the in-app
"Sound credits" sheet (`azan_credits_*` translation keys) in sync when adding or replacing audio.

## Azan notification sounds

Both are short excerpts (under 30 s, the iOS limit for notification sounds) of field recordings
published on Freesound. Changes made to both: trimmed, fades added, mixed down to mono,
loudness-normalised to about -16 LUFS, re-encoded (MP3 for Android/in-app preview, IMA4 CAF for iOS).

| App name | Files | Source | Author | License | Attribution required |
|---|---|---|---|---|---|
| Tatarstan Village (default) | `assets/audio/azan_tatarstan.mp3`, `android/app/src/main/res/raw/azan_tatarstan.mp3`, `ios/Runner/azan_tatarstan.caf` | [“morning_azan.wav”, Freesound #168775](https://freesound.org/people/Jahffar/sounds/168775/) — recorded in Bereske, Tatarstan, Aug 2012; excerpt 0.9 s–29.0 s | Jahffar | [CC0 1.0](http://creativecommons.org/publicdomain/zero/1.0/) | No (credited anyway) |
| Hamtramck, Michigan | `assets/audio/azan_hamtramck.mp3`, `android/app/src/main/res/raw/azan_hamtramck.mp3`, `ios/Runner/azan_hamtramck.caf` | [“Islamic Call to Prayer (Dhuhr Adhan Audiophile Field Recording from Hamtramck, MI 96 kHz 24 Bit Stereo).wav”, Freesound #255231](https://freesound.org/people/RJStefanski/sounds/255231/); excerpt 10.8 s–37.0 s | RJStefanski | [CC BY 3.0](http://creativecommons.org/licenses/by/3.0/) | **Yes** — shown in the app's Sound credits sheet |

Licenses were read from each Freesound sound page (the license link in the page HTML) on 2026-11-12.
The source files were Freesound's public HQ previews of those sounds.

### Considered and rejected

- Freesound #648427 (CC0, Mashhad) — too faint (-49 LUFS), the call is barely audible.
- Freesound #260102 (CC BY 3.0, Mt. Merapi) — the call is buried in ambience, no clear phrases.
- Freesound #161185 (CC BY 4.0, Istanbul) — several overlapping calls in city noise.
- Freesound #89738 (CC BY-NC 4.0, Mardin) — non-commercial license, not allowed in the app.
- University of Cambridge Cairo adhan recordings — CC BY-NC-ND, not allowed.

## Quran recitation (streamed, not bundled)

Ayah audio streams from EveryAyah (`https://everyayah.com/data/Alafasy_128kbps/`, Mishary Rashid
Alafasy). It is not bundled; EveryAyah's usage terms still need a review before release.
