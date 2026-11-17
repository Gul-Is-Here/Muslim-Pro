import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:quran_pro/core/localization/ar.dart';
import 'package:quran_pro/core/localization/en.dart';
import 'package:quran_pro/core/localization/ur.dart';

final class AppTranslations extends Translations {
  static const fallback = Locale('en', 'US');
  static const supported = [Locale('en', 'US'), Locale('ur', 'PK'), Locale('ar', 'SA')];

  static Locale resolve(String? languageCode) =>
      supported.firstWhere((l) => l.languageCode == languageCode, orElse: () => fallback);

  @override
  Map<String, Map<String, String>> get keys => const {'en_US': en, 'ur_PK': ur, 'ar_SA': ar};
}
