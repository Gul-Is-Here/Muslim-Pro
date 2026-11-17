import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:quran_pro/app/routes/app_routes.dart';
import 'package:quran_pro/core/localization/app_translations.dart';
import 'package:quran_pro/features/splash/bindings/splash_binding.dart';
import 'package:quran_pro/features/splash/viewmodels/splash_view_model.dart';
import 'package:quran_pro/features/splash/views/splash_view.dart';

void main() {
  tearDown(Get.reset);

  for (final (name, size, ratio) in [
    ('Pixel 7 Pro', const Size(1080, 2340), 2.625),
    ('small phone', const Size(720, 1280), 2.0),
  ]) {
    testWidgets('shows the brand on $name, then moves on to Home', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en'),
          initialRoute: AppRoutes.splash,
          getPages: [
            GetPage(
              name: AppRoutes.splash,
              page: () => const SplashView(),
              binding: SplashBinding(), // the real one: it must create the ViewModel itself
            ),
            GetPage(name: AppRoutes.home, page: () => const Text('home')),
          ],
        ),
      );
      await tester.pump(const Duration(milliseconds: 1500)); // entrance finished
      expect(find.text('NOOR'), findsOneWidget);
      expect(find.text('A SANCTUARY FOR THE SOUL'), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(find.text('home'), findsNothing);

      await tester.pump(const Duration(seconds: 1)); // 2.5 s: past the 2.2 s hold
      await tester.pump(const Duration(seconds: 1)); // route transition
      expect(find.text('home'), findsOneWidget);
      expect(Get.isRegistered<SplashViewModel>(), isFalse, reason: 'splash is disposed');
    });
  }
}
