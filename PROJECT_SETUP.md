# Quran Pro — Project Setup

This is the setup guide for the Quran Pro Flutter app. The app covers prayer times, Qibla, Quran, a Learn path with lessons and quizzes, duas, tasbeeh, a prayer tracker, Ramadan mode, a zakat calculator, the 99 Names and settings. It uses **MVVM with GetX**, a **Firebase** backend and three **flavors** (dev, staging, prod).

Work through the steps in order. Each step lists the files it creates and ends with the four mandatory checks. All four checks can also be run automatically with `tool/check_architecture.sh` (Step 2).

- Baseline: Flutter 3.47.9 stable, Dart ^3.13.7. The repo is currently a fresh `flutter create` output.
- Package versions were taken from pub.dev and npm on **2026-11-11**.

---

## 0. Decisions and deviations from the brief

| # | Decision | Why |
|---|----------|-----|
| 1 | All Firebase code, including `firebase_options_*.dart`, Firebase init, Crashlytics and FCM, lives under `lib/data/datasources/remote/`. | The rule "no Firebase import outside remote datasources" then holds with **zero exceptions**, and a script can check it. |
| 2 | A 10-line sealed `Result<T>` (`Ok` / `Err`) replaces `fpdart`'s `Either`. | It avoids adding a dependency for a few lines of code. |
| 3 | The error state is named `ViewError<T>`, not `Error<T>`, and carries a **translation key**. | `Error` would shadow `dart:core`'s `Error`. Using keys keeps every message localizable. |
| 4 | `get_storage` is used for preferences. Hive is not used. Quran, duas and the 99 Names ship as **bundled JSON assets**. | The core content works fully offline with no database to migrate. |
| 5 | `--dart-define-from-file=env/<flavor>.json` is used instead of `flutter_dotenv`. | `flutter_dotenv` ships `.env` as a plain-text asset inside the APK. Dart defines are compiled into the binary, so **only public client IDs go there**. Real secrets live server-side, in Cloud Functions. |
| 6 | Apple sign-in uses `firebase_auth`'s `AppleAuthProvider`. | No `sign_in_with_apple` or `crypto` packages are needed, because Firebase handles the nonce. |
| 7 | `permission_handler` is dropped. | `geolocator` and `flutter_local_notifications` already request permissions, detect "permanently denied" and open system settings. |
| 8 | User-scoped ViewModels are registered **only in route bindings**. On sign-out, `Get.offAllNamed()` removes every route, and GetX calls `Get.delete()` on each route's controllers. | This avoids a hand-maintained delete list that can drift out of date or delete a controller that is still in use. |
| 9 | Pagination uses `startAfter([lastOrder])` rather than `startAfterDocument`. | It keeps `DocumentSnapshot`, a Firebase type, out of ViewModels. Firestore cost is the same. |
| 10 | `domain/` holds contracts only, and they reference `data/models`. | This follows the folder structure in the brief, which has no entities layer. |
| 11 | XP, streaks and badges live in `users/{uid}/stats/*`. Clients can read them but not write them, and Cloud Functions maintain them. | Profile rules stay simple, and leaderboard values can't be forged from the client. |

---

## 1. `pubspec.yaml` (pinned)

Replace the generated file with this:

```yaml
name: quran_pro
description: Islamic learning and worship app.
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: ^3.13.7
  flutter: ">=3.47.9"

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # State, DI, routing
  get: 4.7.3

  # Firebase
  firebase_core: 5.1.0
  firebase_auth: 7.0.1
  cloud_firestore: 7.1.0
  firebase_storage: 14.0.1
  firebase_messaging: 17.0.1
  firebase_crashlytics: 6.0.1
  firebase_analytics: 13.0.1
  firebase_remote_config: 7.0.1
  firebase_app_check: 0.5.1
  google_sign_in: 7.2.0

  # Worship features
  adhan: 2.0.0+1
  geolocator: 14.1.2
  just_audio: 0.10.6

  # Notifications
  flutter_local_notifications: 23.0.1
  timezone: 0.11.2
  flutter_timezone: 5.1.1

  # Storage, network, utils
  get_storage: 2.1.1
  flutter_secure_storage: 11.2.0
  connectivity_plus: 7.3.1 # 7.3.2 needs dbus 0.8, geolocator_linux needs 0.7
  equatable: 3.0.0
  logger: 2.8.0
  intl: any # flutter_localizations dictates the version; the exact one is locked in pubspec.lock

dev_dependencies:
  flutter_test:
    sdk: flutter
  very_good_analysis: 11.0.0
  mocktail: 1.0.5

flutter:
  uses-material-design: true
  assets:
    - assets/data/    # quran.json, duas.json, names_of_allah.json (offline core content)
    - assets/audio/   # in-app azan preview
  fonts:
    - family: Amiri
      fonts: [{ asset: assets/fonts/Amiri-Regular.ttf }]
    - family: NotoNastaliqUrdu
      fonts: [{ asset: assets/fonts/NotoNastaliqUrdu-Regular.ttf }]
```

> These versions resolve together; `pubspec.lock` pins the rest, so commit it. `connectivity_plus` stays at 7.3.1, because 7.3.2 conflicts with `geolocator` on Linux. `flutter_qiblah` was **dropped**: 3.2.0 still calls `jcenter()`, which breaks the Android build under Gradle 9 / AGP 9. `adhan` already computes the Qibla bearing (`adhan.Qibla`), so the Qibla feature only needs a compass package, chosen and checked for AGP 9 support when that feature is built. The fonts are already in `assets/fonts/`. Both are OFL-licensed.

`analysis_options.yaml`:

```yaml
include: package:very_good_analysis/analysis_options.yaml

analyzer:
  exclude:
    - build/**
    - lib/data/datasources/remote/firebase_options/**

formatter:
  page_width: 100

linter:
  rules:
    public_member_api_docs: false # app, not a package
    lines_longer_than_80_chars: false # formatter enforces 100
    unnecessary_type_name_in_constructor: false # keep classic constructor syntax
    sort_pub_dependencies: false # pubspec is grouped by purpose
```

`very_good_analysis` already enables `avoid_print`, strict casts, strict inference and strict raw types, `prefer_const_constructors` and `unawaited_futures`.

**Files:** `pubspec.yaml`, `analysis_options.yaml`

**Checks:** no views or controllers yet ✅ · Firebase is only declared as dependencies ✅ · no secrets ✅

---

## 2. Folder structure and base files

### 2.1 Scaffold

```sh
rm lib/main.dart test/widget_test.dart   # replaced by flavor entry points; the default test imports MyApp
mkdir -p lib/app/{bindings,routes,middlewares,session} \
  lib/core/{config,theme,localization,errors,network,services,utils,widgets} \
  lib/data/{models,repositories,datasources/local,datasources/remote/firebase_options} \
  lib/domain/repositories assets/{data,audio,fonts} env tool firebase_tests functions
for f in onboarding auth home prayer_times qibla quran learn duas tasbeeh tracker ramadan tools settings; do
  mkdir -p lib/features/$f/{views,viewmodels,bindings}
done
touch assets/data/.gitkeep assets/audio/.gitkeep
```

### 2.2 Target tree (files created by this guide)

```
quran_pro/
├── firebase.json  .firebaserc  firestore.rules  firestore.indexes.json  storage.rules
├── env/example.json                  # committed template; env/{dev,staging,prod}.json are gitignored
├── tool/check_architecture.sh
├── firebase_tests/package.json  rules.test.mjs
├── functions/src/index.ts            # XP/streak writer (Admin SDK)
├── lib/
│   ├── main_dev.dart  main_staging.dart  main_prod.dart
│   ├── app/
│   │   ├── app.dart  bootstrap.dart
│   │   ├── bindings/initial_binding.dart
│   │   ├── middlewares/auth_middleware.dart
│   │   ├── routes/app_routes.dart  app_pages.dart
│   │   └── session/session_controller.dart
│   ├── core/
│   │   ├── config/flavor_config.dart  env.dart
│   │   ├── errors/app_exception.dart  failure.dart  error_mapper.dart  result.dart
│   │   ├── localization/app_translations.dart  en.dart  ur.dart  ar.dart
│   │   ├── network/connectivity_service.dart
│   │   ├── services/auth_service.dart  settings_service.dart  location_service.dart
│   │   │            notification_service.dart  prayer_schedule_service.dart  audio_service.dart
│   │   ├── theme/app_colors.dart  app_text_styles.dart  app_theme.dart
│   │   ├── utils/app_log.dart  formatters.dart  validators.dart  view_state.dart
│   │   └── widgets/error_retry.dart  offline_banner.dart
│   ├── data/
│   │   ├── models/app_user.dart  prayer.dart  day_prayer_times.dart  prayer_settings.dart
│   │   │          user_location.dart  lesson_model.dart  push_message.dart
│   │   ├── datasources/local/prayer_calc_local_ds.dart
│   │   ├── datasources/remote/
│   │   │   ├── firebase_options/firebase_options_{dev,staging,prod}.dart   # generated, gitignored
│   │   │   ├── firebase_initializer.dart  firebase_guard.dart
│   │   │   ├── auth_remote_ds.dart  lesson_remote_ds.dart
│   │   │   └── crash_reporter_remote_ds.dart  messaging_remote_ds.dart
│   │   └── repositories/run_catching.dart  auth_repository_impl.dart  prayer_times_repository_impl.dart
│   ├── domain/repositories/auth_repository.dart  prayer_times_repository.dart
│   └── features/
│       ├── onboarding/  auth/  home/  prayer_times/      # implemented in this guide
│       └── qibla/ quran/ learn/ duas/ tasbeeh/ tracker/ ramadan/ tools/ settings/   # views/ viewmodels/ bindings/
└── test/
    ├── core/translations_test.dart
    ├── data/prayer_times_repository_test.dart
    └── features/auth/auth_view_model_test.dart  auth_view_test.dart
```

**Layer rules.** CI enforces these with the script below.

| Layer | May import | Must not import |
|-------|-----------|-----------------|
| `features/*/views` | own ViewModel through `GetView<T>`, `core/widgets`, `core/theme`, `core/utils` | Firebase, datasources, repositories, `Get.put` / `Get.find` |
| `features/*/viewmodels` | `domain/repositories`, `core/services`, `data/models` | datasources, Firebase |
| `data/repositories` | datasources, `core/errors` | Firebase |
| `data/datasources/remote` | Firebase SDKs | `features/*` |

### 2.3 `.gitignore` additions

```gitignore
# Firebase config per flavor (generated by flutterfire; provisioned from CI secrets)
android/app/src/*/google-services.json
ios/flavors/*/GoogleService-Info.plist
lib/data/datasources/remote/firebase_options/firebase_options_*.dart

# Build-time values and signing
env/*.json
!env/example.json
android/key.properties
*.jks
*.keystore

# Obfuscation symbols (upload to Crashlytics, never commit)
build/symbols/

# Rules tests / functions
firebase_tests/node_modules/
functions/node_modules/
functions/lib/
*-debug.log
```

> Until `flutterfire configure` runs, `firebase_options/firebase_options_{dev,staging,prod}.dart` are **placeholder stubs**. The code compiles, analyzes and passes its tests, but the app throws `UnsupportedError` at startup. They are gitignored, and `flutterfire configure` overwrites them.
>
> Firebase client API keys identify the project; they do not authorize anything. Security comes from rules, App Check and API-key restrictions (Step 3.6). They are gitignored anyway, as the brief asks. As a result, a fresh clone **won't compile** until you run `flutterfire configure` (Step 3.3) or CI writes the files.

### 2.4 `tool/check_architecture.sh`

```sh
#!/usr/bin/env bash
# Mechanical version of the four per-step checks. Run locally and in CI.
set -uo pipefail
fail=0
err() { echo "✗ $1"; fail=1; }

# 1. Firebase SDKs only in remote datasources
hits=$(grep -rlE "package:(firebase_[a-z_]+|cloud_firestore|google_sign_in)/" lib --include='*.dart' \
       | grep -v '^lib/data/datasources/remote/' || true)
[ -n "$hits" ] && err "Firebase import outside data/datasources/remote:\n$hits"

# 2. Views: no DI, no data layer, no Firebase
hits=$(grep -rnE "Get\.(put|lazyPut|putAsync|find)\b|datasources/|repositories/" lib/features/*/views || true)
[ -n "$hits" ] && err "View touches DI or the data layer:\n$hits"

# 3. ViewModels never touch datasources
hits=$(grep -rn "datasources/" lib/features/*/viewmodels || true)
[ -n "$hits" ] && err "ViewModel imports a datasource:\n$hits"

# 4. Anything holding a disposable must override onClose
for f in $(grep -rlE "Timer|StreamSubscription|TextEditingController|AnimationController|PageController|AudioPlayer|Worker|AppLifecycleListener" \
             lib/features/*/viewmodels lib/core/services lib/core/network lib/app/session 2>/dev/null); do
  grep -q "void onClose" "$f" || err "missing onClose(): $f"
done

# 5. No hardcoded keys outside generated (gitignored) options
hits=$(grep -rnE "AIza[0-9A-Za-z_-]{20,}|-----BEGIN (RSA )?PRIVATE KEY" lib android/app/src/main ios/Runner --include='*.*' \
       | grep -vE 'firebase_options/|GoogleService-Info.plist|google-services.json' || true)
[ -n "$hits" ] && err "Possible hardcoded secret:\n$hits"

[ $fail -eq 0 ] && echo "✓ architecture checks passed"
exit $fail
```

`chmod +x tool/check_architecture.sh`. In CI, run it together with `dart format --set-exit-if-changed .`, `flutter analyze` and `flutter test`.

**Files:** directories, `.gitignore`, `tool/check_architecture.sh`

**Checks:** no views or controllers yet ✅ · no Firebase code yet ✅ · secrets are gitignored and scanned ✅

---

## 3. Flavors, Firebase per flavor, App Check

### 3.1 Identifiers

The app ID is **`com.islamicnoorapp.app`**. It has replaced the template's `com.example.quran_pro` / `com.example.quranPro` on Android, iOS, macOS and Linux, and `MainActivity.kt` now lives in `kotlin/com/islamicnoorapp/app/`.

| Flavor | Android applicationId | iOS bundle ID | Firebase project |
|--------|----------------------|---------------|------------------|
| dev | `com.islamicnoorapp.app.dev` | `com.islamicnoorapp.app.dev` | `quran-pro-dev` |
| staging | `com.islamicnoorapp.app.stg` | `com.islamicnoorapp.app.stg` | `quran-pro-staging` |
| prod | `com.islamicnoorapp.app` | `com.islamicnoorapp.app` | `quran-pro-prod` |

### 3.2 Android — `android/app/build.gradle.kts`

