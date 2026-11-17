import 'package:quran_pro/core/errors/failure.dart';
import 'package:quran_pro/core/errors/result.dart';
import 'package:quran_pro/core/utils/app_log.dart';
import 'package:quran_pro/data/datasources/local/prayer_calc_local_ds.dart';
import 'package:quran_pro/data/models/day_prayer_times.dart';
import 'package:quran_pro/data/models/prayer_settings.dart';
import 'package:quran_pro/data/models/user_location.dart';
import 'package:quran_pro/domain/repositories/prayer_times_repository.dart';

final class PrayerTimesRepositoryImpl implements PrayerTimesRepository {
  const PrayerTimesRepositoryImpl(this._calc);

  final PrayerCalcLocalDataSource _calc;

  @override
  Result<DayPrayerTimes> timesFor(DateTime day, UserLocation at, PrayerSettings settings) {
    try {
      return Ok(_calc.compute(day, at, settings));
      // ignore: avoid_catching_errors, adhan signals bad input with ArgumentError
    } on ArgumentError catch (e, s) {
      AppLog.e(e, s);
      return const Err(Failure('invalid-location'));
    }
  }

  @override
  Result<double> qiblaFor(UserLocation at) {
    try {
      return Ok(_calc.qiblaBearing(at));
      // ignore: avoid_catching_errors, adhan signals bad input with ArgumentError
    } on ArgumentError catch (e, s) {
      AppLog.e(e, s);
      return const Err(Failure('invalid-location'));
    }
  }
}
