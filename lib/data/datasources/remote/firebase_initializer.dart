import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:quran_pro/core/config/env.dart';
import 'package:quran_pro/core/config/flavor_config.dart';
import 'package:quran_pro/data/datasources/remote/firebase_options/firebase_options_dev.dart'
    as dev;
import 'package:quran_pro/data/datasources/remote/firebase_options/firebase_options_prod.dart'
    as prod;
import 'package:quran_pro/data/datasources/remote/firebase_options/firebase_options_staging.dart'
    as staging;

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
