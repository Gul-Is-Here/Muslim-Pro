import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_pro/core/localization/app_translations.dart';
import 'package:quran_pro/core/network/connectivity_service.dart';
import 'package:quran_pro/core/services/audio_service.dart';
import 'package:quran_pro/core/services/notification_service.dart';
import 'package:quran_pro/core/services/prayer_schedule_service.dart';
import 'package:quran_pro/core/services/settings_service.dart';
import 'package:quran_pro/core/theme/app_theme.dart';
import 'package:quran_pro/data/datasources/local/prayer_calc_local_ds.dart';
import 'package:quran_pro/data/models/user_location.dart';
import 'package:quran_pro/data/repositories/prayer_times_repository_impl.dart';
import 'package:quran_pro/features/settings/viewmodels/prayer_notifications_view_model.dart';
import 'package:quran_pro/features/settings/views/prayer_notifications_view.dart';

class _Player extends Mock implements AudioPlayer;

class _Connectivity extends Mock implements Connectivity;

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir = Directory.systemTemp.createTempSync('prayer_notif_test');
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (_) async => dir.path,
      )
      ..setMockMethodCallHandler(
        const MethodChannel('flutter_timezone'),
        (_) async => 'Asia/Karachi',
      )
      ..setMockMethodCallHandler(
        const MethodChannel('dexterous.com/flutter/local_notifications'),
        (call) async => switch (call.method) {
          'initialize' => false,
          'areNotificationsEnabled' || 'canScheduleExactNotifications' => true,
          _ => null,
        },
      );
    await GetStorage.init();
    await initializeDateFormatting();
  });

  tearDown(Get.reset);

  for (final (name, size, ratio) in [
    ('Pixel 7 Pro', const Size(1080, 2340), 2.625),
    ('small phone', const Size(720, 1280), 2.0),
  ]) {
    testWidgets('master switch gates the prayer rows; a row opens its sound sheet ($name)', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      final settings = SettingsService(GetStorage());
      await settings.setLastLocation(const UserLocation(24.86, 67.01));
      await settings.setPrayerAlerts(on: true);
      const prayers = PrayerTimesRepositoryImpl(PrayerCalcLocalDataSource());
      final notifications = NotificationService();
      Get.put(
        PrayerNotificationsViewModel(
          settings,
          notifications,
          PrayerScheduleService(prayers, notifications, settings),
          AudioService(ConnectivityService(_Connectivity()), _Player()),
          prayers,
        ),
      );
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.light,
          translations: AppTranslations(),
          locale: const Locale('en'),
          home: const PrayerNotificationsView(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Azan reminders'), findsOneWidget);
      expect(find.text('DAILY PRAYERS'), findsOneWidget);
      expect(find.byType(Switch), findsNWidgets(6)); // master + five prayers
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Fajr'));
      await tester.pumpAndSettle();
      expect(find.text('Azan sound for Fajr'), findsOneWidget);
      expect(find.text('Madinah · Masjid an-Nabawi'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tapAt(const Offset(10, 10)); // dismiss the sheet
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch).first); // master off
      await tester.pumpAndSettle();
      expect(settings.prayerAlertsOn, isFalse);
      final fajrSwitch = tester.widget<Switch>(find.byType(Switch).at(1));
      expect(fajrSwitch.onChanged, isNull, reason: 'per-prayer switches follow the master');
      await tester.tap(find.text('Fajr'));
      await tester.pumpAndSettle();
      expect(find.text('Azan sound for Fajr'), findsNothing);
    });
  }
}