```kotlin
import java.util.Properties

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")    // added by flutterfire configure
    id("com.google.firebase.crashlytics")   // added by flutterfire configure
    id("dev.flutter.flutter-gradle-plugin")
}

val keystore = Properties().apply {
    rootProject.file("key.properties").takeIf { it.exists() }?.inputStream()?.use { load(it) }
}

android {
    namespace = "com.islamicnoorapp.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true   // required by flutter_local_notifications
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.islamicnoorapp.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystore["keyAlias"] as String?
            keyPassword = keystore["keyPassword"] as String?
            storeFile = (keystore["storeFile"] as String?)?.let { file(it) }
            storePassword = keystore["storePassword"] as String?
        }
    }

    buildFeatures {
        resValues = true // per-flavor app_name (off by default since AGP 9)
    }

    flavorDimensions += "env"
    productFlavors {
        create("dev")     { dimension = "env"; applicationIdSuffix = ".dev"; resValue("string", "app_name", "Quran Pro Dev") }
        create("staging") { dimension = "env"; applicationIdSuffix = ".stg"; resValue("string", "app_name", "Quran Pro Stg") }
        create("prod")    { dimension = "env"; resValue("string", "app_name", "Quran Pro") }
    }

    buildTypes {
        release {
            // Without android/key.properties (local machines), fall back to debug signing.
            signingConfig = signingConfigs.getByName(if (keystore.isEmpty) "debug" else "release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

dependencies { coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4") }

flutter { source = "../.." }
```

`android/app/proguard-rules.pro`:

```proguard
# flutter_local_notifications serializes scheduled notifications with Gson
-keep class com.dexterous.** { *; }
-keepattributes Signature
# Most plugins ship consumer rules; add more only if a release build crashes with ClassNotFound.
```

`android/app/src/main/res/raw/keep.xml` stops resource shrinking from deleting the azan sound and the notification icon:

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources xmlns:tools="http://schemas.android.com/tools"
    tools:keep="@raw/azan,@drawable/ic_notification" />
```

Put `azan.mp3` in `res/raw/`. `ic_notification` is a white, monochrome vector in `res/drawable/`.

`AndroidManifest.xml` (main):

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.VIBRATE"/>

<application android:label="@string/app_name" ...>
    <!-- Re-arm scheduled prayer alerts after reboot / app update -->
    <receiver android:exported="false"
        android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"/>
    <receiver android:exported="false"
        android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
        <intent-filter>
            <action android:name="android.intent.action.BOOT_COMPLETED"/>
            <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
            <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
        </intent-filter>
    </receiver>
    ...
</application>
```

> Use `SCHEDULE_EXACT_ALARM`, which the user can grant, not `USE_EXACT_ALARM`. Play restricts `USE_EXACT_ALARM` to alarm-clock and calendar apps. Without the grant, the app falls back to inexact alarms (Step 7.4).

### 3.3 iOS

Steps 1 to 4 are **already done** in the repo; a script built them with the `xcodeproj` gem.

1. The `Debug-<flavor>`, `Release-<flavor>` and `Profile-<flavor>` configurations exist for `dev`, `staging` and `prod`. They are copied from the base configurations, so they share Flutter's xcconfig files. The base `Debug`, `Release` and `Profile` behave like prod.
2. The shared schemes `dev`, `staging` and `prod` exist, and each one uses its own configurations.
3. `PRODUCT_BUNDLE_IDENTIFIER` is set for each configuration (table in 3.1). `APP_DISPLAY_NAME` drives `CFBundleDisplayName`.
4. The User-Defined settings `GOOGLE_IOS_CLIENT_ID` and `GOOGLE_REVERSED_CLIENT_ID` exist but are **empty**. Fill them for each configuration from that flavor's `GoogleService-Info.plist` (`CLIENT_ID` and `REVERSED_CLIENT_ID`) before testing Google sign-in on iOS.

The `Podfile` maps every flavored configuration to `:debug` or `:release` and sets `platform :ios, '15.0'`.
5. Capabilities: Push Notifications, Background Modes → Remote notifications, Sign in with Apple, and App Attest.
6. Add an `azan.caf` (30 seconds or less) to the Runner target. iOS falls back to the default sound for longer files.

`Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Your approximate location is used on this device to calculate prayer times and the Qibla direction.</string>
<key>GIDClientID</key>
<string>$(GOOGLE_IOS_CLIENT_ID)</string>
<key>CFBundleURLTypes</key>
<array><dict><key>CFBundleURLSchemes</key><array><string>$(GOOGLE_REVERSED_CLIENT_ID)</string></array></dict></array>
<key>UIBackgroundModes</key>
<array><string>remote-notification</string></array>
```

Localize the permission strings in `InfoPlist.strings` for `ur` and `ar`.

### 3.4 Firebase projects per flavor

```sh
dart pub global activate flutterfire_cli
firebase login

for env in dev staging prod; do
  case $env in
    dev)     id=com.islamicnoorapp.app.dev; proj=quran-pro-dev;     cfg=dev ;;
    staging) id=com.islamicnoorapp.app.stg; proj=quran-pro-staging; cfg=staging ;;
    prod)    id=com.islamicnoorapp.app;     proj=quran-pro-prod;    cfg=prod ;;
  esac
  flutterfire configure --yes \
    --project=$proj --platforms=android,ios \
    --out=lib/data/datasources/remote/firebase_options/firebase_options_$env.dart \
    --android-package-name=$id --android-out=android/app/src/$env/google-services.json \
    --ios-bundle-id=$id --ios-build-config=Debug-$cfg --ios-out=ios/flavors/$env/GoogleService-Info.plist
done
```

`--ios-build-config` adds an Xcode build phase that copies the right plist. Repeat it for `Release-<flavor>` and `Profile-<flavor>`, or extend that run script to match `*-<flavor>`.

Then, for each Firebase project:

- **Authentication:** enable Anonymous, Email/Password, Google and Apple. Turn on email enumeration protection.
- **SHA-1 and SHA-256:** add the debug and upload keys (`cd android && ./gradlew signingReport`). For prod, also add the **Play App Signing** key from Play Console. Google sign-in and Play Integrity both need these.
- **Cloud Messaging:** upload the APNs auth key.
- **Firestore:** create the database in production mode. Rules deploy in Step 8.

`.firebaserc`:

```json
{ "projects": { "dev": "quran-pro-dev", "staging": "quran-pro-staging", "prod": "quran-pro-prod" } }
```

### 3.5 Build-time values

`env/example.json` is committed. Copy it to `env/dev.json`, `env/staging.json` and `env/prod.json`, which are gitignored.

```json
{
  "GOOGLE_SERVER_CLIENT_ID": "<web OAuth client id>.apps.googleusercontent.com",
  "APP_CHECK_DEBUG_TOKEN": "",
  "USE_EMULATORS": "false"
}
```

`lib/core/config/env.dart`:

```dart
/// Values from `--dart-define-from-file=env/<flavor>.json`.
/// They are compiled into the app binary: public client identifiers only, never server secrets.
abstract final class Env {
  static const googleServerClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
  static const appCheckDebugToken = String.fromEnvironment('APP_CHECK_DEBUG_TOKEN');
  static const useEmulators = bool.fromEnvironment('USE_EMULATORS');
}
```

`lib/core/config/flavor_config.dart`:

```dart
enum Flavor { dev, staging, prod }

final class FlavorConfig {
  const FlavorConfig(this.flavor);

  final Flavor flavor;

  /// Set once in bootstrap(); defaults to dev so tests need no setup.
  static FlavorConfig instance = const FlavorConfig(Flavor.dev);

  bool get isDev => flavor == Flavor.dev;
  bool get isProd => flavor == Flavor.prod;
}
```

### 3.6 Firebase init and App Check

`lib/data/datasources/remote/firebase_initializer.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:quran_pro/core/config/env.dart';
import 'package:quran_pro/core/config/flavor_config.dart';
import 'package:quran_pro/data/datasources/remote/firebase_options/firebase_options_dev.dart' as dev;
import 'package:quran_pro/data/datasources/remote/firebase_options/firebase_options_prod.dart' as prod;
import 'package:quran_pro/data/datasources/remote/firebase_options/firebase_options_staging.dart' as staging;

abstract final class FirebaseInitializer {
  static Future<void> init(Flavor flavor) async {
    await Firebase.initializeApp(
      options: switch (flavor) {
        Flavor.dev => dev.DefaultFirebaseOptions.currentPlatform,
        Flavor.staging => staging.DefaultFirebaseOptions.currentPlatform,
        Flavor.prod => prod.DefaultFirebaseOptions.currentPlatform,
      },
    );

    // Debug provider in dev only. Staging must ship through Play internal testing / TestFlight,
    // or Play Integrity / App Attest attestation fails.
    final debugToken = Env.appCheckDebugToken.isEmpty ? null : Env.appCheckDebugToken;
    await FirebaseAppCheck.instance.activate(
      providerAndroid: flavor == Flavor.dev
          ? AndroidDebugProvider(debugToken: debugToken)
          : const AndroidPlayIntegrityProvider(),
      providerApple: flavor == Flavor.dev
          ? AppleDebugProvider(debugToken: debugToken)
          : const AppleAppAttestWithDeviceCheckFallbackProvider(),
    );

    // Must be set before any other Firestore call.
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: 100 * 1024 * 1024,
    );

    if (flavor == Flavor.dev && Env.useEmulators) {
      final host = defaultTargetPlatform == TargetPlatform.android ? '10.0.2.2' : 'localhost';
      await FirebaseAuth.instance.useAuthEmulator(host, 9099);
      FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
      await FirebaseStorage.instance.useStorageEmulator(host, 9199);
    }
  }
}
```

App Check rollout:

1. Register the apps in Firebase Console → App Check: Play Integrity for Android, App Attest for iOS.
2. Register the dev debug tokens.
3. Ship with **monitoring** first. Turn on **enforcement** for Firestore, Storage and Auth once the metrics show about 99% verified requests.

**Restrict API keys** in Google Cloud Console → Credentials, for each project:

- Android key: limited to the flavor's package names plus their SHA-1s.
- iOS key: limited to the bundle IDs.
- Both keys: API restrictions limited to the Firebase APIs actually used.

### 3.7 Crash reporting and bootstrap

`lib/data/datasources/remote/crash_reporter_remote_ds.dart`:

```dart
import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Never attach PII: no setUserIdentifier(email), no custom keys with names or locations.
final class CrashReporterRemoteDataSource {
  CrashReporterRemoteDataSource([FirebaseCrashlytics? crashlytics])
      : _c = crashlytics ?? FirebaseCrashlytics.instance;

  final FirebaseCrashlytics _c;

  Future<void> setEnabled({required bool enabled}) => _c.setCrashlyticsCollectionEnabled(enabled);

  void recordFlutterFatalError(FlutterErrorDetails details) =>
      unawaited(_c.recordFlutterFatalError(details));

  void recordError(Object error, StackTrace? stack, {bool fatal = false}) =>
      unawaited(_c.recordError(error, stack, fatal: fatal));
}
```

`lib/app/bootstrap.dart` is the composition root. It imports datasource classes but never Firebase packages:

```dart
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:quran_pro/app/app.dart';
import 'package:quran_pro/app/bindings/initial_binding.dart';
import 'package:quran_pro/app/session/session_controller.dart';
import 'package:quran_pro/core/config/flavor_config.dart';
import 'package:quran_pro/core/services/auth_service.dart';
import 'package:quran_pro/core/utils/app_log.dart';
import 'package:quran_pro/data/datasources/remote/crash_reporter_remote_ds.dart';
import 'package:quran_pro/data/datasources/remote/firebase_initializer.dart';
import 'package:quran_pro/data/datasources/remote/messaging_remote_ds.dart';

Future<void> bootstrap(Flavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();
  FlavorConfig.instance = FlavorConfig(flavor);
  await FirebaseInitializer.init(flavor);

  final crash = CrashReporterRemoteDataSource();
  await crash.setEnabled(enabled: !FlavorConfig.instance.isDev);
  if (!FlavorConfig.instance.isDev) {
    // Dev keeps Flutter's default red-screen/console reporting.
    FlutterError.onError = crash.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      crash.recordError(error, stack, fatal: true);
      return true;
    };
    AppLog.errorSink = crash.recordError;
  }
  MessagingRemoteDataSource.registerBackgroundHandler();

  await Future.wait([
    GetStorage.init(),
    GetStorage.init(SessionController.userCacheBox),
    initializeDateFormatting(),
  ]);
  InitialBinding().dependencies();
  await Get.find<AuthService>().ready; // restored session known before the first route
  runApp(const App());
}
```

`lib/main_dev.dart` (staging and prod are identical apart from the flavor):

```dart
import 'package:quran_pro/app/bootstrap.dart';
import 'package:quran_pro/core/config/flavor_config.dart';

Future<void> main() => bootstrap(Flavor.dev);
```

Run with:

```sh
flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=env/dev.json
```

**Files:** `build.gradle.kts`, `proguard-rules.pro`, `res/raw/keep.xml`, manifest, Xcode configs and schemes, `Info.plist`, `.firebaserc`, `env/example.json`, `core/config/*`, `firebase_initializer.dart`, `crash_reporter_remote_ds.dart`, `app/bootstrap.dart`, `main_*.dart`

**Checks:**
- **No logic in views:** no views in this step ✅
- **Disposal:** no controllers in this step ✅
- **Firebase imports:** only `firebase_initializer.dart`, `crash_reporter_remote_ds.dart` and the generated options, all under `data/datasources/remote/` ✅
- **Secrets:** config files and env files are gitignored, and values come from `--dart-define-from-file` ✅

---

## 4. Core

### 4.1 Errors and `Result`

`lib/core/errors/app_exception.dart`:

```dart
/// Thrown by datasources only, carrying a backend-neutral error code.
final class AppException implements Exception {
  const AppException(this.code);

  final String code;

  static const cancelled = 'cancelled';
  static const unknown = 'unknown';

  @override
  String toString() => 'AppException($code)';
}
```

`lib/core/errors/error_mapper.dart`:

```dart
/// Maps backend error codes to translation keys shown to the user.
abstract final class ErrorMapper {
  static const _cancellations = {'cancelled', 'canceled', 'web-context-canceled'};

  static const _keys = <String, String>{
    'invalid-credential': 'err_invalid_credential',
    'wrong-password': 'err_invalid_credential',
    'user-not-found': 'err_invalid_credential',
    'invalid-email': 'err_invalid_email',
    'weak-password': 'err_weak_password',
    'email-already-in-use': 'err_email_in_use',
    'too-many-requests': 'err_too_many_requests',
    'network-request-failed': 'err_network',
    'unavailable': 'err_network',
    'deadline-exceeded': 'err_network',
    'permission-denied': 'err_permission',
    'not-found': 'err_not_found',
    'google-sign-in-failed': 'err_google_failed',
    'invalid-location': 'err_invalid_location',
  };

  static bool isCancellation(String code) => _cancellations.contains(code);
  static String keyFor(String code) => _keys[code] ?? 'err_unknown';
}
```

`lib/core/errors/failure.dart`:

```dart
import 'package:equatable/equatable.dart';
import 'package:quran_pro/core/errors/error_mapper.dart';

final class Failure extends Equatable {
  const Failure(this.code);

  final String code;

  String get messageKey => ErrorMapper.keyFor(code);
  bool get isCancelled => ErrorMapper.isCancellation(code);

  @override
  List<Object> get props => [code];
}
```

`lib/core/errors/result.dart`:

```dart
import 'package:quran_pro/core/errors/failure.dart';

sealed class Result<T> {
  const Result();
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;
}
```

### 4.2 `ViewState`

`lib/core/utils/view_state.dart`:

```dart
/// UI state of one async operation. `messageKey` is a translation key, never raw text.
sealed class ViewState<T> {
  const ViewState();
}

final class Idle<T> extends ViewState<T> {
  const Idle();
}

final class Loading<T> extends ViewState<T> {
  const Loading();
}

final class Success<T> extends ViewState<T> {
  const Success(this.data);
  final T data;
}

final class Empty<T> extends ViewState<T> {
  const Empty();
}

final class ViewError<T> extends ViewState<T> {
  const ViewError(this.messageKey);
  final String messageKey;
}
```

