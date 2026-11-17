import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:quran_pro/core/errors/result.dart';
import 'package:quran_pro/core/services/notification_service.dart';
import 'package:quran_pro/core/services/settings_service.dart';
import 'package:quran_pro/core/utils/app_log.dart';
import 'package:quran_pro/data/models/prayer.dart';
import 'package:quran_pro/data/models/prayer_alert_settings.dart';
import 'package:quran_pro/data/models/prayer_settings.dart';
import 'package:quran_pro/data/models/user_location.dart';
import 'package:quran_pro/domain/repositories/prayer_times_repository.dart';

/// Schedules azan alerts locally from adhan calculations, never from the server.
/// App-wide (not tied to any screen): it reschedules on app start and whenever the location,
/// method, madhab, master switch, or a prayer's toggle/sound changes.
final class PrayerScheduleService extends GetxService {
  PrayerScheduleService(this._prayers, this._notifications, this._settings);

  final PrayerTimesRepository _prayers;
  final NotificationService _notifications;
  final SettingsService _settings;
  StreamSubscription<int>? _sub;
  bool _running = false;
  bool _again = false;

  // iOS keeps at most 64 pending notifications: 5 × 12 = 60 leaves room for reminders.
  // shortcut: the window only advances when the app opens; add a background refresh
  // (workmanager / BGTaskScheduler) if users report missing alerts after ~12 idle days.
  int get _days => GetPlatform.isIOS ? 12 : 30;

  @override
  void onReady() {
    super.onReady(); // after the first frame: translations are loaded
    _sub = _settings.prayerInputsChanged.listen((_) => unawaited(reschedule()));
    unawaited(reschedule());
  }

  Future<void> reschedule() async {
    if (_running) {
      _again = true; // coalesce bursts of changes into one extra pass
      return;
    }
    _running = true;
    try {
      do {
        _again = false;
        await _notifications.replacePrayerAlerts(
          _settings.prayerAlertsOn
              ? buildAlerts(
                  prayers: _prayers,
                  location: _settings.lastLocation,
                  method: _settings.prayerSettings,
                  prefs: _settings.prayerAlertSettings,
                  now: DateTime.now(),
                  days: _days,
                )
              : const [],
        );
      } while (_again);
    } on Object catch (e, s) {
      AppLog.e(e, s);
    } finally {
      _running = false;
    }
  }

  /// Alerts for every enabled prayer still ahead in the next [days] days, each with its sound.
  @visibleForTesting
  static List<PrayerAlert> buildAlerts({
    required PrayerTimesRepository prayers,
    required UserLocation? location,
    required PrayerSettings method,
    required PrayerAlertSettings prefs,
    required DateTime now,
    required int days,
  }) {
    if (location == null) return const [];
    return [
      for (var d = 0; d < days; d++)
        if (prayers.timesFor(DateTime(now.year, now.month, now.day + d), location, method) case Ok(
          :final value,
        ))
          for (final p in Prayer.obligatory)
            if (prefs.isOn(p) && value.times[p]!.isAfter(now))
              (
                id: _id(value.date, p),
                title: p.labelKey.tr,
                body: 'prayer_alert_body'.trParams({'prayer': p.labelKey.tr}),
                at: value.times[p]!,
                sound: prefs.soundFor(p),
              ),
    ];
  }

  /// Stable per (day, prayer), so rescheduling replaces rather than duplicates.
  /// UTC dates so DST shifts never collide two days.
  static int _id(DateTime day, Prayer p) =>
      DateTime.utc(day.year, day.month, day.day).difference(DateTime.utc(2024)).inDays * 10 +
      p.index;

  @override
  void onClose() {
    unawaited(_sub?.cancel());
    super.onClose();
  }
}
