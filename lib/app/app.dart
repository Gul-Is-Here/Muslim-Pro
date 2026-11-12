import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:quran_pro/app/routes/app_pages.dart';
import 'package:quran_pro/core/localization/app_translations.dart';
import 'package:quran_pro/core/services/settings_service.dart';
import 'package:quran_pro/core/theme/app_theme.dart';
import 'package:quran_pro/core/widgets/offline_banner.dart';

final class App extends GetView<SettingsService> {
  const App({super.key});

  @override
  Widget build(BuildContext context) => GetMaterialApp(
    title: 'Quran Pro',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    themeMode: controller.themeMode, // changed at runtime via Get.changeThemeMode
    translations: AppTranslations(),
    locale: controller.locale, // changed at runtime via Get.updateLocale
    fallbackLocale: AppTranslations.fallback,
    supportedLocales: AppTranslations.supported,
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    initialRoute: AppPages.initial,
    getPages: AppPages.routes,
    builder: (context, child) => Column(
      children: [
        const OfflineBanner(),
        Expanded(child: child!),
      ],
    ),
  );
}