### 4.3 Utils

`lib/core/utils/app_log.dart`:

```dart
import 'package:logger/logger.dart';
import 'package:quran_pro/core/config/flavor_config.dart';

/// The only logging entry point (`avoid_print` is on). Never log PII: email, names, coordinates.
abstract final class AppLog {
  static final Logger _logger = Logger(
    level: switch (FlavorConfig.instance.flavor) {
      Flavor.dev => Level.debug,
      Flavor.staging => Level.warning,
      Flavor.prod => Level.off,
    },
    printer: PrettyPrinter(methodCount: 0),
  );

  /// Set in bootstrap (staging/prod) to forward non-fatal errors to Crashlytics.
  static void Function(Object error, StackTrace? stack)? errorSink;

  static void d(String message) => _logger.d(message);
  static void w(String message) => _logger.w(message);

  static void e(Object error, [StackTrace? stack]) {
    _logger.e('error', error: error, stackTrace: stack);
    errorSink?.call(error, stack);
  }
}
```

`lib/core/utils/validators.dart`:

```dart
/// Return a translation key when invalid, null when valid.
/// Security rules re-validate everything server-side.
abstract final class Validators {
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String? v) =>
      v != null && _email.hasMatch(v.trim()) ? null : 'err_invalid_email';

  static String? password(String? v) =>
      v != null && v.length >= 8 ? null : 'err_weak_password';
}
```

`lib/core/utils/formatters.dart`:

```dart
import 'package:get/get.dart';
import 'package:intl/intl.dart';

abstract final class Formatters {
  static String time(DateTime t) => DateFormat.jm(Get.locale?.languageCode).format(t);

  static String countdown(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
  }
}
```

### 4.4 Theme

```dart
// lib/core/theme/app_colors.dart
import 'package:flutter/material.dart';

abstract final class AppColors {
  static const seed = Color(0xFF0F6E56); // deep emerald
}

// lib/core/theme/app_text_styles.dart
import 'package:flutter/material.dart';

abstract final class AppTextStyles {
  static const quranArabic = TextStyle(fontFamily: 'Amiri', fontSize: 26, height: 2);
  static const urdu = TextStyle(fontFamily: 'NotoNastaliqUrdu', height: 2.2);
}

// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:quran_pro/core/theme/app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) => ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.seed, brightness: brightness),
        fontFamilyFallback: const ['NotoNastaliqUrdu', 'Amiri'],
      );
}
```

### 4.5 Localization (en, ur, ar) with RTL

`lib/core/localization/app_translations.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:quran_pro/core/localization/ar.dart';
import 'package:quran_pro/core/localization/en.dart';
import 'package:quran_pro/core/localization/ur.dart';

final class AppTranslations extends Translations {
  static const fallback = Locale('en', 'US');
  static const supported = [Locale('en', 'US'), Locale('ur', 'PK'), Locale('ar', 'SA')];

  static Locale resolve(String? languageCode) =>
      supported.firstWhere((l) => l.languageCode == languageCode, orElse: () => fallback);

  @override
  Map<String, Map<String, String>> get keys => const {'en_US': en, 'ur_PK': ur, 'ar_SA': ar};
}
```

`lib/core/localization/en.dart`:

```dart
const Map<String, String> en = {
  'auth_title': 'Welcome',
  'email': 'Email',
  'password': 'Password',
  'toggle_password': 'Show or hide password',
  'sign_in': 'Sign in',
  'sign_up': 'Create account',
  'no_account': 'New here? Create an account',
  'have_account': 'Already have an account? Sign in',
  'forgot_password': 'Forgot password?',
  'reset_email_sent': 'Password reset email sent.',
  'continue_google': 'Continue with Google',
  'continue_apple': 'Continue with Apple',
  'continue_guest': 'Continue as guest',
  'home_greeting': 'Assalamu alaikum, @name',
  'home_greeting_guest': 'Assalamu alaikum',
  'prayer_times': 'Prayer times',
  'next_prayer': 'Next: @prayer at @time',
  'prayer_fajr': 'Fajr',
  'prayer_sunrise': 'Sunrise',
  'prayer_dhuhr': 'Dhuhr',
  'prayer_asr': 'Asr',
  'prayer_maghrib': 'Maghrib',
  'prayer_isha': 'Isha',
  'prayer_alert_body': "It's time for @prayer",
  'location_rationale':
      'Prayer times are calculated on your device from your approximate location. It is never uploaded.',
  'allow_location': 'Allow location',
  'open_app_settings': 'Open settings',
  'open_location_settings': 'Turn on location',
  'retry': 'Try again',
  'offline_banner': "You're offline. Showing saved data.",
  'channel_prayer': 'Prayer times (Azan)',
  'channel_general': 'Reminders and announcements',
  'err_invalid_email': 'Enter a valid email address.',
  'err_weak_password': 'Use at least 8 characters.',
  'err_invalid_credential': 'Email or password is incorrect.',
  'err_email_in_use': 'An account with this email already exists.',
  'err_too_many_requests': 'Too many attempts. Try again later.',
  'err_network': 'No connection. Check your internet and try again.',
  'err_permission': "You don't have access to this.",
  'err_not_found': 'Not found.',
  'err_google_failed': 'Google sign-in failed. Try again.',
  'err_invalid_location': "Couldn't calculate prayer times for this location.",
  'err_unknown': 'Something went wrong. Try again.',
};
```

`lib/core/localization/ur.dart`:

```dart
const Map<String, String> ur = {
  'auth_title': 'خوش آمدید',
  'email': 'ای میل',
  'password': 'پاس ورڈ',
  'toggle_password': 'پاس ورڈ دکھائیں یا چھپائیں',
  'sign_in': 'سائن ان کریں',
  'sign_up': 'اکاؤنٹ بنائیں',
  'no_account': 'نئے ہیں؟ اکاؤنٹ بنائیں',
  'have_account': 'پہلے سے اکاؤنٹ ہے؟ سائن ان کریں',
  'forgot_password': 'پاس ورڈ بھول گئے؟',
  'reset_email_sent': 'پاس ورڈ ری سیٹ ای میل بھیج دی گئی ہے۔',
  'continue_google': 'گوگل کے ساتھ جاری رکھیں',
  'continue_apple': 'ایپل کے ساتھ جاری رکھیں',
  'continue_guest': 'بطور مہمان جاری رکھیں',
  'home_greeting': 'السلام علیکم، @name',
  'home_greeting_guest': 'السلام علیکم',
  'prayer_times': 'نماز کے اوقات',
  'next_prayer': 'اگلی نماز: @prayer، @time',
  'prayer_fajr': 'فجر',
  'prayer_sunrise': 'طلوعِ آفتاب',
  'prayer_dhuhr': 'ظہر',
  'prayer_asr': 'عصر',
  'prayer_maghrib': 'مغرب',
  'prayer_isha': 'عشاء',
  'prayer_alert_body': '@prayer کا وقت ہو گیا ہے',
  'location_rationale':
      'نماز کے اوقات آپ کے تقریبی مقام سے آپ کے آلے پر ہی معلوم کیے جاتے ہیں۔ یہ کبھی اپ لوڈ نہیں ہوتا۔',
  'allow_location': 'مقام کی اجازت دیں',
  'open_app_settings': 'سیٹنگز کھولیں',
  'open_location_settings': 'لوکیشن آن کریں',
  'retry': 'دوبارہ کوشش کریں',
  'offline_banner': 'آپ آف لائن ہیں۔ محفوظ شدہ ڈیٹا دکھایا جا رہا ہے۔',
  'channel_prayer': 'نماز کے اوقات (اذان)',
  'channel_general': 'یاد دہانیاں اور اعلانات',
  'err_invalid_email': 'درست ای میل درج کریں۔',
  'err_weak_password': 'کم از کم 8 حروف استعمال کریں۔',
  'err_invalid_credential': 'ای میل یا پاس ورڈ غلط ہے۔',
  'err_email_in_use': 'اس ای میل سے اکاؤنٹ پہلے سے موجود ہے۔',
  'err_too_many_requests': 'بہت زیادہ کوششیں۔ کچھ دیر بعد کوشش کریں۔',
  'err_network': 'کنکشن نہیں ہے۔ انٹرنیٹ چیک کر کے دوبارہ کوشش کریں۔',
  'err_permission': 'آپ کو اس تک رسائی نہیں ہے۔',
  'err_not_found': 'نہیں ملا۔',
  'err_google_failed': 'گوگل سائن ان ناکام ہو گیا۔ دوبارہ کوشش کریں۔',
  'err_invalid_location': 'اس مقام کے لیے نماز کے اوقات معلوم نہیں ہو سکے۔',
  'err_unknown': 'کچھ غلط ہو گیا۔ دوبارہ کوشش کریں۔',
};
```

`lib/core/localization/ar.dart`:

```dart
const Map<String, String> ar = {
  'auth_title': 'مرحبًا بك',
  'email': 'البريد الإلكتروني',
  'password': 'كلمة المرور',
  'toggle_password': 'إظهار كلمة المرور أو إخفاؤها',
  'sign_in': 'تسجيل الدخول',
  'sign_up': 'إنشاء حساب',
  'no_account': 'جديد هنا؟ أنشئ حسابًا',
  'have_account': 'لديك حساب؟ سجّل الدخول',
  'forgot_password': 'نسيت كلمة المرور؟',
  'reset_email_sent': 'تم إرسال رسالة إعادة تعيين كلمة المرور.',
  'continue_google': 'المتابعة باستخدام Google',
  'continue_apple': 'المتابعة باستخدام Apple',
  'continue_guest': 'المتابعة كضيف',
  'home_greeting': 'السلام عليكم، @name',
  'home_greeting_guest': 'السلام عليكم',
  'prayer_times': 'مواقيت الصلاة',
  'next_prayer': 'الصلاة القادمة: @prayer، @time',
  'prayer_fajr': 'الفجر',
  'prayer_sunrise': 'الشروق',
  'prayer_dhuhr': 'الظهر',
  'prayer_asr': 'العصر',
  'prayer_maghrib': 'المغرب',
  'prayer_isha': 'العشاء',
  'prayer_alert_body': 'حان الآن موعد صلاة @prayer',
  'location_rationale': 'تُحسب مواقيت الصلاة على جهازك بناءً على موقعك التقريبي، ولا يُرفع أبدًا.',
  'allow_location': 'السماح بالوصول إلى الموقع',
  'open_app_settings': 'فتح الإعدادات',
  'open_location_settings': 'تشغيل الموقع',
  'retry': 'حاول مرة أخرى',
  'offline_banner': 'أنت غير متصل. يتم عرض البيانات المحفوظة.',
  'channel_prayer': 'مواقيت الصلاة (الأذان)',
  'channel_general': 'التذكيرات والإعلانات',
  'err_invalid_email': 'أدخل بريدًا إلكترونيًا صالحًا.',
  'err_weak_password': 'استخدم 8 أحرف على الأقل.',
  'err_invalid_credential': 'البريد الإلكتروني أو كلمة المرور غير صحيحة.',
  'err_email_in_use': 'يوجد حساب بهذا البريد الإلكتروني بالفعل.',
  'err_too_many_requests': 'محاولات كثيرة. حاول لاحقًا.',
  'err_network': 'لا يوجد اتصال. تحقّق من الإنترنت وحاول مجددًا.',
  'err_permission': 'ليس لديك صلاحية الوصول إلى هذا.',
  'err_not_found': 'غير موجود.',
  'err_google_failed': 'فشل تسجيل الدخول باستخدام Google. حاول مرة أخرى.',
  'err_invalid_location': 'تعذّر حساب مواقيت الصلاة لهذا الموقع.',
  'err_unknown': 'حدث خطأ ما. حاول مرة أخرى.',
};
```

> A native speaker must review the Urdu and Arabic strings before release.

RTL rules:

- `GlobalMaterialLocalizations.delegates` together with the `ar` and `ur` locales flips `Directionality` automatically.
- In layouts, use `EdgeInsetsDirectional`, `AlignmentDirectional` and `start`/`end`. Never use `left`/`right`.
- A test enforces key parity across the three languages (Step 6.5).

### 4.6 Services (GetxService)

`lib/core/network/connectivity_service.dart`:

```dart
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

final class ConnectivityService extends GetxService {
  ConnectivityService([Connectivity? connectivity]) : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;
  final _online = true.obs;
  StreamSubscription<List<ConnectivityResult>>? _sub;

  /// A network interface is up. Not proof of internet access — use as a UI hint only.
  bool get isOnline => _online.value;

  @override
  void onInit() {
    super.onInit();
    _sub = _connectivity.onConnectivityChanged.listen(_update);
    unawaited(_connectivity.checkConnectivity().then(_update));
  }

  void _update(List<ConnectivityResult> results) =>
      _online.value = results.any((r) => r != ConnectivityResult.none);

  @override
  void onClose() {
    unawaited(_sub?.cancel());
    super.onClose();
  }
}
```

`lib/core/services/settings_service.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:quran_pro/core/localization/app_translations.dart';
import 'package:quran_pro/data/models/prayer_settings.dart';
import 'package:quran_pro/data/models/user_location.dart';

/// Device preferences (not user-scoped, not sensitive). Secrets never go here — see 4.7.
final class SettingsService extends GetxService {
  SettingsService(this._box);

  final GetStorage _box;
  final _prayerInputs = 0.obs;

  static const _kLang = 'lang';
  static const _kTheme = 'themeMode';
  static const _kOnboarded = 'onboarded';
  static const _kPrayer = 'prayerSettings';
  static const _kAlerts = 'prayerAlerts';
  static const _kLocation = 'lastLocation';

  Locale get locale =>
      AppTranslations.resolve(_box.read<String>(_kLang) ?? Get.deviceLocale?.languageCode);
  ThemeMode get themeMode =>
      ThemeMode.values.asNameMap()[_box.read<String>(_kTheme)] ?? ThemeMode.system;
  bool get onboardingDone => _box.read<bool>(_kOnboarded) ?? false;
  bool get prayerAlertsOn => _box.read<bool>(_kAlerts) ?? true;

  PrayerSettings get prayerSettings {
    final json = _box.read<Map<String, dynamic>>(_kPrayer);
    return json == null ? const PrayerSettings() : PrayerSettings.fromJson(json);
  }

  UserLocation? get lastLocation {
    final json = _box.read<Map<String, dynamic>>(_kLocation);
    return json == null ? null : UserLocation.fromJson(json);
  }

  /// Emits whenever an input to prayer-time calculation changes.
  Stream<int> get prayerInputsChanged => _prayerInputs.stream;

  Future<void> setLanguage(String code) async {
    await _box.write(_kLang, code);
    await Get.updateLocale(locale);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _box.write(_kTheme, mode.name);
    Get.changeThemeMode(mode);
  }

  Future<void> completeOnboarding() => _box.write(_kOnboarded, true);
  Future<void> setPrayerSettings(PrayerSettings s) => _savePrayerInput(_kPrayer, s.toJson());
  Future<void> setPrayerAlerts({required bool on}) => _savePrayerInput(_kAlerts, on);
  Future<void> setLastLocation(UserLocation l) => _savePrayerInput(_kLocation, l.toJson());

  Future<void> _savePrayerInput(String key, Object value) async {
    await _box.write(key, value);
    _prayerInputs.value++;
  }
}
```

