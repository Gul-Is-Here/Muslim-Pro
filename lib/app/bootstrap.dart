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
