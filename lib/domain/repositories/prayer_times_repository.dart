import 'package:quran_pro/core/errors/result.dart';
import 'package:quran_pro/data/models/day_prayer_times.dart';
import 'package:quran_pro/data/models/prayer_settings.dart';
import 'package:quran_pro/data/models/user_location.dart';

abstract interface class PrayerTimesRepository {
  Result<DayPrayerTimes> timesFor(DateTime day, UserLocation at, PrayerSettings settings);
  Result<double> qiblaFor(UserLocation at);
}
