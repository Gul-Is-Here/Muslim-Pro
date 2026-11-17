import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:quran_pro/core/localization/app_translations.dart';
import 'package:quran_pro/core/services/location_service.dart';
import 'package:quran_pro/core/services/location_sync_service.dart';
import 'package:quran_pro/core/services/notification_service.dart';
import 'package:quran_pro/core/services/settings_service.dart';
import 'package:quran_pro/features/onboarding/viewmodels/onboarding_view_model.dart';
import 'package:quran_pro/features/onboarding/views/onboarding_view.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir = Directory.systemTemp.createTempSync('onboarding_test');
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (_) async => dir.path,
      )
      // Location services on, permission not yet asked.
      ..setMockMethodCallHandler(
        const MethodChannel('flutter.baseflow.com/geolocator'),
        (call) async => call.method == 'isLocationServiceEnabled' ? true : 0,
      )
      ..setMockMethodCallHandler(
        const MethodChannel('flutter_timezone'),
        (_) async => 'Asia/Karachi',
      )
      ..setMockMethodCallHandler(
        const MethodChannel('dexterous.com/flutter/local_notifications'),
        (call) async => switch (call.method) {
          'initialize' || 'areNotificationsEnabled' => false,
          _ => null,
        },
      );
    await GetStorage.init();
  });

  tearDown(Get.reset);

  for (final (name, size, ratio) in [
    ('Pixel 7 Pro', const Size(1080, 2340), 2.625),
    ('small phone', const Size(720, 1280), 2.0),
  ]) {
    testWidgets('walks welcome → location → alerts without overflow on $name', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);
      final settings = SettingsService(GetStorage());
      final location = LocationService();
      Get.put(
        OnboardingViewModel(
          settings,
          NotificationService(),
          location,
          LocationSyncService(location, settings),
        ),
      );
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en'),
          home: const OnboardingView(),
        ),
      );
      await tester.pumpAndSettle();
      final vm = Get.find<OnboardingViewModel>();

      expect(find.text('Your daily companion'), findsOneWidget);
      expect(find.text('Not now'), findsNothing, reason: 'nothing to skip on the welcome step');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(vm.step, OnboardingStep.location);
      expect(find.text('Accurate prayer times & Qibla'), findsOneWidget);
      expect(find.text('Allow location'), findsOneWidget);
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();

      expect(vm.step, OnboardingStep.alerts);
      expect(find.text("It's time for Maghrib"), findsOneWidget);
      expect(find.text('Enable prayer alerts'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
