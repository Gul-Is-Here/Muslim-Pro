import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:quran_pro/app/routes/app_routes.dart';
import 'package:quran_pro/core/services/location_service.dart';
import 'package:quran_pro/core/services/location_sync_service.dart';
import 'package:quran_pro/core/services/notification_service.dart';
import 'package:quran_pro/core/services/settings_service.dart';

enum OnboardingStep { welcome, location, alerts }

/// Welcome, then location, then notifications. Each permission can be skipped; nothing is
/// requested before its page has explained why.
final class OnboardingViewModel extends GetxController {
  OnboardingViewModel(this._settings, this._notifications, this._location, this._sync);

  final SettingsService _settings;
  final NotificationService _notifications;
  final LocationService _location;
  final LocationSyncService _sync;

  final RxInt _page = 0.obs;
  final Rxn<LocationAccess> _locationAccess = Rxn<LocationAccess>();
  final RxBool _alertsOn = false.obs;
  final RxBool _alertsAsked = false.obs;
  final RxBool _busy = false.obs;
  AppLifecycleListener? _lifecycle;

  int get page => _page.value;
  int get pageCount => OnboardingStep.values.length;
  OnboardingStep get step => OnboardingStep.values[_page.value];
  bool get busy => _busy.value;

  bool get locationGranted => _locationAccess.value == LocationAccess.granted;
  bool get alertsGranted => _alertsOn.value;

  /// Already asked and refused: the system will not ask again, so offer Settings.
  bool get alertsBlocked => _alertsAsked.value && !_alertsOn.value;

  /// Label of the main button for the current step.
  String get primaryLabelKey => switch (step) {
    OnboardingStep.welcome => 'continue',
    OnboardingStep.location => switch (_locationAccess.value) {
      LocationAccess.granted => 'continue',
      LocationAccess.permanentlyDenied => 'open_app_settings',
      LocationAccess.serviceDisabled => 'open_location_settings',
      _ => 'allow_location',
    },
    OnboardingStep.alerts =>
      alertsGranted
          ? 'get_started'
          : alertsBlocked
          ? 'open_app_settings'
          : 'onboarding_enable_alerts',
  };

  /// "Not now" only makes sense while a permission is still missing.
  bool get canSkip => switch (step) {
    OnboardingStep.welcome => false,
    OnboardingStep.location => !locationGranted,
    OnboardingStep.alerts => !alertsGranted,
  };

  Future<void> primary() async {
    if (_busy.value) return;
    _busy.value = true;
    try {
      switch (step) {
        case OnboardingStep.welcome:
          _next();
        case OnboardingStep.location:
          await _allowLocation();
        case OnboardingStep.alerts:
          await _enableAlerts();
      }
    } finally {
      _busy.value = false;
    }
  }

  void skip() => step == OnboardingStep.alerts ? unawaited(finish()) : _next();

  Future<void> _allowLocation() async {
    switch (_locationAccess.value) {
      case LocationAccess.granted:
        _next();
        return;
      case LocationAccess.permanentlyDenied:
        await _location.openAppSettings(); // re-checked when the app comes back
        return;
      case LocationAccess.serviceDisabled:
        await _location.openLocationSettings();
        return;
      case LocationAccess.denied || null:
        _locationAccess.value = await _location.request();
    }
    if (locationGranted) {
      unawaited(_sync.sync()); // first fix in the background: Home opens with prayer times
      _next();
    }
  }

  Future<void> _enableAlerts() async {
    if (alertsGranted) {
      await finish();
      return;
    }
    if (alertsBlocked) {
      await _notifications.openAppSettings();
      return;
    }
    _alertsOn.value = await _notifications.requestPermission();
    _alertsAsked.value = true;
    if (alertsGranted) await finish();
  }

  void _next() {
    if (_page.value < pageCount - 1) _page.value++;
  }

  Future<void> _refresh() async {
    _locationAccess.value = await _location.status();
    _alertsOn.value = await _notifications.notificationsAllowed();
  }

  Future<void> finish() async {
    await _settings.completeOnboarding();
    unawaited(Get.offAllNamed<void>(AppRoutes.home)); // AuthMiddleware takes over
  }

  @override
  void onInit() {
    super.onInit();
    // Returning from system Settings: pick up whatever the user changed there.
    _lifecycle = AppLifecycleListener(onResume: () => unawaited(_refresh()));
    unawaited(_refresh());
  }

  @override
  void onClose() {
    _lifecycle?.dispose();
    super.onClose();
  }
}
