// Renders real app screens (real fonts, sample data) for the Play Store listing.
// Run: TZ=Europe/London flutter test tool/store/store_screens_test.dart
// then:  flutter test tool/store/store_frames_test.dart
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_pro/app/bindings/initial_binding.dart';
import 'package:quran_pro/app/routes/app_pages.dart';
import 'package:quran_pro/app/routes/app_routes.dart';
import 'package:quran_pro/core/config/flavor_config.dart';
import 'package:quran_pro/core/errors/result.dart';
import 'package:quran_pro/core/localization/app_translations.dart';
import 'package:quran_pro/core/network/connectivity_service.dart';
import 'package:quran_pro/core/services/audio_service.dart';
import 'package:quran_pro/core/services/learn_service.dart';
import 'package:quran_pro/core/services/quran_service.dart';
import 'package:quran_pro/core/services/settings_service.dart';
import 'package:quran_pro/core/theme/app_theme.dart';
import 'package:quran_pro/data/models/app_user.dart';
import 'package:quran_pro/data/models/learn_progress.dart';
import 'package:quran_pro/data/models/saved_place.dart';
import 'package:quran_pro/data/models/user_location.dart';
import 'package:quran_pro/domain/repositories/auth_repository.dart';

class _Auth extends Mock implements AuthRepository;

class _Player extends Mock implements AudioPlayer;

class _Connectivity extends Mock implements Connectivity;

final GlobalKey _key = GlobalKey();
const _out = 'build/store/screens';

Future<void> _font(String family, List<String> paths) async {
  final l = FontLoader(family);
  for (final p in paths) {
    l.addFont(Future.value(ByteData.sublistView(File(p).readAsBytesSync())));
  }
  await l.load();
}

void main() {
  testWidgets('store screens', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    final dir = Directory.systemTemp.createTempSync('store');
    FlavorConfig.instance = const FlavorConfig(Flavor.prod);
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (_) async => dir.path,
      )
      ..setMockMethodCallHandler(
        const MethodChannel('flutter.baseflow.com/geolocator'),
        (call) async => switch (call.method) {
          'isLocationServiceEnabled' => true,
          'checkPermission' || 'requestPermission' => 2, // while in use
          _ => throw PlatformException(code: 'unavailable'), // keeps the stored location
        },
      )
      ..setMockMethodCallHandler(
        const MethodChannel('flutter_timezone'),
        (_) async => 'Europe/London',
      )
      ..setMockMethodCallHandler(
        const MethodChannel('dexterous.com/flutter/local_notifications'),
        (call) async => switch (call.method) {
          'initialize' => false,
          'areNotificationsEnabled' || 'canScheduleExactNotifications' => true,
          'pendingNotificationRequests' => <Object>[],
          _ => null,
        },
      );
    expect(messenger, isNotNull);

    await tester.runAsync(() async {
      await _font('Manrope', [
        for (final w in [400, 600, 700, 800]) 'assets/fonts/Manrope-$w.ttf',
      ]);
      await _font('Amiri', ['assets/fonts/Amiri-Regular.ttf']);
      await _font('JetBrainsMono', ['assets/fonts/JetBrainsMono-700.ttf']);
      await _font('NotoNastaliqUrdu', ['assets/fonts/NotoNastaliqUrdu-Regular.ttf']);
      final root =
          Platform.environment['FLUTTER_ROOT'] ??
          File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.parent.path;
      await _font('Roboto', [
        for (final w in ['Regular', 'Medium', 'Bold'])
          '$root/bin/cache/artifacts/material_fonts/Roboto-$w.ttf',
      ]);
      await _font('MaterialIcons', [
        '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      ]);
      await GetStorage.init();
      await GetStorage.init('user_cache');
      await initializeDateFormatting();
    });

    // Sample data: settled in London, a few days into learning, reading Al-Kahf.
    final box = GetStorage();
    await box.write('onboarded', true);
    final settings = SettingsService(box);
    await settings.setLastLocation(const UserLocation(51.5072, -0.1276));
    await settings.setLastPlace(
      const SavedPlace(at: UserLocation(51.5072, -0.1276), name: 'London', countryCode: 'GB'),
    );
    final now = DateTime.now();
    var progress = const LearnProgress();
    for (final back in [5, 4, 3, 2, 1, 0]) {
      progress = progress.complete('s$back', 40, DateTime(now.year, now.month, now.day - back, 9));
    }
    await box.write('learnProgress', progress.toJson());
    final quran = QuranService(box)..lastRead = (surah: 18, ayah: 10);
    [
      (surah: 2, ayah: 255),
      (surah: 18, ayah: 10),
      (surah: 36, ayah: 58),
    ].forEach(quran.toggleBookmark);

    // Stand-ins for Firebase sign-in, the audio player and connectivity.
    final auth = _Auth();
    when(auth.authStateChanges).thenAnswer(
      (_) => Stream.value(
        const AppUser(
          uid: 'u',
          isGuest: false,
          email: 'zayd@example.com',
          displayName: 'Zayd Khan',
        ),
      ),
    );
    when(auth.signOut).thenAnswer((_) async => const Ok(null));
    final player = _Player();
    when(() => player.playerStateStream).thenAnswer((_) => const Stream.empty());
    when(() => player.playbackEventStream).thenAnswer((_) => const Stream.empty());
    when(() => player.currentIndexStream).thenAnswer((_) => const Stream.empty());
    final connectivity = _Connectivity();
    when(() => connectivity.onConnectivityChanged).thenAnswer((_) => const Stream.empty());
    when(connectivity.checkConnectivity).thenAnswer((_) async => [ConnectivityResult.wifi]);
    final connectivityService = ConnectivityService(connectivity);
    Get
      ..put<AuthRepository>(auth, permanent: true)
      ..put(connectivityService, permanent: true)
      ..put(AudioService(connectivityService, player), permanent: true)
      ..put(settings, permanent: true)
      ..put(quran, permanent: true);
    InitialBinding(appSupportDir: dir).dependencies();
    expect(Get.find<LearnService>().progress.completed, hasLength(6));

    await tester.pumpWidget(
      RepaintBoundary(
        key: _key,
        child: GetMaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          translations: AppTranslations(),
          locale: const Locale('en'),
          getPages: AppPages.routes,
          initialRoute: AppRoutes.home,
        ),
      ),
    );
    Directory(_out).createSync(recursive: true);

    Future<void> settle() async {
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
      await tester.pump(const Duration(milliseconds: 250));
    }

    Future<void> shot(String name) async {
      await settle();
      await tester.runAsync(() async {
        final b = _key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final img = await b.toImage(pixelRatio: 2.625);
        final png = await img.toByteData(format: ui.ImageByteFormat.png);
        File('$_out/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
      });
    }

    await shot('1_home');
    for (final (name, route, args) in [
      ('2_prayer', AppRoutes.prayerTimes, null),
      ('3_quran', AppRoutes.quran, null),
      ('4_reader', AppRoutes.surah, (surah: 36, ayah: null)),
      ('5_learn', AppRoutes.learn, null),
      ('6_profile', AppRoutes.more, null),
    ]) {
      unawaited(Get.toNamed<void>(route, arguments: args));
      await shot(name);
    }
    expect(File('$_out/6_profile.png').existsSync(), isTrue);
  });
}
