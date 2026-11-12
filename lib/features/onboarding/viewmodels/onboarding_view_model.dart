import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:quran_pro/app/routes/app_routes.dart';
import 'package:quran_pro/core/services/notification_service.dart';
import 'package:quran_pro/core/services/settings_service.dart';

final class OnboardingViewModel extends GetxController {
  OnboardingViewModel(this._settings, this._notifications);

  static const pageCount = 3;

  final SettingsService _settings;
  final NotificationService _notifications;

  final pageController = PageController();
  final RxInt _page = 0.obs;

  int get page => _page.value;
  bool get isLast => _page.value == pageCount - 1;

  // ignore: use_setters_to_change_properties, passed as a PageView callback tear-off
  void onPageChanged(int index) => _page.value = index;

  void next() {
    if (isLast) {
      unawaited(finish());
      return;
    }
    pageController.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  /// Called from the page that explains the azan alerts (the rationale).
  Future<void> enableNotifications() => _notifications.requestPermission();

  Future<void> finish() async {
    await _settings.completeOnboarding();
    unawaited(Get.offAllNamed<void>(AppRoutes.home)); // AuthMiddleware takes over
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
