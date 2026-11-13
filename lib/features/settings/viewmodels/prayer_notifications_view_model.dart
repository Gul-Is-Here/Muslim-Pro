import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:quran_pro/core/errors/result.dart';
import 'package:quran_pro/core/services/audio_service.dart';
import 'package:quran_pro/core/services/notification_service.dart';
import 'package:quran_pro/core/services/prayer_schedule_service.dart';
import 'package:quran_pro/core/services/settings_service.dart';
import 'package:quran_pro/core/utils/formatters.dart';
import 'package:quran_pro/data/models/prayer.dart';
import 'package:quran_pro/data/models/prayer_alert_settings.dart';
import 'package:quran_pro/domain/repositories/prayer_times_repository.dart';

/// Edits reminder preferences only. Scheduling itself lives in [PrayerScheduleService], which
/// reacts to every saved change whether or not this screen is open.
final class PrayerNotificationsViewModel extends GetxController {
  PrayerNotificationsViewModel(
    this._settings,
    this._notifications,
    this._schedule,
    this._audio,
    this._prayers,
  );

  final SettingsService _settings;
  final NotificationService _notifications;
  final PrayerScheduleService _schedule;
  final AudioService _audio;
  final PrayerTimesRepository _prayers;

  late final Rx<PrayerAlertSettings> _prefs = _settings.prayerAlertSettings.obs;
  final RxnBool _allowed = RxnBool(); // null until checked
  final RxBool _exact = true.obs;
  AppLifecycleListener? _lifecycle;

  bool get masterOn => _settings.prayerAlertsOn;
  bool get showBlocked => masterOn && _allowed.value == false;
  bool get showExactHint => GetPlatform.isAndroid && masterOn && !showBlocked && !_exact.value;
  bool get isAndroid => GetPlatform.isAndroid;
  bool isOn(Prayer p) => _prefs.value.isOn(p);
  AzanSound soundOf(Prayer p) => _prefs.value.soundFor(p);

  @override
  void onInit() {
    super.onInit();
    _lifecycle = AppLifecycleListener(
      onResume: () => unawaited(_refreshPermissions()), // back from system Settings
      onHide: stopPreview,
    );
    unawaited(_refreshPermissions());
  }

  /// Next occurrence of [p] ("Today, 5:10 AM"), or null until a location is known.
  String? nextTimeLabel(Prayer p) {
    final loc = _settings.lastLocation;
    if (loc == null) return null;
    final now = DateTime.now();
    for (var d = 0; d < 2; d++) {
      final day = DateTime(now.year, now.month, now.day + d);
      if (_prayers.timesFor(day, loc, _settings.prayerSettings) case Ok(:final value)) {
        final at = value.times[p]!;
        if (at.isAfter(now)) {
          return (d == 0 ? 'today_at' : 'tomorrow_at').trParams({'time': Formatters.clock(at)});
        }
      }
    }
    return null;
  }

  Future<void> setMaster({required bool on}) async {
    if (on) await _ensurePermission();
    await _settings.setPrayerAlerts(on: on);
  }

  Future<void> setPrayerOn(Prayer p, {required bool on}) async {
    if (on && masterOn) await _ensurePermission();
    await _save(_prefs.value.withEnabled(p, on: on));
  }

  Future<void> setSound(Prayer p, AzanSound sound) => _save(_prefs.value.withSound(p, sound));

  AudioStatus previewStatus(AzanSound s) => _audio.statusOf(_previewId(s));

  /// One preview at a time: the app-wide player replaces whatever was playing.
  Future<void> togglePreview(AzanSound s) =>
      _audio.toggle(_previewId(s), Uri.parse('asset:///${s.previewAsset}'));

  void stopPreview() {
    if (_audio.trackId?.startsWith(_previewPrefix) ?? false) unawaited(_audio.stop());
  }

  /// Plays [s] through a real notification, so users hear it with their own volume/DND settings.
  Future<void> sendTest(AzanSound s) async {
    stopPreview();
    await _ensurePermission();
    if (_allowed.value != true) return;
    await _notifications.showTestAlert(
      s,
      title: 'test_alert_title'.tr,
      body: 'test_alert_body'.trParams({'sound': s.labelKey.tr}),
    );
  }

  Future<void> openAppSettings() => _notifications.openAppSettings();
  Future<void> allowExactAlarms() => _notifications.requestExactAlarms(); // result read on resume

  static const _previewPrefix = 'azan-preview:';
  String _previewId(AzanSound s) => '$_previewPrefix${s.name}';

  Future<void> _save(PrayerAlertSettings s) {
    _prefs.value = s;
    return _settings.setPrayerAlertSettings(s); // PrayerScheduleService reschedules on change
  }

  Future<void> _ensurePermission() async {
    _allowed.value =
        await _notifications.notificationsAllowed() || await _notifications.requestPermission();
  }

  Future<void> _refreshPermissions() async {
    _allowed.value = await _notifications.notificationsAllowed();
    final exact = await _notifications.exactAlarmsAllowed();
    if (exact && !_exact.value) unawaited(_schedule.reschedule()); // upgrade inexact alarms
    _exact.value = exact;
  }

  @override
  void onClose() {
    stopPreview();
    _lifecycle?.dispose();
    super.onClose();
  }
}
