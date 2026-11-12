import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:quran_pro/app/routes/app_routes.dart';
import 'package:quran_pro/core/services/auth_service.dart';
import 'package:quran_pro/core/services/settings_service.dart';

final class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    if (!Get.find<SettingsService>().onboardingDone) {
      return const RouteSettings(name: AppRoutes.onboarding);
    }
    if (!Get.find<AuthService>().isSignedIn) return const RouteSettings(name: AppRoutes.auth);
    return null;
  }
}
