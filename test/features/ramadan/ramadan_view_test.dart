import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_pro/core/errors/result.dart';
import 'package:quran_pro/core/network/connectivity_service.dart';
import 'package:quran_pro/core/services/audio_service.dart';
import 'package:quran_pro/core/services/ramadan_service.dart';
import 'package:quran_pro/core/services/settings_service.dart';
import 'package:quran_pro/data/datasources/local/quran_local_ds.dart';
import 'package:quran_pro/data/models/day_prayer_times.dart';
import 'package:quran_pro/data/models/prayer.dart';
import 'package:quran_pro/data/models/prayer_settings.dart';
import 'package:quran_pro/data/models/ramadan_progress.dart';
import 'package:quran_pro/data/models/user_location.dart';
import 'package:quran_pro/data/repositories/quran_repository_impl.dart';
import 'package:quran_pro/domain/repositories/prayer_times_repository.dart';
import 'package:quran_pro/features/ramadan/viewmodels/ramadan_view_model.dart';
import 'package:quran_pro/features/ramadan/views/ramadan_view.dart';

class _Player extends Mock implements AudioPlayer;

class _Prayers extends Mock implements PrayerTimesRepository;

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir = Directory.systemTemp.createTempSync('ramadan_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => dir.path,
    );
    await GetStorage.init();
    await initializeDateFormatting();
  });

  tearDown(Get.reset);

  // The page list, not the calendar grid inside it.
  Finder list() => find.byType(Scrollable).first;

  Future<RamadanService> pump(WidgetTester tester) async {
    await GetStorage().erase();
    tester.view.physicalSize = const Size(1080, 2340); // Pixel 7 Pro
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    final ramadan = RamadanService(GetStorage());
    Get.put(
      RamadanViewModel(
        ramadan,
        _Prayers(),
        SettingsService(GetStorage()), // no saved location: times show as --:--
        AudioService(ConnectivityService(), _Player()),
        const QuranRepositoryImpl(QuranLocalDataSource()),
      ),
    );
    await tester.pumpWidget(const GetMaterialApp(home: RamadanView()));
    await tester.pump();
    return ramadan;
  }

  testWidgets('before Ramadan: countdown, locked calendar, duas; nothing overflows', (
    tester,
  ) async {
    final ramadan = await pump(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('ramadan_days_to_go'), findsOneWidget);
    expect(find.text('ramadan_calendar_locked'), findsOneWidget);
    expect(find.text('ramadan_deeds'), findsNothing, reason: 'checklist is for Ramadan days');

    await tester.tap(find.text('1')); // locked: nothing happens
    await tester.pump();
    expect(ramadan.progress.fasts, isEmpty);

    await tester.scrollUntilVisible(find.text('ramadan_dua_qadr'), 300, scrollable: list());
    expect(tester.takeException(), isNull);
    await Get.delete<RamadanViewModel>(); // stops the countdown ticker
  });

  testWidgets('preview: mark a day, tick a deed, adjust make-up fasts', (tester) async {
    final ramadan = await pump(tester);
    await tester.tap(find.text('ramadan_preview'));
    await tester.pump();
    expect(find.text('ramadan_calendar_hint'), findsOneWidget);

    await tester.tap(find.text('3'));
    await tester.pump();
    final vm = Get.find<RamadanViewModel>();
    expect(ramadan.progress.fastOn(vm.year, 3), FastStatus.fasted);
    await tester.tap(find.text('13')); // a day after "today" (12) stays closed
    await tester.pump();
    expect(ramadan.progress.fastOn(vm.year, 13), FastStatus.none);

    await tester.scrollUntilVisible(find.text('ramadan_deed_taraweeh'), 300, scrollable: list());
    await tester.tap(find.text('ramadan_deed_taraweeh'));
    await tester.pump();
    expect(ramadan.progress.deedsOn(vm.year, 12), {RamadanDeed.taraweeh});

    await tester.scrollUntilVisible(find.text('ramadan_qada_before'), 300, scrollable: list());
    await tester.tap(find.byIcon(Icons.add_rounded).first);
    await tester.pump();
    expect(vm.owed, 1);
    expect(tester.takeException(), isNull);
    await Get.delete<RamadanViewModel>();
  });

  test('countdown: suhoor before fajr, iftar before maghrib, then tomorrow’s suhoor', () async {
    await GetStorage().erase();
    final settings = SettingsService(GetStorage());
    await settings.setLastLocation(const UserLocation(31.5, 74.3));
    final prayers = _Prayers();
    registerFallbackValue(const UserLocation(0, 0));
    registerFallbackValue(PrayerSettings.forCountry(null));
    registerFallbackValue(DateTime(2000));
    // Fajr one hour before now, maghrib one hour after: we are mid-fast.
    final now = DateTime.now();
    when(() => prayers.timesFor(any(), any(), any())).thenAnswer((inv) {
      final day = inv.positionalArguments.first as DateTime;
      final shift = DateTime(
        day.year,
        day.month,
        day.day,
      ).difference(DateTime(now.year, now.month, now.day));
      return Ok(
        DayPrayerTimes(
          date: day,
          times: {
            Prayer.fajr: now.subtract(const Duration(hours: 1)).add(shift),
            Prayer.maghrib: now.add(const Duration(hours: 1)).add(shift),
          },
        ),
      );
    });
    final vm = RamadanViewModel(
      RamadanService(GetStorage()),
      prayers,
      settings,
      AudioService(ConnectivityService(), _Player()),
      const QuranRepositoryImpl(QuranLocalDataSource()),
    );
    expect(vm.next?.event, FastEvent.iftar);
    expect(vm.countdown, anyOf('00:59:59', '01:00:00'));
    expect(vm.fastFraction, closeTo(0.5, 0.01));
  });
}
