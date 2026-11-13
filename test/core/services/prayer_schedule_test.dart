import 'package:flutter_test/flutter_test.dart';
import 'package:quran_pro/core/errors/result.dart';
import 'package:quran_pro/core/services/prayer_schedule_service.dart';
import 'package:quran_pro/data/datasources/local/prayer_calc_local_ds.dart';
import 'package:quran_pro/data/models/day_prayer_times.dart';
import 'package:quran_pro/data/models/prayer.dart';
import 'package:quran_pro/data/models/prayer_alert_settings.dart';
import 'package:quran_pro/data/models/prayer_settings.dart';
import 'package:quran_pro/data/models/user_location.dart';
import 'package:quran_pro/data/repositories/prayer_times_repository_impl.dart';

void main() {
  const repo = PrayerTimesRepositoryImpl(PrayerCalcLocalDataSource());
  const karachi = UserLocation(24.86, 67.01);
  const method = PrayerSettings(method: 'karachi');
  // Just after Dhuhr (derived, so the test holds in any host time zone): Asr, Maghrib, Isha remain.
  final noon = (repo.timesFor(DateTime(2026, 3, 15), karachi, method) as Ok<DayPrayerTimes>)
      .value
      .times[Prayer.dhuhr]!
      .add(const Duration(minutes: 1));

  List<({int id, String title, String body, DateTime at, AzanSound sound})> build(
    PrayerAlertSettings prefs, {
    UserLocation? at = karachi,
    PrayerSettings settings = method,
  }) => PrayerScheduleService.buildAlerts(
    prayers: repo,
    location: at,
    method: settings,
    prefs: prefs,
    now: noon,
    days: 3,
  );

  test('schedules only future prayers, 5 a day, with stable unique ids', () {
    final alerts = build(const PrayerAlertSettings());
    expect(alerts.length, 3 + 5 + 5); // today: Asr, Maghrib, Isha
    expect(alerts.every((a) => a.at.isAfter(noon)), isTrue);
    expect(alerts.map((a) => a.id).toSet().length, alerts.length);
    expect(build(const PrayerAlertSettings()).map((a) => a.id), alerts.map((a) => a.id));
  });

  test("disabled prayers are left out; each alert carries its prayer's sound", () {
    final prefs = const PrayerAlertSettings()
        .withEnabled(Prayer.fajr, on: false)
        .withSound(Prayer.isha, AzanSound.hamtramck)
        .withSound(Prayer.maghrib, AzanSound.system);
    final alerts = build(prefs);
    expect(alerts.where((a) => a.title == Prayer.fajr.labelKey), isEmpty);
    expect(alerts.length, 3 + 4 + 4);
    for (final a in alerts) {
      final expected = switch (a.title) {
        'prayer_isha' => AzanSound.hamtramck,
        'prayer_maghrib' => AzanSound.system,
        _ => AzanSound.fallback,
      };
      expect(a.sound, expected, reason: a.title);
    }
  });

  test('times follow the calculation method; no location means nothing scheduled', () {
    final mwl = build(const PrayerAlertSettings(), settings: const PrayerSettings());
    final kar = build(const PrayerAlertSettings());
    final ishaMwl = mwl.firstWhere((a) => a.title == 'prayer_isha').at;
    final ishaKar = kar.firstWhere((a) => a.title == 'prayer_isha').at;
    expect(ishaMwl, isNot(ishaKar)); // Karachi uses 18° for Isha, MWL 17°
    expect(build(const PrayerAlertSettings(), at: null), isEmpty);
  });
}
