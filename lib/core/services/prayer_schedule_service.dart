import 'dart:async';

import 'package:get/get.dart';
import 'package:quran_pro/core/errors/result.dart';
import 'package:quran_pro/core/services/notification_service.dart';
import 'package:quran_pro/core/services/settings_service.dart';
import 'package:quran_pro/core/utils/app_log.dart';
import 'package:quran_pro/data/models/prayer.dart';
import 'package:quran_pro/domain/repositories/prayer_times_repository.dart';

/// Schedules azan alerts locally from adhan calculations, never from the server.
/// It reschedules on app start and whenever the location, method, madhab or alerts toggle changes.
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
        await _notifications.replacePrayerAlerts(_buildAlerts());
      } while (_again);
    } on Object catch (e, s) {
      AppLog.e(e, s);
    } finally {
      _running = false;
    }
  }

  List<PrayerAlert> _buildAlerts() {
    final loc = _settings.lastLocation;
    if (loc == null || !_settings.prayerAlertsOn) return const [];
    final now = DateTime.now();
    return [
      for (var d = 0; d < _days; d++)
        if (_prayers.timesFor(
              DateTime(now.year, now.month, now.day + d),
              loc,
              _settings.prayerSettings,
            )
            case Ok(:final value))
          for (final p in Prayer.obligatory)
            if (value.times[p]!.isAfter(now))
              (
                id: _id(value.date, p),
                title: p.labelKey.tr,
                body: 'prayer_alert_body'.trParams({'prayer': p.labelKey.tr}),
                at: value.times[p]!,
              ),
    ];
  }

  /// Stable per (day, prayer). UTC dates so DST shifts never collide two days.
  static int _id(DateTime day, Prayer p) =>
      DateTime.utc(day.year, day.month, day.day).difference(DateTime.utc(2024)).inDays * 10 +
      p.index;

  @override
  void onClose() {
    unawaited(_sub?.cancel());
    super.onClose();
  }
}
