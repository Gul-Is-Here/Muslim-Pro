import 'package:flutter_test/flutter_test.dart';
import 'package:quran_pro/core/errors/result.dart';
import 'package:quran_pro/data/datasources/local/prayer_calc_local_ds.dart';
import 'package:quran_pro/data/models/day_prayer_times.dart';
import 'package:quran_pro/data/models/prayer.dart';
import 'package:quran_pro/data/models/prayer_settings.dart';
import 'package:quran_pro/data/models/user_location.dart';
import 'package:quran_pro/data/repositories/prayer_times_repository_impl.dart';

void main() {
  const repo = PrayerTimesRepositoryImpl(PrayerCalcLocalDataSource());
  final day = DateTime(2026, 3, 15);

  test('times are in canonical order', () {
    final result = repo.timesFor(
      day,
      const UserLocation(24.86, 67.01),
      const PrayerSettings(method: 'karachi'),
    );
    final times = (result as Ok<DayPrayerTimes>).value.times;
    for (var i = 1; i < Prayer.values.length; i++) {
      expect(times[Prayer.values[i]]!.isAfter(times[Prayer.values[i - 1]]!), isTrue);
    }
  });

  test('invalid coordinates and unknown methods become Failures, not crashes', () {
    expect(
      repo.timesFor(day, const UserLocation(123, 0), const PrayerSettings()),
      isA<Err<DayPrayerTimes>>(),
    );
    expect(
      repo.timesFor(day, const UserLocation(24.86, 67.01), const PrayerSettings(method: 'nope')),
      isA<Err<DayPrayerTimes>>(),
    );
  });

  test('nextAfter returns null after Isha', () {
    final t = DayPrayerTimes(
      date: day,
      times: {for (final p in Prayer.values) p: day.add(Duration(hours: p.index))},
    );
    expect(t.nextAfter(day.add(const Duration(hours: 23))), isNull);
    expect(t.nextAfter(day.add(const Duration(minutes: 30)))?.prayer, Prayer.dhuhr);
  });
}