`lib/core/services/location_service.dart`:

```dart
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:quran_pro/core/utils/app_log.dart';
import 'package:quran_pro/data/models/user_location.dart';

enum LocationAccess { granted, denied, permanentlyDenied, serviceDisabled }

final class LocationService extends GetxService {
  Future<LocationAccess> status() => _resolve(request: false);

  /// Call only after the rationale UI has been shown.
  Future<LocationAccess> request() => _resolve(request: true);

  Future<LocationAccess> _resolve({required bool request}) async {
    if (!await Geolocator.isLocationServiceEnabled()) return LocationAccess.serviceDisabled;
    var permission = await Geolocator.checkPermission();
    if (request && permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return switch (permission) {
      LocationPermission.always || LocationPermission.whileInUse => LocationAccess.granted,
      LocationPermission.deniedForever => LocationAccess.permanentlyDenied,
      _ => LocationAccess.denied,
    };
  }

  /// City-level fix: enough for prayer times, kinder to battery and privacy.
  Future<UserLocation?> current() async {
    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return UserLocation.rounded(p.latitude, p.longitude);
    } on Exception catch (e, s) {
      AppLog.e(e, s);
      return null;
    }
  }

  Future<void> openAppSettings() async => Geolocator.openAppSettings();
  Future<void> openLocationSettings() async => Geolocator.openLocationSettings();
}
```

`lib/core/services/audio_service.dart`:

```dart
import 'dart:async';

import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';

final class AudioService extends GetxService {
  final _player = AudioPlayer();
  final _playing = false.obs;
  StreamSubscription<PlayerState>? _sub;

  bool get isPlaying => _playing.value;

  @override
  void onInit() {
    super.onInit();
    _sub = _player.playerStateStream.listen(
      (s) => _playing.value = s.playing && s.processingState != ProcessingState.completed,
    );
  }

  Future<void> playAsset(String path) async {
    await _player.setAsset(path);
    unawaited(_player.play()); // completes when playback ends
  }

  Future<void> stop() => _player.stop();

  @override
  void onClose() {
    unawaited(_sub?.cancel());
    unawaited(_player.dispose());
    super.onClose();
  }
}
```

`AuthService`, `NotificationService` and `PrayerScheduleService` are in Steps 6 and 7, next to the features that drive them.

### 4.7 Sensitive values

- Firebase Auth already keeps its tokens in the Keychain or EncryptedSharedPreferences. **Never copy them out.**
- Any other secret the app receives, such as a third-party OAuth token, goes in `data/datasources/local/secure_storage_local_ds.dart`. It wraps `const FlutterSecureStorage()` with `read`, `write` and `delete`.
- Secrets never go in `GetStorage` or `SharedPreferences`. Nothing in this guide needs one yet, so the file is created only when the first such value appears.

### 4.8 Shared widgets

```dart
// lib/core/widgets/error_retry.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

final class ErrorRetry extends StatelessWidget {
  const ErrorRetry({required this.messageKey, required this.onRetry, super.key});

  final String messageKey;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsetsDirectional.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(messageKey.tr, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onRetry, child: Text('retry'.tr)),
            ],
          ),
        ),
      );
}

// lib/core/widgets/offline_banner.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_pro/core/network/connectivity_service.dart';

final class OfflineBanner extends GetView<ConnectivityService> {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) => Obx(
        () => controller.isOnline
            ? const SizedBox.shrink()
            : Material(
                color: Theme.of(context).colorScheme.errorContainer,
                child: SafeArea(
                  bottom: false,
                  child: SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.all(8),
                      child: Semantics(
                        liveRegion: true,
                        child: Text('offline_banner'.tr, textAlign: TextAlign.center),
                      ),
                    ),
                  ),
                ),
              ),
      );
}
```

**Files:** `core/errors/*`, `core/utils/*`, `core/theme/*`, `core/localization/*`, `core/network/connectivity_service.dart`, `core/services/{settings,location,audio}_service.dart`, `core/widgets/*`

**Checks:**
- **No logic in views:** widgets only read getters and call methods ✅
- **Disposal:** `ConnectivityService` and `AudioService` cancel their subscriptions and dispose the player in `onClose` ✅
- **Firebase imports:** none in `core/` ✅
- **Secrets:** none, and the secure-storage rule is documented ✅

---

## 5. Routing, middleware, `InitialBinding`, session

`lib/app/routes/app_routes.dart`. Add a constant only once its page exists:

```dart
abstract final class AppRoutes {
  static const onboarding = '/onboarding';
  static const auth = '/auth';
  static const home = '/home';
  static const prayerTimes = '/prayer-times';
}
```

`lib/app/middlewares/auth_middleware.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:quran_pro/app/routes/app_routes.dart';
import 'package:quran_pro/core/services/auth_service.dart';
import 'package:quran_pro/core/services/settings_service.dart';

final class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    if (!Get.find<SettingsService>().onboardingDone) {
      return const RouteSettings(name: AppRoutes.onboarding);
    }
    if (!Get.find<AuthService>().isSignedIn) return const RouteSettings(name: AppRoutes.auth);
    return null;
  }
}
```

`lib/app/routes/app_pages.dart`:

```dart
import 'package:get/get.dart';
import 'package:quran_pro/app/middlewares/auth_middleware.dart';
import 'package:quran_pro/app/routes/app_routes.dart';
import 'package:quran_pro/features/auth/bindings/auth_binding.dart';
import 'package:quran_pro/features/auth/views/auth_view.dart';
import 'package:quran_pro/features/home/bindings/home_binding.dart';
import 'package:quran_pro/features/home/views/home_view.dart';
import 'package:quran_pro/features/onboarding/bindings/onboarding_binding.dart';
import 'package:quran_pro/features/onboarding/views/onboarding_view.dart';
import 'package:quran_pro/features/prayer_times/bindings/prayer_times_binding.dart';
import 'package:quran_pro/features/prayer_times/views/prayer_times_view.dart';

abstract final class AppPages {
  static const initial = AppRoutes.home; // AuthMiddleware redirects as needed

  static final routes = <GetPage<dynamic>>[
    GetPage(name: AppRoutes.onboarding, page: () => const OnboardingView(), binding: OnboardingBinding()),
    GetPage(name: AppRoutes.auth, page: () => const AuthView(), binding: AuthBinding()),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeView(),
      binding: HomeBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.prayerTimes,
      page: () => const PrayerTimesView(),
      binding: PrayerTimesBinding(),
      middlewares: [AuthMiddleware()],
    ),
  ];
}
```

Navigation uses named routes only. Arguments are typed models: `Get.toNamed(AppRoutes.lesson, arguments: LessonArgs(id: id))`, and the receiving ViewModel reads `Get.arguments as LessonArgs` in `onInit`.

`lib/app/bindings/initial_binding.dart`:

```dart
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:quran_pro/app/session/session_controller.dart';
import 'package:quran_pro/core/network/connectivity_service.dart';
import 'package:quran_pro/core/services/audio_service.dart';
import 'package:quran_pro/core/services/auth_service.dart';
import 'package:quran_pro/core/services/location_service.dart';
import 'package:quran_pro/core/services/notification_service.dart';
import 'package:quran_pro/core/services/prayer_schedule_service.dart';
import 'package:quran_pro/core/services/settings_service.dart';
import 'package:quran_pro/data/datasources/local/prayer_calc_local_ds.dart';
import 'package:quran_pro/data/datasources/remote/auth_remote_ds.dart';
import 'package:quran_pro/data/repositories/auth_repository_impl.dart';
import 'package:quran_pro/data/repositories/prayer_times_repository_impl.dart';
import 'package:quran_pro/domain/repositories/auth_repository.dart';
import 'package:quran_pro/domain/repositories/prayer_times_repository.dart';

/// Registered once from bootstrap(), before runApp. Feature ViewModels belong in feature bindings.
final class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Repositories: stateless, created on first use.
    Get
      ..lazyPut<AuthRepository>(() => AuthRepositoryImpl(AuthRemoteDataSource()), fenix: true)
      ..lazyPut<PrayerTimesRepository>(
        () => const PrayerTimesRepositoryImpl(PrayerCalcLocalDataSource()),
        fenix: true,
      )
      // App-wide state: permanent.
      ..put(SettingsService(GetStorage()), permanent: true)
      ..put(ConnectivityService(), permanent: true)
      ..put(AuthService(Get.find()), permanent: true)
      // Other services. SmartManagement never disposes a GetxService.
      ..lazyPut(LocationService.new, fenix: true)
      ..lazyPut(AudioService.new, fenix: true)
      ..put(NotificationService())
      ..put(PrayerScheduleService(Get.find(), Get.find(), Get.find()))
      ..put(SessionController(Get.find()));
  }
}
```

`lib/app/session/session_controller.dart` is the single place that reacts to sign-in, sign-out and account switches:

```dart
import 'dart:async';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:quran_pro/app/routes/app_routes.dart';
import 'package:quran_pro/core/services/auth_service.dart';
import 'package:quran_pro/data/models/app_user.dart';

final class SessionController extends GetxService {
  SessionController(this._auth);

  /// Anything user-specific cached on device goes in this box; it is erased on session end.
  static const userCacheBox = 'user_cache';

  final AuthService _auth;
  StreamSubscription<AppUser?>? _sub;
  String? _uid;

  @override
  void onInit() {
    super.onInit();
    _uid = _auth.user?.uid;
    _sub = _auth.userChanges.listen(_onUserChanged);
  }

  Future<void> _onUserChanged(AppUser? user) async {
    if (user?.uid == _uid) return; // guest upgraded in place keeps its uid: same session
    final sessionEnded = _uid != null;
    _uid = user?.uid;
    if (sessionEnded) await GetStorage(userCacheBox).erase();
    // offAllNamed removes every route; GetX then calls Get.delete on each route-bound
    // ViewModel, so no user-scoped controller or its data survives into the next session.
    unawaited(Get.offAllNamed<void>(user == null ? AppRoutes.auth : AppRoutes.home));
  }

  @override
  void onClose() {
    unawaited(_sub?.cancel());
    super.onClose();
  }
}
```

`lib/app/app.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:quran_pro/app/routes/app_pages.dart';
import 'package:quran_pro/core/localization/app_translations.dart';
import 'package:quran_pro/core/services/settings_service.dart';
import 'package:quran_pro/core/theme/app_theme.dart';
import 'package:quran_pro/core/widgets/offline_banner.dart';

final class App extends GetView<SettingsService> {
  const App({super.key});

  @override
  Widget build(BuildContext context) => GetMaterialApp(
        title: 'Quran Pro',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: controller.themeMode, // changed at runtime via Get.changeThemeMode
        translations: AppTranslations(),
        locale: controller.locale, // changed at runtime via Get.updateLocale
        fallbackLocale: AppTranslations.fallback,
        supportedLocales: AppTranslations.supported,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        initialRoute: AppPages.initial,
        getPages: AppPages.routes,
        builder: (context, child) => Column(
          children: [const OfflineBanner(), Expanded(child: child!)],
        ),
      );
}
```

**Onboarding (minimal).** `OnboardingViewModel(SettingsService, NotificationService)` exposes two actions:

- `enableNotifications()` calls `NotificationService.requestPermission()`. It runs **after** a rationale page explains the azan alerts.
- `finish()` calls `completeOnboarding()` and then `Get.offAllNamed(AppRoutes.home)`. `AuthMiddleware` takes it from there.

`OnboardingBinding` registers it with `lazyPut(..., fenix: true)`. The view is a `PageView` with three pages and has no logic.

**Files:** `app/routes/*`, `app/middlewares/auth_middleware.dart`, `app/bindings/initial_binding.dart`, `app/session/session_controller.dart`, `app/app.dart`, `features/onboarding/*`

**Checks:**
- **No logic in views:** `App` only passes `SettingsService` values through ✅
- **Disposal:** `SessionController` cancels its subscription ✅
- **Firebase imports:** `InitialBinding` imports datasource *classes*, not Firebase packages ✅
- **Secrets:** none ✅

---

## 6. Auth feature — the reference MVVM + GetX implementation

The flow runs: View → `AuthViewModel` → `AuthRepository` (contract) → `AuthRepositoryImpl` → `AuthRemoteDataSource` → Firebase. Copy this shape for every feature.

### 6.1 Model and contract

```dart
// lib/data/models/app_user.dart
import 'package:equatable/equatable.dart';

final class AppUser extends Equatable {
  const AppUser({required this.uid, required this.isGuest, this.email, this.displayName});

  final String uid;
  final bool isGuest;
  final String? email;
  final String? displayName;

  @override
  List<Object?> get props => [uid, isGuest, email, displayName];
}

// lib/domain/repositories/auth_repository.dart
import 'package:quran_pro/core/errors/result.dart';
import 'package:quran_pro/data/models/app_user.dart';

abstract interface class AuthRepository {
  Stream<AppUser?> authStateChanges();
  Future<Result<AppUser>> signInAnonymously();
  Future<Result<AppUser>> signInWithEmail(String email, String password);
  Future<Result<AppUser>> signUpWithEmail(String email, String password);
  Future<Result<AppUser>> signInWithGoogle();
  Future<Result<AppUser>> signInWithApple();
  Future<Result<void>> sendPasswordReset(String email);
  Future<Result<void>> signOut();
}
```

### 6.2 Datasource (the only Firebase-aware layer)

`lib/data/datasources/remote/firebase_guard.dart`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:quran_pro/core/errors/app_exception.dart';

