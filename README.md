# Quran Pro

Islamic learning and worship app: prayer times, Qibla, Quran, a Learn path with lessons and quizzes, duas, tasbeeh, a prayer tracker, Ramadan mode, a zakat calculator, the 99 Names and settings.

The app uses Flutter, GetX (MVVM) and Firebase. The app ID is `com.islamicnoorapp.app`, with `.dev` and `.stg` suffixes for the dev and staging flavors.

The architecture, rules and decisions are in [PROJECT_SETUP.md](PROJECT_SETUP.md).

## Setup

1. Install Flutter 3.47.9 or later, Node 24.12 or later, and the Firebase CLI (`npm i -g firebase-tools`). Then run `dart pub global activate flutterfire_cli`.
2. Run `flutter pub get`.
3. Get access to the three Firebase projects, then run the `flutterfire configure` loop in [PROJECT_SETUP.md §3.4](PROJECT_SETUP.md). It writes the gitignored config files and replaces the placeholder `firebase_options_*.dart`.
4. Copy `env/example.json` to `env/<flavor>.json` and fill it in. Ask the team lead for the values.
5. Run `tool/check_architecture.sh && flutter analyze && flutter test`.

## Run (flavors)

```sh
flutter run --flavor dev     -t lib/main_dev.dart     --dart-define-from-file=env/dev.json
flutter run --flavor staging -t lib/main_staging.dart --dart-define-from-file=env/staging.json
flutter run --flavor prod    -t lib/main_prod.dart    --dart-define-from-file=env/prod.json
```

## Emulators

```sh
firebase emulators:start --only auth,firestore,storage       # UI at http://localhost:4000
# then run dev with "USE_EMULATORS": "true" in env/dev.json
npm --prefix firebase_tests ci
firebase emulators:exec --only firestore,storage "npm --prefix firebase_tests test"   # rules tests
```

## Deploy rules, indexes and functions

```sh
firebase deploy --only firestore:rules,firestore:indexes,storage -P dev    # then staging, then prod
firebase deploy --only functions -P <alias>
```

Rules reach prod only after the rules tests pass in CI.

## Release builds

```sh
flutter build appbundle --flavor prod -t lib/main_prod.dart --release \
  --obfuscate --split-debug-info=build/symbols/prod --dart-define-from-file=env/prod.json
flutter build ipa --flavor prod -t lib/main_prod.dart --release \
  --obfuscate --split-debug-info=build/symbols/prod --dart-define-from-file=env/prod.json

# De-obfuscate Dart stack traces in Crashlytics:
firebase crashlytics:symbols:upload --app=<FIREBASE_ANDROID_APP_ID> build/symbols/prod
firebase crashlytics:symbols:upload --app=<FIREBASE_IOS_APP_ID> build/symbols/prod
```

Android release builds sign with `android/key.properties` (gitignored). Without that file they fall back to debug signing.

## CI secrets

Store each gitignored file base64-encoded as a CI secret and decode it before building:

- `firebase_options_<flavor>.dart`
- `google-services.json` for each flavor
- `GoogleService-Info.plist` for each flavor
- `env/<flavor>.json`
- the upload keystore
- `key.properties`
