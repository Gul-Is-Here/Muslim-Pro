import 'dart:math' as math;

import 'package:geomag/geomag.dart';
import 'package:quran_pro/data/datasources/local/wmm2025.dart';
import 'package:quran_pro/data/models/user_location.dart';
import 'package:quran_pro/domain/repositories/qibla_repository.dart';

final class QiblaLocalDataSource {
  const QiblaLocalDataSource();

  static final GeoMag _wmm = GeoMag.fromWmmCof(WmmCof.fromString(wmm2025Cof));

  /// Great-circle (haversine) distance to the Kaaba in km.
  double distanceKm(UserLocation from) {
    const r = 6371.0088; // mean Earth radius
    double rad(double d) => d * math.pi / 180;
    final dLat = rad(kaabaLocation.lat - from.lat);
    final dLng = rad(kaabaLocation.lng - from.lng);
    final a =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(from.lat)) *
            math.cos(rad(kaabaLocation.lat)) *
            math.pow(math.sin(dLng / 2), 2);
    return 2 * r * math.asin(math.sqrt(a));
  }

  /// Magnetic declination (degrees, east positive) from the World Magnetic Model 2025:
  /// true heading = magnetic heading + declination.
  double declination(UserLocation at, DateTime when) =>
      _wmm.calculate(at.lat, at.lng, 0, when.toUtc()).dec;
}
