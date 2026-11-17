import 'package:quran_pro/core/errors/failure.dart';
import 'package:quran_pro/core/errors/result.dart';
import 'package:quran_pro/core/utils/app_log.dart';
import 'package:quran_pro/data/datasources/local/prayer_calc_local_ds.dart';
import 'package:quran_pro/data/datasources/local/qibla_local_ds.dart';
import 'package:quran_pro/data/models/user_location.dart';
import 'package:quran_pro/domain/repositories/qibla_repository.dart';

final class QiblaRepositoryImpl implements QiblaRepository {
  const QiblaRepositoryImpl(this._calc, this._qibla);

  final PrayerCalcLocalDataSource _calc; // same adhan bearing the Home screen shows
  final QiblaLocalDataSource _qibla;

  @override
  Result<QiblaInfo> infoFor(UserLocation at, DateTime when) {
    try {
      return Ok((
        bearing: _calc.qiblaBearing(at),
        distanceKm: _qibla.distanceKm(at),
        declination: _qibla.declination(at, when),
      ));
      // ignore: avoid_catching_errors, adhan signals bad input with ArgumentError
    } on ArgumentError catch (e, s) {
      AppLog.e(e, s);
      return const Err(Failure('invalid-location'));
    }
  }
}
