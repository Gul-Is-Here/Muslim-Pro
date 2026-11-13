import java.util.Base64
import java.util.Properties

plugins {
    id("com.android.application")
    // `flutterfire configure` adds com.google.gms.google-services and
    // com.google.firebase.crashlytics here (they need the per-flavor google-services.json).
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Values from --dart-define / --dart-define-from-file=env/<flavor>.json (Flutter passes them
// base64-encoded). Keeps the Maps key out of git, like every other per-environment value.
val dartDefines: Map<String, String> =
    (project.findProperty("dart-defines") as String?).orEmpty().split(",").filter { it.isNotEmpty() }
        .map { String(Base64.getDecoder().decode(it)).split("=", limit = 2) }
        .associate { it[0] to it.getOrElse(1) { "" } }

val keystore = Properties().apply {
    rootProject.file("key.properties").takeIf { it.exists() }?.inputStream()?.use { load(it) }
}

android {
    namespace = "com.islamicnoorapp.app"
    compileSdk = 37 // flutter_local_notifications 23 requires 37; flutter default is 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true // required by flutter_local_notifications
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.islamicnoorapp.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["mapsApiKey"] = dartDefines["GOOGLE_MAPS_API_KEY"].orEmpty()
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
        create("dev") {
            dimension = "env"
            applicationIdSuffix = ".dev"
            resValue("string", "app_name", "Quran Pro Dev")
        }
        create("staging") {
            dimension = "env"
            applicationIdSuffix = ".stg"
            resValue("string", "app_name", "Quran Pro Stg")
        }
        create("prod") {
            dimension = "env"
            resValue("string", "app_name", "Quran Pro")
        }
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

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
