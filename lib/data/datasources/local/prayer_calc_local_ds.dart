import 'package:adhan/adhan.dart' as adhan;
import 'package:quran_pro/data/models/day_prayer_times.dart';
import 'package:quran_pro/data/models/prayer.dart';
import 'package:quran_pro/data/models/prayer_settings.dart';
import 'package:quran_pro/data/models/user_location.dart';

final class PrayerCalcLocalDataSource {
  const PrayerCalcLocalDataSource();

  /// Compass bearing (degrees clockwise from north) to the Kaaba. Throws ArgumentError on bad input.
  double qiblaBearing(UserLocation at) =>
      adhan.Qibla(adhan.Coordinates(at.lat, at.lng, validate: true)).direction;

  /// Times are in the device's local time zone. Throws ArgumentError on bad input.
  DayPrayerTimes compute(DateTime day, UserLocation at, PrayerSettings s) {
    final params = adhan.CalculationMethod.values.byName(s.method).getParameters()
      ..madhab = s.hanafiAsr ? adhan.Madhab.hanafi : adhan.Madhab.shafi;
    final t = adhan.PrayerTimes(
      adhan.Coordinates(at.lat, at.lng, validate: true),
      adhan.DateComponents.from(day),
      params,
    );
    return DayPrayerTimes(
      date: DateTime(day.year, day.month, day.day),
      times: {
        Prayer.fajr: t.fajr,
        Prayer.sunrise: t.sunrise,
        Prayer.dhuhr: t.dhuhr,
        Prayer.asr: t.asr,
        Prayer.maghrib: t.maghrib,
        Prayer.isha: t.isha,
      },
    );
  }
}
