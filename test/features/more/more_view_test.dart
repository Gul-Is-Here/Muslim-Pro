import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_pro/core/localization/app_translations.dart';
import 'package:quran_pro/core/services/auth_service.dart';
import 'package:quran_pro/core/services/learn_service.dart';
import 'package:quran_pro/core/services/quran_service.dart';
import 'package:quran_pro/core/services/settings_service.dart';
import 'package:quran_pro/core/services/surah_download_service.dart';
import 'package:quran_pro/core/theme/app_theme.dart';
import 'package:quran_pro/data/datasources/local/quran_audio_files.dart';
import 'package:quran_pro/data/models/app_user.dart';
import 'package:quran_pro/domain/repositories/auth_repository.dart';
import 'package:quran_pro/domain/repositories/learn_repository.dart';
import 'package:quran_pro/features/more/viewmodels/more_view_model.dart';
import 'package:quran_pro/features/more/views/more_view.dart';

class _Auth extends Mock implements AuthRepository;

class _Learn extends Mock implements LearnRepository;

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir = Directory.systemTemp.createTempSync('more_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => dir.path,
    );
    await GetStorage.init();
    await initializeDateFormatting();
  });

  tearDown(Get.reset);

  Future<void> pump(WidgetTester tester, AppUser user, Size size, double ratio) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = ratio;
    addTearDown(tester.view.reset);
    final auth = _Auth();
    when(auth.authStateChanges).thenAnswer((_) => Stream.value(user));
    final authService = Get.put(AuthService(auth));
    await authService.ready;
    final box = GetStorage();
    final quran = QuranService(box);
    for (final ayah in [1, 2, 3]) {
      quran.toggleBookmark((surah: 2, ayah: ayah));
    }
    Get.put(
      MoreViewModel(
        authService,
        SettingsService(box),
        LearnService(_Learn(), box),
        quran,
        SurahDownloadService(
          QuranAudioFiles(Directory.systemTemp.createTempSync('dl')),
          (s, a) => Uri(),
        ),
      ),
    );
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        translations: AppTranslations(),
        locale: const Locale('en'),
        home: const MoreView(),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final (name, size, ratio) in [
    ('Pixel 7 Pro', const Size(1080, 2340), 2.625),
    ('small phone', const Size(720, 1280), 2.0),
  ]) {
    testWidgets('signed in: name, email, stats and sign out ($name)', (tester) async {
      await pump(
        tester,
        const AppUser(uid: 'u1', isGuest: false, email: 'z@y.co', displayName: 'Zayd Khan'),
        size,
        ratio,
      );
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Zayd Khan'), findsOneWidget);
      expect(find.text('ZK'), findsOneWidget);
      expect(find.text('3'), findsOneWidget, reason: 'saved ayahs');
      expect(find.text('Sign in with an account'), findsNothing);
      await tester.scrollUntilVisible(
        find.text('Sign out'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Sign out'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('guest: sign-in call to action in the card, no sign out ($name)', (tester) async {
      await pump(tester, const AppUser(uid: 'g1', isGuest: true), size, ratio);
      expect(find.text('Guest'), findsOneWidget);
      expect(find.text('Sign in with an account'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Sources and credits'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Sign out'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