/// Converts SDK exceptions into backend-neutral AppExceptions. Wrap every remote call.
Future<T> guard<T>(Future<T> Function() call) async {
  try {
    return await call();
  } on FirebaseException catch (e) {
    // FirebaseAuthException is a FirebaseException subtype.
    throw AppException(e.code);
  } on GoogleSignInException catch (e) {
    throw AppException(
      e.code == GoogleSignInExceptionCode.canceled ? AppException.cancelled : 'google-sign-in-failed',
    );
  }
}
```

`lib/data/datasources/remote/auth_remote_ds.dart`:

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:quran_pro/core/config/env.dart';
import 'package:quran_pro/data/datasources/remote/firebase_guard.dart';
import 'package:quran_pro/data/models/app_user.dart';

final class AuthRemoteDataSource {
  AuthRemoteDataSource({FirebaseAuth? auth, GoogleSignIn? google})
      : _auth = auth ?? FirebaseAuth.instance,
        _google = google ?? GoogleSignIn.instance;

  final FirebaseAuth _auth;
  final GoogleSignIn _google;
  Future<void>? _googleReady;

  /// userChanges (not authStateChanges) so a guest → linked upgrade is emitted too.
  Stream<AppUser?> authStateChanges() =>
      _auth.userChanges().map((u) => u == null ? null : _toModel(u));

  Future<AppUser> signInAnonymously() =>
      guard(() async => _toModel((await _auth.signInAnonymously()).user!));

  Future<AppUser> signInWithEmail(String email, String password) => guard(() async {
        final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
        return _toModel(cred.user!);
      });

  /// A guest is upgraded in place (same uid, progress kept); otherwise a new account is created.
  Future<AppUser> signUpWithEmail(String email, String password) => guard(() async {
        final guest = _currentGuest;
        final cred = guest != null
            ? await guest.linkWithCredential(
                EmailAuthProvider.credential(email: email, password: password),
              )
            : await _auth.createUserWithEmailAndPassword(email: email, password: password);
        await cred.user!.sendEmailVerification();
        return _toModel(cred.user!);
      });

  Future<AppUser> signInWithGoogle() => guard(() async {
        await (_googleReady ??= _google.initialize(
          serverClientId: Env.googleServerClientId.isEmpty ? null : Env.googleServerClientId,
        ));
        final account = await _google.authenticate();
        final credential = GoogleAuthProvider.credential(idToken: account.authentication.idToken);
        return _toModel(await _upgradeGuestOr(
          link: (guest) => guest.linkWithCredential(credential),
          signIn: () => _auth.signInWithCredential(credential),
        ));
      });

  Future<AppUser> signInWithApple() => guard(() async {
        final provider = AppleAuthProvider()..addScope('email');
        return _toModel(await _upgradeGuestOr(
          link: (guest) => guest.linkWithProvider(provider),
          signIn: () => _auth.signInWithProvider(provider),
        ));
      });

  Future<void> sendPasswordReset(String email) =>
      guard(() => _auth.sendPasswordResetEmail(email: email));

  Future<void> signOut() => guard(() async {
        await _auth.signOut();
        if (_googleReady != null) await _google.signOut(); // next Google sign-in shows the picker
      });

  User? get _currentGuest {
    final u = _auth.currentUser;
    return u != null && u.isAnonymous ? u : null;
  }

  Future<User> _upgradeGuestOr({
    required Future<UserCredential> Function(User guest) link,
    required Future<UserCredential> Function() signIn,
  }) async {
    final guest = _currentGuest;
    if (guest == null) return (await signIn()).user!;
    try {
      return (await link(guest)).user!;
    } on FirebaseAuthException catch (e) {
      if (e.code != 'credential-already-in-use') rethrow;
      // The account already exists: switch to it. Guest data stays with the abandoned anonymous uid.
      final existing = e.credential;
      return existing != null
          ? (await _auth.signInWithCredential(existing)).user!
          : (await signIn()).user!;
    }
  }

  AppUser _toModel(User u) =>
      AppUser(uid: u.uid, isGuest: u.isAnonymous, email: u.email, displayName: u.displayName);
}
```

### 6.3 Repository

```dart
// lib/data/repositories/run_catching.dart
import 'package:quran_pro/core/errors/app_exception.dart';
import 'package:quran_pro/core/errors/failure.dart';
import 'package:quran_pro/core/errors/result.dart';
import 'package:quran_pro/core/utils/app_log.dart';

Future<Result<T>> runCatching<T>(Future<T> Function() call) async {
  try {
    return Ok(await call());
  } on AppException catch (e) {
    return Err(Failure(e.code));
  } on Object catch (e, s) {
    AppLog.e(e, s); // unexpected: goes to Crashlytics in staging/prod
    return const Err(Failure(AppException.unknown));
  }
}

// lib/data/repositories/auth_repository_impl.dart
import 'package:quran_pro/core/errors/result.dart';
import 'package:quran_pro/data/datasources/remote/auth_remote_ds.dart';
import 'package:quran_pro/data/models/app_user.dart';
import 'package:quran_pro/data/repositories/run_catching.dart';
import 'package:quran_pro/domain/repositories/auth_repository.dart';

final class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remote);

  final AuthRemoteDataSource _remote;

  @override
  Stream<AppUser?> authStateChanges() => _remote.authStateChanges();

  @override
  Future<Result<AppUser>> signInAnonymously() => runCatching(_remote.signInAnonymously);

  @override
  Future<Result<AppUser>> signInWithEmail(String email, String password) =>
      runCatching(() => _remote.signInWithEmail(email, password));

  @override
  Future<Result<AppUser>> signUpWithEmail(String email, String password) =>
      runCatching(() => _remote.signUpWithEmail(email, password));

  @override
  Future<Result<AppUser>> signInWithGoogle() => runCatching(_remote.signInWithGoogle);

  @override
  Future<Result<AppUser>> signInWithApple() => runCatching(_remote.signInWithApple);

  @override
  Future<Result<void>> sendPasswordReset(String email) =>
      runCatching(() => _remote.sendPasswordReset(email));

  @override
  Future<Result<void>> signOut() => runCatching(_remote.signOut);
}
```

### 6.4 `AuthService`, ViewModel, binding and view

`lib/core/services/auth_service.dart`:

```dart
import 'dart:async';

import 'package:get/get.dart';
import 'package:quran_pro/core/errors/result.dart';
import 'package:quran_pro/data/models/app_user.dart';
import 'package:quran_pro/domain/repositories/auth_repository.dart';

final class AuthService extends GetxService {
  AuthService(this._repo);

  final AuthRepository _repo;
  final _user = Rxn<AppUser>();
  final _ready = Completer<void>();
  StreamSubscription<AppUser?>? _sub;

  AppUser? get user => _user.value;
  bool get isSignedIn => _user.value != null;
  Stream<AppUser?> get userChanges => _user.stream;

  /// Completes once Firebase has restored the persisted session (or found none).
  Future<void> get ready => _ready.future;

  @override
  void onInit() {
    super.onInit();
    _sub = _repo.authStateChanges().listen((u) {
      _user.value = u; // Equatable: token refreshes with identical data do not re-emit
      if (!_ready.isCompleted) _ready.complete();
    });
  }

  Future<Result<void>> signOut() => _repo.signOut(); // SessionController handles the rest

  @override
  void onClose() {
    unawaited(_sub?.cancel());
    super.onClose();
  }
}
```

`lib/features/auth/viewmodels/auth_view_model.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:quran_pro/core/errors/result.dart';
import 'package:quran_pro/core/utils/validators.dart';
import 'package:quran_pro/core/utils/view_state.dart';
import 'package:quran_pro/domain/repositories/auth_repository.dart';

/// Navigation after sign-in is SessionController's job; this ViewModel only reports state.
final class AuthViewModel extends GetxController {
  AuthViewModel(this._auth);

  final AuthRepository _auth;

  final formKey = GlobalKey<FormState>();
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  final _state = Rx<ViewState<String>>(const Idle()); // Success carries an info message key
  final _signUp = false.obs;
  final _obscure = true.obs;

  ViewState<String> get state => _state.value;
  bool get isBusy => _state.value is Loading;
  bool get isSignUp => _signUp.value;
  bool get obscure => _obscure.value;
  bool get showApple => GetPlatform.isIOS;

  void toggleMode() => _signUp.toggle();
  void toggleObscure() => _obscure.toggle();

  Future<void> continueAsGuest() => _run(_auth.signInAnonymously);
  Future<void> signInWithGoogle() => _run(_auth.signInWithGoogle);
  Future<void> signInWithApple() => _run(_auth.signInWithApple);

  Future<void> submitEmail() async {
    if (isBusy || !(formKey.currentState?.validate() ?? false)) return;
    final email = emailCtrl.text.trim();
    final password = passwordCtrl.text;
    await _run(
      () => isSignUp ? _auth.signUpWithEmail(email, password) : _auth.signInWithEmail(email, password),
    );
  }

  Future<void> resetPassword() async {
    final invalid = Validators.email(emailCtrl.text);
    if (invalid != null) {
      _state.value = ViewError(invalid);
      return;
    }
    await _run(() => _auth.sendPasswordReset(emailCtrl.text.trim()), successKey: 'reset_email_sent');
  }

  Future<void> _run<T>(Future<Result<T>> Function() action, {String? successKey}) async {
    if (isBusy) return; // duplicate-tap guard
    _state.value = const Loading();
    final result = await action();
    if (isClosed) return; // route may be gone after a successful sign-in
    _state.value = switch (result) {
      Ok() => successKey == null ? const Idle() : Success(successKey),
      Err(:final failure) when failure.isCancelled => const Idle(),
      Err(:final failure) => ViewError(failure.messageKey),
    };
  }

  @override
  void onClose() {
    emailCtrl.dispose();
    passwordCtrl.dispose();
    super.onClose();
  }
}
```

`lib/features/auth/bindings/auth_binding.dart`:

```dart
import 'package:get/get.dart';
import 'package:quran_pro/features/auth/viewmodels/auth_view_model.dart';

final class AuthBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut(() => AuthViewModel(Get.find()), fenix: true);
}
```

`lib/features/auth/views/auth_view.dart`. Each `Obx` wraps only the widget that changes:

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_pro/core/utils/validators.dart';
import 'package:quran_pro/core/utils/view_state.dart';
import 'package:quran_pro/features/auth/viewmodels/auth_view_model.dart';

