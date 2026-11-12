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