final class AuthView extends GetView<AuthViewModel> {
  const AuthView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsetsDirectional.all(24),
            child: AutofillGroup(
              child: Form(
                key: controller.formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('auth_title'.tr, style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: controller.emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      decoration: InputDecoration(labelText: 'email'.tr),
                      validator: (v) => Validators.email(v)?.tr,
                    ),
                    const SizedBox(height: 12),
                    Obx(
                      () => TextFormField(
                        controller: controller.passwordCtrl,
                        obscureText: controller.obscure,
                        autofillHints: const [AutofillHints.password],
                        decoration: InputDecoration(
                          labelText: 'password'.tr,
                          suffixIcon: IconButton(
                            tooltip: 'toggle_password'.tr,
                            onPressed: controller.toggleObscure,
                            icon: Icon(controller.obscure ? Icons.visibility : Icons.visibility_off),
                          ),
                        ),
                        validator: (v) => Validators.password(v)?.tr,
                      ),
                    ),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton(
                        onPressed: controller.resetPassword,
                        child: Text('forgot_password'.tr),
                      ),
                    ),
                    const _StatusText(),
                    const SizedBox(height: 12),
                    const _SubmitButton(),
                    TextButton(
                      onPressed: controller.toggleMode,
                      child: Obx(() => Text((controller.isSignUp ? 'have_account' : 'no_account').tr)),
                    ),
                    const Divider(height: 32),
                    const _ProviderButtons(),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

final class _StatusText extends GetView<AuthViewModel> {
  const _StatusText();

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        child: Obx(
          () => switch (controller.state) {
            ViewError(:final messageKey) => Text(
                messageKey.tr,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            Success(:final data) => Text(data.tr),
            _ => const SizedBox.shrink(),
          },
        ),
      );
}

final class _SubmitButton extends GetView<AuthViewModel> {
  const _SubmitButton();

  @override
  Widget build(BuildContext context) => Obx(
        () => FilledButton(
          key: const Key('auth_submit'),
          onPressed: controller.isBusy ? null : controller.submitEmail,
          child: controller.isBusy
              ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text((controller.isSignUp ? 'sign_up' : 'sign_in').tr),
        ),
      );
}

final class _ProviderButtons extends GetView<AuthViewModel> {
  const _ProviderButtons();

  @override
  Widget build(BuildContext context) => Obx(() {
        final busy = controller.isBusy;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            OutlinedButton(
              onPressed: busy ? null : controller.signInWithGoogle,
              child: Text('continue_google'.tr),
            ),
            if (controller.showApple)
              OutlinedButton(
                onPressed: busy ? null : controller.signInWithApple,
                child: Text('continue_apple'.tr),
              ),
            TextButton(
              onPressed: busy ? null : controller.continueAsGuest,
              child: Text('continue_guest'.tr),
            ),
          ],
        );
      });
}
```

> **App Store:** Guideline 4.8 requires Sign in with Apple whenever Google sign-in is offered on iOS, and that is why `showApple` exists. Guideline 5.1.1(v) requires **in-app account deletion**. Add it in Settings: `user.delete()` plus the "Delete User Data" extension (or a function) that removes `users/{uid}/**`.

### 6.5 Tests

`test/features/auth/auth_view_model_test.dart`:

```dart
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_pro/core/errors/failure.dart';
import 'package:quran_pro/core/errors/result.dart';
import 'package:quran_pro/core/utils/view_state.dart';
import 'package:quran_pro/data/models/app_user.dart';
import 'package:quran_pro/domain/repositories/auth_repository.dart';
import 'package:quran_pro/features/auth/viewmodels/auth_view_model.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  const guest = AppUser(uid: 'u1', isGuest: true);
  late _MockAuthRepository repo;
  late AuthViewModel vm;

  setUp(() {
    repo = _MockAuthRepository();
    vm = AuthViewModel(repo);
  });
  tearDown(() => vm.onClose());

  test('guest sign-in success returns to Idle', () async {
    when(() => repo.signInAnonymously()).thenAnswer((_) async => const Ok(guest));
    await vm.continueAsGuest();
    expect(vm.state, isA<Idle<String>>());
  });

  test('failure exposes a translation key', () async {
    when(() => repo.signInWithGoogle())
        .thenAnswer((_) async => const Err(Failure('network-request-failed')));
    await vm.signInWithGoogle();
    expect(
      vm.state,
      isA<ViewError<String>>().having((s) => s.messageKey, 'key', 'err_network'),
    );
  });

  test('cancelled Google sign-in shows no error', () async {
    when(() => repo.signInWithGoogle()).thenAnswer((_) async => const Err(Failure('cancelled')));
    await vm.signInWithGoogle();
    expect(vm.state, isA<Idle<String>>());
  });

  test('double tap sends one request', () async {
    final pending = Completer<Result<AppUser>>();
    when(() => repo.signInAnonymously()).thenAnswer((_) => pending.future);
    final first = vm.continueAsGuest();
    final second = vm.continueAsGuest();
    pending.complete(const Ok(guest));
    await Future.wait([first, second]);
    verify(() => repo.signInAnonymously()).called(1);
  });
}
```

`test/features/auth/auth_view_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_pro/core/localization/app_translations.dart';
import 'package:quran_pro/core/localization/en.dart';
import 'package:quran_pro/domain/repositories/auth_repository.dart';
import 'package:quran_pro/features/auth/viewmodels/auth_view_model.dart';
import 'package:quran_pro/features/auth/views/auth_view.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  tearDown(Get.reset);

  testWidgets('empty submit shows validation errors and never calls the repository', (tester) async {
    final repo = _MockAuthRepository();
    Get.put(AuthViewModel(repo));
    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: AppTranslations.fallback,
        home: const AuthView(),
      ),
    );

    await tester.tap(find.byKey(const Key('auth_submit')));
    await tester.pump();

    expect(find.text(en['err_invalid_email']!), findsOneWidget);
    expect(find.text(en['err_weak_password']!), findsOneWidget);
    verifyNever(() => repo.signInWithEmail(any(), any()));
  });
}
```

`test/core/translations_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_pro/core/localization/app_translations.dart';

void main() {
  test('every locale defines exactly the same keys', () {
    final all = AppTranslations().keys;
    final base = all['en_US']!.keys.toSet();
    for (final entry in all.entries) {
      expect(entry.value.keys.toSet(), base, reason: entry.key);
    }
  });
}
```

**Files:** `data/models/app_user.dart`, `domain/repositories/auth_repository.dart`, `data/datasources/remote/{firebase_guard,auth_remote_ds}.dart`, `data/repositories/{run_catching,auth_repository_impl}.dart`, `core/services/auth_service.dart`, `features/auth/**`, three test files

**Checks:**
- **No logic in views:** they read getters, call ViewModel methods and translate keys. Validators are pure functions owned by `core` ✅
- **Disposal:** `AuthViewModel` disposes both `TextEditingController`s, and `AuthService` cancels its subscription ✅
- **Firebase imports:** only `firebase_guard.dart` and `auth_remote_ds.dart` ✅
- **Secrets:** the Google server client ID comes from `Env`. It is a public identifier ✅

---

## 7. Home and Prayer Times

### 7.1 Models

```dart
// lib/data/models/prayer.dart
enum Prayer {
  fajr, sunrise, dhuhr, asr, maghrib, isha;

  static const obligatory = [fajr, dhuhr, asr, maghrib, isha];
  String get labelKey => 'prayer_$name';
}

// lib/data/models/day_prayer_times.dart
import 'package:equatable/equatable.dart';
import 'package:quran_pro/data/models/prayer.dart';

typedef NextPrayer = ({Prayer prayer, DateTime at});

final class DayPrayerTimes extends Equatable {
  const DayPrayerTimes({required this.date, required this.times});

  final DateTime date;
  final Map<Prayer, DateTime> times;

  /// First obligatory prayer after [now] on this day, or null once Isha has passed.
  NextPrayer? nextAfter(DateTime now) {
    for (final p in Prayer.obligatory) {
      final at = times[p]!;
      if (at.isAfter(now)) return (prayer: p, at: at);
    }
    return null;
  }

  @override
  List<Object?> get props => [date, times];
}

// lib/data/models/prayer_settings.dart
import 'package:equatable/equatable.dart';

final class PrayerSettings extends Equatable {
  const PrayerSettings({this.method = 'muslim_world_league', this.hanafiAsr = false});

  factory PrayerSettings.fromJson(Map<String, dynamic> json) => PrayerSettings(
        method: json['method'] as String? ?? 'muslim_world_league',
        hanafiAsr: json['hanafiAsr'] as bool? ?? false,
      );

  /// Name of an adhan `CalculationMethod` value, e.g. 'karachi', 'umm_al_qura'.
  final String method;
  final bool hanafiAsr;

  Map<String, dynamic> toJson() => {'method': method, 'hanafiAsr': hanafiAsr};
  PrayerSettings copyWith({String? method, bool? hanafiAsr}) =>
      PrayerSettings(method: method ?? this.method, hanafiAsr: hanafiAsr ?? this.hanafiAsr);

  @override
  List<Object> get props => [method, hanafiAsr];
}

// lib/data/models/user_location.dart
import 'package:equatable/equatable.dart';

final class UserLocation extends Equatable {
  const UserLocation(this.lat, this.lng);

  /// ~1 km precision: accurate enough for prayer times, avoids storing a precise home location.
  factory UserLocation.rounded(double lat, double lng) => UserLocation(_r(lat), _r(lng));

  factory UserLocation.fromJson(Map<String, dynamic> json) =>
      UserLocation((json['lat'] as num).toDouble(), (json['lng'] as num).toDouble());

  final double lat;
  final double lng;

  static double _r(double v) => (v * 100).roundToDouble() / 100;
  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng};

  @override
  List<Object> get props => [lat, lng];
}
```

### 7.2 Calculation (local, offline)

```dart
// lib/data/datasources/local/prayer_calc_local_ds.dart
import 'package:adhan/adhan.dart' as adhan;
import 'package:quran_pro/data/models/day_prayer_times.dart';
import 'package:quran_pro/data/models/prayer.dart';
import 'package:quran_pro/data/models/prayer_settings.dart';
import 'package:quran_pro/data/models/user_location.dart';

final class PrayerCalcLocalDataSource {
  const PrayerCalcLocalDataSource();

  /// Times are in the device's local time zone. Throws ArgumentError on bad input.
  DayPrayerTimes compute(DateTime day, UserLocation at, PrayerSettings s) {
    final params = adhan.CalculationMethod.values.byName(s.method).getParameters()
      ..madhab = s.hanafiAsr ? adhan.Madhab.hanafi : adhan.Madhab.shafi;
    final t = adhan.PrayerTimes(
      adhan.Coordinates(at.lat, at.lng, validate: true),
      adhan.DateComponents.from(day),
      params,
    );
    return DayPrayerTimes(
      date: DateTime(day.year, day.month, day.day),
      times: {
        Prayer.fajr: t.fajr,
        Prayer.sunrise: t.sunrise,
        Prayer.dhuhr: t.dhuhr,
        Prayer.asr: t.asr,
        Prayer.maghrib: t.maghrib,
        Prayer.isha: t.isha,
      },
    );
  }
}

// lib/domain/repositories/prayer_times_repository.dart
import 'package:quran_pro/core/errors/result.dart';
import 'package:quran_pro/data/models/day_prayer_times.dart';
import 'package:quran_pro/data/models/prayer_settings.dart';
import 'package:quran_pro/data/models/user_location.dart';

abstract interface class PrayerTimesRepository {
  Result<DayPrayerTimes> timesFor(DateTime day, UserLocation at, PrayerSettings settings);
}

// lib/data/repositories/prayer_times_repository_impl.dart
import 'package:quran_pro/core/errors/failure.dart';
import 'package:quran_pro/core/errors/result.dart';
import 'package:quran_pro/core/utils/app_log.dart';
import 'package:quran_pro/data/datasources/local/prayer_calc_local_ds.dart';
import 'package:quran_pro/data/models/day_prayer_times.dart';
import 'package:quran_pro/data/models/prayer_settings.dart';
import 'package:quran_pro/data/models/user_location.dart';
import 'package:quran_pro/domain/repositories/prayer_times_repository.dart';

final class PrayerTimesRepositoryImpl implements PrayerTimesRepository {
  const PrayerTimesRepositoryImpl(this._calc);

  final PrayerCalcLocalDataSource _calc;

  @override
  Result<DayPrayerTimes> timesFor(DateTime day, UserLocation at, PrayerSettings settings) {
    try {
      return Ok(_calc.compute(day, at, settings));
    } on ArgumentError catch (e, s) {
      AppLog.e(e, s);
      return const Err(Failure('invalid-location'));
    }
  }
}
```

> For locations above about 48° latitude, add `params.highLatitudeRule` (a user setting) before release.

### 7.3 Prayer Times ViewModel

`lib/features/prayer_times/viewmodels/prayer_times_view_model.dart`:

```dart
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:quran_pro/core/errors/result.dart';
import 'package:quran_pro/core/services/location_service.dart';
import 'package:quran_pro/core/services/settings_service.dart';
import 'package:quran_pro/core/utils/app_log.dart';
import 'package:quran_pro/core/utils/formatters.dart';
import 'package:quran_pro/core/utils/view_state.dart';
import 'package:quran_pro/data/models/day_prayer_times.dart';
import 'package:quran_pro/data/models/user_location.dart';
import 'package:quran_pro/domain/repositories/prayer_times_repository.dart';

final class PrayerTimesViewModel extends GetxController {
  PrayerTimesViewModel(this._prayers, this._location, this._settings);

  final PrayerTimesRepository _prayers;
  final LocationService _location;
  final SettingsService _settings;

  final _state = Rx<ViewState<DayPrayerTimes>>(const Idle());
  final _access = LocationAccess.granted.obs;
  final _next = Rxn<NextPrayer>();
  final _remaining = Duration.zero.obs;
  Timer? _ticker;
  StreamSubscription<int>? _inputsSub;
  AppLifecycleListener? _lifecycle;

  ViewState<DayPrayerTimes> get state => _state.value;
  NextPrayer? get next => _next.value;
  Duration get remaining => _remaining.value;

  String get nextLabel {
    final n = _next.value;
    return n == null
        ? ''
        : 'next_prayer'.trParams({'prayer': n.prayer.labelKey.tr, 'time': Formatters.time(n.at)});
  }

  String get permissionActionKey => switch (_access.value) {
        LocationAccess.permanentlyDenied => 'open_app_settings',
        LocationAccess.serviceDisabled => 'open_location_settings',
        _ => 'allow_location',
      };

  @override
  void onInit() {
    super.onInit();
    _inputsSub = _settings.prayerInputsChanged.listen((_) => _compute());
    // Returning from system settings, or after a long background: refresh.
    _lifecycle = AppLifecycleListener(onResume: () => unawaited(load()));
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    unawaited(load());
  }

  Future<void> load() async {
    if (_state.value is Loading) return;
    _state.value = const Loading();
    try {
      _access.value = await _location.status();
      if (_access.value == LocationAccess.granted) {
        final fresh = await _location.current();
        if (fresh != null && fresh != _settings.lastLocation) {
          await _settings.setLastLocation(fresh); // also triggers notification reschedule
        }
      }
    } on Object catch (e, s) {
      AppLog.e(e, s); // fall back to the cached location below
    }
    _compute();
  }

  Future<void> onPermissionAction() async {
    switch (_access.value) {
      case LocationAccess.permanentlyDenied:
        await _location.openAppSettings();
      case LocationAccess.serviceDisabled:
        await _location.openLocationSettings();
      case LocationAccess.denied || LocationAccess.granted:
        _access.value = await _location.request();
        await load();
    }
  }

  void _compute() {
    final loc = _settings.lastLocation;
    if (loc == null) {
      _next.value = null;
      _state.value = const Empty(); // view shows the location rationale
      return;
    }
    final now = DateTime.now();
    switch (_prayers.timesFor(now, loc, _settings.prayerSettings)) {
      case Err(:final failure):
        _state.value = ViewError(failure.messageKey);
      case Ok(:final value):
        _state.value = Success(value);
        _next.value = value.nextAfter(now) ?? _tomorrowFajr(loc, now);
        _tick();
    }
  }

  NextPrayer? _tomorrowFajr(UserLocation loc, DateTime now) => switch (_prayers.timesFor(
        DateTime(now.year, now.month, now.day + 1),
        loc,
        _settings.prayerSettings,
      )) {
        Ok(:final value) => value.nextAfter(now),
        Err() => null,
      };

  void _tick() {
    final next = _next.value;
    if (next == null) return;
    final left = next.at.difference(DateTime.now());
    if (left.isNegative) {
      _compute(); // prayer time reached: roll to the next one
      return;
    }
    _remaining.value = left;
  }

  @override
  void onClose() {
    _ticker?.cancel();
    unawaited(_inputsSub?.cancel());
    _lifecycle?.dispose();
    super.onClose();
  }
}
```

### 7.4 Notifications: local azan scheduling

`lib/core/services/notification_service.dart`:

```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:get/get.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

typedef PrayerAlert = ({int id, String title, String body, DateTime at});

final class NotificationService extends GetxService {
  // Channel sound is immutable once created on a device: bump the suffix to change it.
  static const _azanChannel = 'prayer_azan_v1';
  static const _generalChannel = 'general_v1';
  static const _prayerPayload = 'prayer';

  final _plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _initialized;

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  IOSFlutterLocalNotificationsPlugin? get _ios =>
      _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

  /// Idempotent. Call after the first frame so channel names are translated.
  Future<void> init() => _initialized ??= _init();

  Future<void> _init() async {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation((await FlutterTimezone.getLocalTimezone()).identifier));
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@drawable/ic_notification'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false, // asked later, after the rationale
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    await _android?.createNotificationChannel(
      AndroidNotificationChannel(
        _azanChannel,
        'channel_prayer'.tr,
        importance: Importance.max,
        sound: const RawResourceAndroidNotificationSound('azan'),
      ),
    );
    await _android?.createNotificationChannel(
      AndroidNotificationChannel(_generalChannel, 'channel_general'.tr),
    );
  }

  /// Show the rationale first. Returns false when denied: offer "Open settings".
  Future<bool> requestPermission() async {
    await init();
    if (GetPlatform.isAndroid) {
      final granted = await _android?.requestNotificationsPermission() ?? false;
      if (granted && !(await _android?.canScheduleExactNotifications() ?? true)) {
        await _android?.requestExactAlarmsPermission(); // opens the system screen
      }
      return granted;
    }
    return await _ios?.requestPermissions(alert: true, badge: true, sound: true) ?? false;
  }

  /// Replaces every pending prayer alert with [alerts]; other notifications are untouched.
  Future<void> replacePrayerAlerts(List<PrayerAlert> alerts) async {
    await init();
    for (final p in await _plugin.pendingNotificationRequests()) {
      if (p.payload == _prayerPayload) await _plugin.cancel(id: p.id);
    }
    final exact = await _android?.canScheduleExactNotifications() ?? true;
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _azanChannel,
        'channel_prayer'.tr,
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.alarm,
        sound: const RawResourceAndroidNotificationSound('azan'),
      ),
      iOS: const DarwinNotificationDetails(sound: 'azan.caf'),
    );
    for (final a in alerts) {
      await _plugin.zonedSchedule(
        id: a.id,
        title: a.title,
        body: a.body,
        scheduledDate: tz.TZDateTime.from(a.at, tz.local),
        notificationDetails: details,
        androidScheduleMode:
            exact ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexactAllowWhileIdle,
        payload: _prayerPayload,
      );
    }
  }
}
```

`lib/core/services/prayer_schedule_service.dart`:

```dart
import 'dart:async';

import 'package:get/get.dart';
import 'package:quran_pro/core/errors/result.dart';
import 'package:quran_pro/core/services/notification_service.dart';
import 'package:quran_pro/core/services/settings_service.dart';
import 'package:quran_pro/core/utils/app_log.dart';
import 'package:quran_pro/data/models/prayer.dart';
import 'package:quran_pro/domain/repositories/prayer_times_repository.dart';

/// Schedules azan alerts locally from adhan calculations, never from the server.
/// It reschedules on app start and whenever the location, method, madhab or alerts toggle changes.
final class PrayerScheduleService extends GetxService {
  PrayerScheduleService(this._prayers, this._notifications, this._settings);

  final PrayerTimesRepository _prayers;
  final NotificationService _notifications;
  final SettingsService _settings;
  StreamSubscription<int>? _sub;
  bool _running = false;
  bool _again = false;

  // iOS keeps at most 64 pending notifications: 5 × 12 = 60 leaves room for reminders.
  // shortcut: the window only advances when the app opens; add a background refresh
  // (workmanager / BGTaskScheduler) if users report missing alerts after ~12 idle days.
  int get _days => GetPlatform.isIOS ? 12 : 30;

  @override
  void onReady() {
    super.onReady(); // after the first frame: translations are loaded
    _sub = _settings.prayerInputsChanged.listen((_) => unawaited(reschedule()));
    unawaited(reschedule());
  }

  Future<void> reschedule() async {
    if (_running) {
      _again = true; // coalesce bursts of changes into one extra pass
      return;
    }
    _running = true;
    try {
      do {
        _again = false;
        await _notifications.replacePrayerAlerts(_buildAlerts());
      } while (_again);
    } on Object catch (e, s) {
      AppLog.e(e, s);
    } finally {
      _running = false;
    }
  }

  List<PrayerAlert> _buildAlerts() {
    final loc = _settings.lastLocation;
    if (loc == null || !_settings.prayerAlertsOn) return const [];
    final now = DateTime.now();
    return [
      for (var d = 0; d < _days; d++)
        if (_prayers.timesFor(DateTime(now.year, now.month, now.day + d), loc, _settings.prayerSettings)
            case Ok(:final value))
          for (final p in Prayer.obligatory)
            if (value.times[p]!.isAfter(now))
              (
                id: _id(value.date, p),
                title: p.labelKey.tr,
                body: 'prayer_alert_body'.trParams({'prayer': p.labelKey.tr}),
                at: value.times[p]!,
              ),
    ];
  }

  /// Stable per (day, prayer). UTC dates so DST shifts never collide two days.
  static int _id(DateTime day, Prayer p) =>
      DateTime.utc(day.year, day.month, day.day).difference(DateTime.utc(2024)).inDays * 10 + p.index;

  @override
  void onClose() {
    unawaited(_sub?.cancel());
    super.onClose();
  }
}
```

**FCM**, used only for announcements and reminders. `lib/data/datasources/remote/messaging_remote_ds.dart`:

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:quran_pro/data/models/push_message.dart';

/// Terminated/background: notification messages are displayed by the OS. Keep this handler
/// trivial; data-only messages would be handled here (it runs in its own isolate).
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {}

final class MessagingRemoteDataSource {
  MessagingRemoteDataSource([FirebaseMessaging? messaging])
      : _m = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _m;

  static void registerBackgroundHandler() =>
      FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

  Future<void> subscribe(String topic) => _m.subscribeToTopic(topic);
  Future<void> unsubscribe(String topic) => _m.unsubscribeFromTopic(topic);

  Stream<PushMessage> get foreground => FirebaseMessaging.onMessage.map(_toModel);
  Stream<PushMessage> get opened => FirebaseMessaging.onMessageOpenedApp.map(_toModel);

  Future<PushMessage?> initial() async {
    final m = await _m.getInitialMessage();
    return m == null ? null : _toModel(m);
  }

  PushMessage _toModel(RemoteMessage m) => PushMessage(
        title: m.notification?.title,
        body: m.notification?.body,
        route: m.data['route'] as String?,
      );
}
```

Next comes a `PushService` (GetxService), which reaches the datasource through a `PushRepository` contract:

- **Subscriptions:** it subscribes to `announcements_<lang>` and re-subscribes when the language changes. Topics mean no FCM token is ever stored.
- **Foreground:** it shows `foreground` messages through `NotificationService` on the general channel, because Android does not display them in the foreground.
- **Opened messages:** for `opened` and `initial()`, it navigates **only if `route` is on an allowlist of `AppRoutes`**. A push payload is untrusted input.
- **Disposal:** it cancels both subscriptions in `onClose`.

The same OS permission covers both FCM and local notifications, so `NotificationService.requestPermission()` handles both.

### 7.5 Bindings and views

```dart
// lib/features/prayer_times/bindings/prayer_times_binding.dart
import 'package:get/get.dart';
import 'package:quran_pro/features/prayer_times/viewmodels/prayer_times_view_model.dart';

final class PrayerTimesBinding extends Bindings {
  @override
  void dependencies() =>
      Get.lazyPut(() => PrayerTimesViewModel(Get.find(), Get.find(), Get.find()), fenix: true);
}

// lib/features/home/bindings/home_binding.dart
import 'package:get/get.dart';
import 'package:quran_pro/features/home/viewmodels/home_view_model.dart';
import 'package:quran_pro/features/prayer_times/bindings/prayer_times_binding.dart';

final class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => HomeViewModel(Get.find()), fenix: true);
    PrayerTimesBinding().dependencies(); // Home's next-prayer card shares the feature ViewModel
  }
}

// lib/features/home/viewmodels/home_view_model.dart
import 'package:get/get.dart';
import 'package:quran_pro/app/routes/app_routes.dart';
import 'package:quran_pro/core/services/auth_service.dart';

final class HomeViewModel extends GetxController {
  HomeViewModel(this._auth);

  final AuthService _auth;

  /// Static for this screen's lifetime: an account switch rebuilds the route stack.
  String get greeting {
    final user = _auth.user;
    final name = user?.displayName;
    return user == null || user.isGuest || name == null || name.isEmpty
        ? 'home_greeting_guest'.tr
        : 'home_greeting'.trParams({'name': name});
  }

  void openPrayerTimes() => Get.toNamed<void>(AppRoutes.prayerTimes);
}
```

```dart
// lib/features/home/views/home_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_pro/features/home/viewmodels/home_view_model.dart';
import 'package:quran_pro/features/prayer_times/views/widgets/next_prayer_card.dart';

final class HomeView extends GetView<HomeViewModel> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(controller.greeting)),
        body: ListView(
          padding: const EdgeInsetsDirectional.all(16),
          children: [
            const NextPrayerCard(),
            const SizedBox(height: 16),
            // Add one tile per feature as its route lands.
            Card(
              child: ListTile(
                leading: const Icon(Icons.access_time),
                title: Text('prayer_times'.tr),
                trailing: const Icon(Icons.chevron_right), // auto-mirrors in RTL
                onTap: controller.openPrayerTimes,
              ),
            ),
          ],
        ),
      );
}

// lib/features/prayer_times/views/widgets/next_prayer_card.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_pro/core/utils/formatters.dart';
import 'package:quran_pro/features/prayer_times/viewmodels/prayer_times_view_model.dart';

final class NextPrayerCard extends GetView<PrayerTimesViewModel> {
  const NextPrayerCard({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    // Outer Obx depends on `next` (changes ~5×/day); inner Obx alone ticks every second.
    return Obx(
      () => controller.next == null
          ? const SizedBox.shrink()
          : Card(
              child: Padding(
                padding: const EdgeInsetsDirectional.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(controller.nextLabel, style: text.titleMedium),
                    const SizedBox(height: 8),
                    Obx(() => Text(Formatters.countdown(controller.remaining), style: text.displaySmall)),
                  ],
                ),
              ),
            ),
    );
  }
}

// lib/features/prayer_times/views/prayer_times_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_pro/core/utils/formatters.dart';
import 'package:quran_pro/core/utils/view_state.dart';
import 'package:quran_pro/core/widgets/error_retry.dart';
import 'package:quran_pro/data/models/prayer.dart';
import 'package:quran_pro/features/prayer_times/viewmodels/prayer_times_view_model.dart';
import 'package:quran_pro/features/prayer_times/views/widgets/next_prayer_card.dart';

final class PrayerTimesView extends GetView<PrayerTimesViewModel> {
  const PrayerTimesView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('prayer_times'.tr)),
        body: Obx(
          () => switch (controller.state) {
            Idle() || Loading() => const Center(child: CircularProgressIndicator()),
            Empty() => const _LocationRationale(),
            ViewError(:final messageKey) => ErrorRetry(messageKey: messageKey, onRetry: controller.load),
            Success(:final data) => RefreshIndicator(
                onRefresh: controller.load,
                child: ListView(
                  padding: const EdgeInsetsDirectional.all(16),
                  children: [
                    const NextPrayerCard(),
                    for (final p in Prayer.values) _PrayerRow(prayer: p, at: data.times[p]!),
                  ],
                ),
              ),
          },
        ),
      );
}

final class _PrayerRow extends GetView<PrayerTimesViewModel> {
  const _PrayerRow({required this.prayer, required this.at});

  final Prayer prayer;
  final DateTime at;

  @override
  Widget build(BuildContext context) => Obx(
        () => ListTile(
          selected: controller.next?.prayer == prayer,
          title: Text(prayer.labelKey.tr),
          trailing: Text(Formatters.time(at)),
        ),
      );
}

final class _LocationRationale extends GetView<PrayerTimesViewModel> {
  const _LocationRationale();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsetsDirectional.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on_outlined, size: 48),
              const SizedBox(height: 16),
              Text('location_rationale'.tr, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Obx(
                () => FilledButton(
                  onPressed: controller.onPermissionAction,
                  child: Text(controller.permissionActionKey.tr),
                ),
              ),
            ],
          ),
        ),
      );
}
```

> **Next step:** add manual city entry for users who refuse location. Store it with `SettingsService.setLastLocation`; nothing else changes.

### 7.6 Tests

`test/data/prayer_times_repository_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_pro/core/errors/result.dart';
import 'package:quran_pro/data/datasources/local/prayer_calc_local_ds.dart';
import 'package:quran_pro/data/models/day_prayer_times.dart';
import 'package:quran_pro/data/models/prayer.dart';
import 'package:quran_pro/data/models/prayer_settings.dart';
import 'package:quran_pro/data/models/user_location.dart';
import 'package:quran_pro/data/repositories/prayer_times_repository_impl.dart';

void main() {
  const repo = PrayerTimesRepositoryImpl(PrayerCalcLocalDataSource());
  final day = DateTime(2026, 3, 15);

  test('times are in canonical order', () {
    final result = repo.timesFor(day, const UserLocation(24.86, 67.01), const PrayerSettings(method: 'karachi'));
    final times = (result as Ok<DayPrayerTimes>).value.times;
    for (var i = 1; i < Prayer.values.length; i++) {
      expect(times[Prayer.values[i]]!.isAfter(times[Prayer.values[i - 1]]!), isTrue);
    }
  });

  test('invalid coordinates and unknown methods become Failures, not crashes', () {
    expect(repo.timesFor(day, const UserLocation(123, 0), const PrayerSettings()), isA<Err<DayPrayerTimes>>());
    expect(
      repo.timesFor(day, const UserLocation(24.86, 67.01), const PrayerSettings(method: 'nope')),
      isA<Err<DayPrayerTimes>>(),
    );
  });

  test('nextAfter returns null after Isha', () {
    final t = DayPrayerTimes(date: day, times: {for (final p in Prayer.values) p: day.add(Duration(hours: p.index))});
    expect(t.nextAfter(day.add(const Duration(hours: 23))), isNull);
    expect(t.nextAfter(day.add(const Duration(minutes: 30)))?.prayer, Prayer.dhuhr);
  });
}
```

**Files:** `data/models/{prayer,day_prayer_times,prayer_settings,user_location,push_message}.dart`, `prayer_calc_local_ds.dart`, `prayer_times_repository{,_impl}.dart`, `core/services/{notification,prayer_schedule}_service.dart`, `messaging_remote_ds.dart`, `features/home/**`, `features/prayer_times/**`, repository test

**Checks:**
- **No logic in views:** state, next prayer, labels and permission actions are all ViewModel getters. Views only switch on `ViewState` ✅
- **Disposal:** `PrayerTimesViewModel` cancels its `Timer` and `StreamSubscription` and disposes the `AppLifecycleListener`. `PrayerScheduleService` cancels its subscription ✅
- **Firebase imports:** only `messaging_remote_ds.dart`. `adhan` and local notifications are not Firebase ✅
- **Secrets:** none ✅

---

## 8. Firestore data model, rules, indexes, rules tests

### 8.1 Data model

```
users/{uid}                       displayName, locale, settings{calcMethod,hanafiAsr,prayerAlerts}, createdAt, updatedAt
users/{uid}/stats/current         xp, streak, badges[]                 ← Cloud Functions only
users/{uid}/prayer_logs/{yyyy-MM-dd}  fajr..isha ∈ none|onTime|late|missed|qada, updatedAt
users/{uid}/progress/{lessonId}   completed, score(0–100), completedAt
users/{uid}/bookmarks/{id}        surah(1–114), ayah(1–286), note?, createdAt
users/{uid}/tasbeeh/{id}          dhikrKey, count, target, createdAt, updatedAt
lessons/{lessonId}                unit, order, title{en,ur,ar}, content{en,ur,ar}, audioUrl?
quizzes/{quizId}                  lessonId, order, questions[]
duas/{duaId}                      category, order, arabic, transliteration, translations{en,ur}
names_of_allah/{n}                arabic, transliteration, meaning{en,ur,ar}
```

- Every timestamp is written with `FieldValue.serverTimestamp()`, and the rules require `== request.time`.
- Quran text, duas and the 99 Names are **bundled** in `assets/data/`. The collections exist for updates without a release.

**Typed reads and pagination.** This is the pattern for every remote datasource:

```dart
// lib/data/models/lesson_model.dart
import 'package:equatable/equatable.dart';

final class LessonModel extends Equatable {
  const LessonModel({
    required this.id,
    required this.unit,
    required this.order,
    required this.title,
    required this.content,
    this.audioUrl,
  });

  factory LessonModel.fromJson(String id, Map<String, dynamic> json) => LessonModel(
        id: id,
        unit: json['unit'] as int,
        order: json['order'] as int,
        title: Map<String, String>.from(json['title'] as Map),
        content: Map<String, String>.from(json['content'] as Map),
        audioUrl: json['audioUrl'] as String?,
      );

  final String id;
  final int unit;
  final int order;
  final Map<String, String> title;
  final Map<String, String> content;
  final String? audioUrl;

  String titleFor(String lang) => title[lang] ?? title['en'] ?? '';

  Map<String, dynamic> toJson() =>
      {'unit': unit, 'order': order, 'title': title, 'content': content, 'audioUrl': audioUrl};

  LessonModel copyWith({String? audioUrl}) => LessonModel(
        id: id, unit: unit, order: order, title: title, content: content,
        audioUrl: audioUrl ?? this.audioUrl,
      );

  @override
  List<Object?> get props => [id, unit, order, title, content, audioUrl];
}

// lib/data/datasources/remote/lesson_remote_ds.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quran_pro/data/datasources/remote/firebase_guard.dart';
import 'package:quran_pro/data/models/lesson_model.dart';

final class LessonRemoteDataSource {
  LessonRemoteDataSource([FirebaseFirestore? db]) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  late final _lessons = _db.collection('lessons').withConverter<LessonModel>(
        fromFirestore: (snap, _) => LessonModel.fromJson(snap.id, snap.data()!),
        toFirestore: (lesson, _) => lesson.toJson(),
      );

  /// [afterOrder] is the `order` of the last lesson already shown (null for the first page).
  Future<List<LessonModel>> page({required int unit, int? afterOrder, int limit = 20}) =>
      guard(() async {
        var q = _lessons.where('unit', isEqualTo: unit).orderBy('order').limit(limit);
        if (afterOrder != null) q = q.startAfter([afterOrder]);
        return (await q.get()).docs.map((d) => d.data()).toList();
      });
}
```

### 8.2 `firestore.rules`

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Anything not matched below is denied.

    function signedIn() { return request.auth != null; }
    function isOwner(uid) { return signedIn() && request.auth.uid == uid; }
    function isAdmin() { return signedIn() && request.auth.token.admin == true; }
    function incoming() { return request.resource.data; }
    function isStr(v, min, max) { return v is string && v.size() >= min && v.size() <= max; }
    function inRange(v, lo, hi) { return v is int && v >= lo && v <= hi; }
    function exactKeys(keys) { return incoming().keys().hasAll(keys) && incoming().keys().hasOnly(keys); }
    function onlyChanged(keys) { return incoming().diff(resource.data).affectedKeys().hasOnly(keys); }
    function isNow(v) { return v == request.time; }

    // ---------- Public content: read-only for clients ----------
    // Admin SDK / Console bypass rules; isAdmin() serves an in-house admin panel.
    match /lessons/{id}        { allow read: if signedIn(); allow write: if isAdmin(); }
    match /quizzes/{id}        { allow read: if signedIn(); allow write: if isAdmin(); }
    match /duas/{id}           { allow read: if signedIn(); allow write: if isAdmin(); }
    match /names_of_allah/{id} { allow read: if signedIn(); allow write: if isAdmin(); }

    // ---------- Per-user data: owner only ----------
    match /users/{uid} {
      function validSettings(s) {
        return s is map
          && s.keys().hasOnly(['calcMethod', 'hanafiAsr', 'prayerAlerts'])
          && (!('calcMethod' in s) || isStr(s.calcMethod, 1, 40))
          && (!('hanafiAsr' in s) || s.hanafiAsr is bool)
          && (!('prayerAlerts' in s) || s.prayerAlerts is bool);
      }
      function validProfile() {
        return (!('displayName' in incoming()) || isStr(incoming().displayName, 0, 50))
          && (!('locale' in incoming()) || incoming().locale in ['en', 'ur', 'ar'])
          && (!('settings' in incoming()) || validSettings(incoming().settings));
      }

      allow read, delete: if isOwner(uid);
      allow create: if isOwner(uid)
        && incoming().keys().hasOnly(['displayName', 'locale', 'settings', 'createdAt', 'updatedAt'])
        && isNow(incoming().createdAt) && isNow(incoming().updatedAt)
        && validProfile();
      allow update: if isOwner(uid)
        && onlyChanged(['displayName', 'locale', 'settings', 'updatedAt'])
        && isNow(incoming().updatedAt)
        && validProfile();

      // XP / streak / badges feed leaderboards: written by Cloud Functions only.
      match /stats/{doc} {
        allow read: if isOwner(uid);
        allow write: if false;
      }

      match /prayer_logs/{date} {
        function validStatus(s) { return s in ['none', 'onTime', 'late', 'missed', 'qada']; }
        allow read, delete: if isOwner(uid);
        allow create, update: if isOwner(uid)
          && date.matches('^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
          && exactKeys(['fajr', 'dhuhr', 'asr', 'maghrib', 'isha', 'updatedAt'])
          && validStatus(incoming().fajr) && validStatus(incoming().dhuhr)
          && validStatus(incoming().asr) && validStatus(incoming().maghrib)
          && validStatus(incoming().isha)
          && isNow(incoming().updatedAt);
      }

      match /progress/{lessonId} {
        function validProgress() {
          return exactKeys(['completed', 'score', 'completedAt'])
            && incoming().completed is bool
            && inRange(incoming().score, 0, 100)
            && isNow(incoming().completedAt);
        }
        allow read: if isOwner(uid);
        allow create: if isOwner(uid) && validProgress()
          && exists(/databases/$(database)/documents/lessons/$(lessonId));
        // A completed lesson can't be "un-completed" (would let XP be farmed by toggling).
        allow update: if isOwner(uid) && validProgress()
          && !(resource.data.completed == true && incoming().completed == false);
        allow delete: if false;
      }

      match /bookmarks/{id} {
        allow read, delete: if isOwner(uid);
        allow create: if isOwner(uid)
          && incoming().keys().hasAll(['surah', 'ayah', 'createdAt'])
          && incoming().keys().hasOnly(['surah', 'ayah', 'note', 'createdAt'])
          && inRange(incoming().surah, 1, 114) && inRange(incoming().ayah, 1, 286)
          && (!('note' in incoming()) || isStr(incoming().note, 0, 500))
          && isNow(incoming().createdAt);
        allow update: if isOwner(uid) && onlyChanged(['note']) && isStr(incoming().note, 0, 500);
      }

      match /tasbeeh/{id} {
        allow read, delete: if isOwner(uid);
        allow create: if isOwner(uid)
          && exactKeys(['dhikrKey', 'count', 'target', 'createdAt', 'updatedAt'])
          && isStr(incoming().dhikrKey, 1, 64)
          && inRange(incoming().count, 0, 100000) && inRange(incoming().target, 1, 100000)
          && isNow(incoming().createdAt) && isNow(incoming().updatedAt);
        allow update: if isOwner(uid)
          && onlyChanged(['count', 'updatedAt'])
          && inRange(incoming().count, 0, 100000)
          && isNow(incoming().updatedAt);
      }
    }
  }
}
```

### 8.3 `storage.rules`

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Lesson images/audio: uploaded via Console / Admin SDK only.
    match /content/{path=**} {
      allow read: if request.auth != null;
      allow write: if false;
    }

    // User uploads (avatar, recorded recitation).
    match /users/{uid}/{fileName} {
      allow read, delete: if request.auth != null && request.auth.uid == uid;
      allow create, update: if request.auth != null && request.auth.uid == uid
        && fileName.matches('^[A-Za-z0-9_-]{1,64}[.](png|jpe?g|webp|mp3|m4a|aac)$')
        && request.resource.size < 5 * 1024 * 1024
        && request.resource.contentType.matches('^(image/(png|jpeg|webp)|audio/(mpeg|mp4|aac))$');
    }
  }
}
```

### 8.4 `firestore.indexes.json`

```json
{
  "indexes": [
    {
      "collectionGroup": "lessons",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "unit", "order": "ASCENDING" },
        { "fieldPath": "order", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "quizzes",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "lessonId", "order": "ASCENDING" },
        { "fieldPath": "order", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "duas",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "category", "order": "ASCENDING" },
        { "fieldPath": "order", "order": "ASCENDING" }
      ]
    }
  ],
  "fieldOverrides": []
}
```

The emulator does **not** enforce indexes. Run new queries against the dev project, follow the link in the error to create the index, and then run `firebase firestore:indexes -P dev > firestore.indexes.json`.

### 8.5 `firebase.json`

`flutterfire` also adds a `flutter` section here. Keep it.

```json
{
  "firestore": { "rules": "firestore.rules", "indexes": "firestore.indexes.json" },
  "storage": { "rules": "storage.rules" },
  "functions": [{ "source": "functions", "codebase": "default" }],
  "emulators": {
    "auth": { "port": 9099 },
    "firestore": { "port": 8080 },
    "storage": { "port": 9199 },
    "ui": { "enabled": true }
  }
}
```

### 8.6 Rules tests (emulator)

These need **Node ≥ 24.12**, because `@firebase/rules-unit-testing@6` requires it. The local machine currently has Node 22.

`firebase_tests/package.json`:

```json
{
  "name": "quran-pro-rules-tests",
  "private": true,
  "type": "module",
  "scripts": { "test": "mocha --timeout 15000 'rules.test.mjs'" },
  "devDependencies": {
    "@firebase/rules-unit-testing": "6.0.0",
    "firebase": "13.2.0",
    "mocha": "12.0.3"
  }
}
```

`firebase_tests/rules.test.mjs`:

```js
import { readFileSync } from 'node:fs';
import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, updateDoc, serverTimestamp } from 'firebase/firestore';
import { ref, uploadBytes } from 'firebase/storage';

let env;
const db = (uid, claims) =>
  (uid ? env.authenticatedContext(uid, claims) : env.unauthenticatedContext()).firestore();
const storage = (uid) => env.authenticatedContext(uid).storage();
const seed = (path, data) => env.withSecurityRulesDisabled((c) => setDoc(doc(c.firestore(), path), data));

const log = () => ({
  fajr: 'onTime', dhuhr: 'late', asr: 'none', maghrib: 'missed', isha: 'qada',
  updatedAt: serverTimestamp(),
});
const LOG = 'users/alice/prayer_logs/2026-11-11';

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-quran-pro',
    firestore: { rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8') },
    storage: { rules: readFileSync(new URL('../storage.rules', import.meta.url), 'utf8') },
  });
});
afterEach(async () => { await env.clearFirestore(); await env.clearStorage(); });
after(() => env.cleanup());

describe('users/{uid}/prayer_logs', () => {
  it('owner writes a valid log', () => assertSucceeds(setDoc(doc(db('alice'), LOG), log())));
  it('another user cannot read it', async () => {
    await seed(LOG, { ...log(), updatedAt: new Date() });
    await assertFails(getDoc(doc(db('bob'), LOG)));
  });
  it('signed-out user cannot read it', () => assertFails(getDoc(doc(db(null), LOG))));
  it('rejects unknown status', () => assertFails(setDoc(doc(db('alice'), LOG), { ...log(), fajr: 'maybe' })));
  it('rejects extra keys', () => assertFails(setDoc(doc(db('alice'), LOG), { ...log(), xp: 999 })));
  it('rejects client timestamps', () => assertFails(setDoc(doc(db('alice'), LOG), { ...log(), updatedAt: new Date() })));
  it('rejects malformed date ids', () => assertFails(setDoc(doc(db('alice'), 'users/alice/prayer_logs/today'), log())));
});

describe('users/{uid} profile and stats', () => {
  it('cannot write own stats (XP)', () => assertFails(setDoc(doc(db('alice'), 'users/alice/stats/current'), { xp: 1e6 })));
  it('cannot change createdAt', async () => {
    await seed('users/alice', { displayName: 'A', createdAt: new Date(0), updatedAt: new Date(0) });
    await assertFails(updateDoc(doc(db('alice'), 'users/alice'), { createdAt: serverTimestamp(), updatedAt: serverTimestamp() }));
    await assertSucceeds(updateDoc(doc(db('alice'), 'users/alice'), { displayName: 'B', updatedAt: serverTimestamp() }));
  });
});

describe('progress', () => {
  const p = (completed) => ({ completed, score: 80, completedAt: serverTimestamp() });
  it('requires the lesson to exist', () => assertFails(setDoc(doc(db('alice'), 'users/alice/progress/l9'), p(true))));
  it('cannot un-complete a lesson', async () => {
    await seed('lessons/l1', { unit: 1, order: 1 });
    await seed('users/alice/progress/l1', { completed: true, score: 80, completedAt: new Date() });
    await assertFails(setDoc(doc(db('alice'), 'users/alice/progress/l1'), p(false)));
  });
});

describe('public content', () => {
  beforeEach(() => seed('lessons/l1', { unit: 1, order: 1 }));
  it('signed-in (incl. guest) can read', () => assertSucceeds(getDoc(doc(db('alice'), 'lessons/l1'))));
  it('signed-out cannot read', () => assertFails(getDoc(doc(db(null), 'lessons/l1'))));
  it('clients cannot write', () => assertFails(setDoc(doc(db('alice'), 'lessons/l1'), { unit: 2 })));
  it('admin claim can write', () => assertSucceeds(setDoc(doc(db('root', { admin: true }), 'lessons/l1'), { unit: 2 })));
});

describe('storage', () => {
  const up = (uid, path, size, contentType) =>
    uploadBytes(ref(storage(uid), path), new Uint8Array(size), { contentType });
  it('owner uploads a small image', () => assertSucceeds(up('alice', 'users/alice/avatar.png', 10, 'image/png')));
  it('rejects other uid', () => assertFails(up('bob', 'users/alice/avatar.png', 10, 'image/png')));
  it('rejects wrong content type', () => assertFails(up('alice', 'users/alice/doc.png', 10, 'application/pdf')));
  it('rejects > 5 MB', () => assertFails(up('alice', 'users/alice/big.png', 5 * 1024 * 1024 + 1, 'image/png')));
  it('content is read-only', () => assertFails(up('alice', 'content/x.png', 10, 'image/png')));
});
```

Run them with:

```sh
npm --prefix firebase_tests ci
firebase emulators:exec --only firestore,storage "npm --prefix firebase_tests test"
```

### 8.7 Cloud Function: XP (server-side counterpart)

`functions/src/index.ts`:

```ts
import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { initializeApp } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';

initializeApp();

export const onProgressWritten = onDocumentWritten('users/{uid}/progress/{lessonId}', async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  if (!after?.completed || before?.completed) return; // award once per lesson (rules forbid un-completing)
  await getFirestore().doc(`users/${event.params.uid}/stats/current`).set(
    { xp: FieldValue.increment(10 + Math.round(after.score / 10)), updatedAt: FieldValue.serverTimestamp() },
    { merge: true },
  );
});
```

> `score` is still reported by the client. Once a leaderboard goes public, grade quizzes in a callable function so the answers never reach the client, and award XP from that grade.

**Files:** `firestore.rules`, `storage.rules`, `firestore.indexes.json`, `firebase.json`, `firebase_tests/*`, `functions/src/index.ts`, `lesson_model.dart`, `lesson_remote_ds.dart`

**Checks:**
- **No logic in views:** no views in this step ✅
- **Disposal:** no controllers in this step ✅
- **Firebase imports:** `lesson_remote_ds.dart` is under `data/datasources/remote/` ✅
- **Secrets:** the tests use a `demo-` project ID, which can't reach production ✅

---

## 9. README

Replace `README.md` with the sections below.

### Setup

1. Install Flutter 3.47.9 or later, Node 24.12 or later, and the Firebase CLI (`npm i -g firebase-tools`). Then run `dart pub global activate flutterfire_cli`.
2. Run `flutter pub get`.
3. Get access to the three Firebase projects, then run the `flutterfire configure` loop in [PROJECT_SETUP.md §3.4](PROJECT_SETUP.md). That writes the gitignored config files.
4. Copy `env/example.json` to `env/dev.json` and fill it in. Ask the team lead for the values.
5. Run `tool/check_architecture.sh && flutter analyze && flutter test`.

### Run (flavors)

```sh
flutter run --flavor dev     -t lib/main_dev.dart     --dart-define-from-file=env/dev.json
flutter run --flavor staging -t lib/main_staging.dart --dart-define-from-file=env/staging.json
flutter run --flavor prod    -t lib/main_prod.dart    --dart-define-from-file=env/prod.json
```

### Emulators

```sh
firebase emulators:start --only auth,firestore,storage       # UI at http://localhost:4000
# then run dev with "USE_EMULATORS": "true" in env/dev.json
firebase emulators:exec --only firestore,storage "npm --prefix firebase_tests test"   # rules tests
```

### Deploy rules, indexes and functions

```sh
firebase deploy --only firestore:rules,firestore:indexes,storage -P dev    # then staging, then prod
firebase deploy --only functions -P <alias>
```

Rules reach prod only after the rules tests pass in CI.

### Release builds

```sh
flutter build appbundle --flavor prod -t lib/main_prod.dart --release \
  --obfuscate --split-debug-info=build/symbols/prod --dart-define-from-file=env/prod.json
flutter build ipa --flavor prod -t lib/main_prod.dart --release \
  --obfuscate --split-debug-info=build/symbols/prod --dart-define-from-file=env/prod.json

# De-obfuscate Dart stack traces in Crashlytics:
firebase crashlytics:symbols:upload --app=<FIREBASE_ANDROID_APP_ID> build/symbols/prod
firebase crashlytics:symbols:upload --app=<FIREBASE_IOS_APP_ID> build/symbols/prod
```

R8 and resource shrinking are on for Android release builds (§3.2). Signing reads `android/key.properties`, which is gitignored.

### CI secrets

Store each gitignored file base64-encoded as a CI secret and decode it before building:

- `firebase_options_<flavor>.dart`
- `google-services.json` for each flavor
- `GoogleService-Info.plist` for each flavor
- `env/<flavor>.json`
- the upload keystore
- `key.properties`

---

## Definition of done (whole setup)

- [ ] `tool/check_architecture.sh`, `dart format --set-exit-if-changed .`, `flutter analyze` and `flutter test` are all green.
- [ ] Rules tests are green on the emulator.
- [ ] Each flavor installs side by side, with a distinct app name and Firebase project.
- [ ] Guest → Google upgrade keeps the same uid. Sign-out returns to Auth, and `Get.isRegistered<HomeViewModel>()` is `false` afterwards.
- [ ] Airplane mode: prayer times, the countdown and bundled content still work, and the offline banner shows.
- [ ] Azan alerts fire with the app killed, after a reboot, and in inexact mode when exact alarms are denied.
- [ ] Arabic and Urdu render RTL with no clipped text, and a native speaker has reviewed the strings.
- [ ] App Check is in monitoring mode, then switched to enforcement. API keys are restricted.
- [ ] Release builds are obfuscated, and symbols are uploaded to Crashlytics.
