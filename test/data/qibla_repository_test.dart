import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:geomag/geomag.dart';
import 'package:quran_pro/core/errors/result.dart';
import 'package:quran_pro/data/datasources/local/prayer_calc_local_ds.dart';
import 'package:quran_pro/data/datasources/local/qibla_local_ds.dart';
import 'package:quran_pro/data/datasources/local/wmm2025.dart';
import 'package:quran_pro/data/models/user_location.dart';
import 'package:quran_pro/data/repositories/qibla_repository_impl.dart';
import 'package:quran_pro/domain/repositories/qibla_repository.dart';

void main() {
  const ds = QiblaLocalDataSource();
  const repo = QiblaRepositoryImpl(PrayerCalcLocalDataSource(), ds);

  // NOAA's official WMM2025 test rows: decimal year, altitude km, lat, lng, declination, ...
  final rows = File('test/fixtures/wmm2025_test_values.txt')
      .readAsLinesSync()
      .where((l) => l.trim().isNotEmpty && !l.startsWith('#'))
      .map((l) => l.trim().split(RegExp(r'\s+')).map(double.parse).toList())
      .toList();
  DateTime at(double decimalYear) {
    final y = decimalYear.floor();
    final len = DateTime.utc(y + 1).difference(DateTime.utc(y)).inSeconds;
    return DateTime.utc(y).add(Duration(seconds: ((decimalYear - y) * len).round()));
  }

  test('bundled WMM2025 coefficients reproduce all 100 NOAA test values (2025-2030)', () {
    final wmm = GeoMag.fromWmmCof(WmmCof.fromString(wmm2025Cof));
    expect(rows, hasLength(100));
    for (final r in rows) {
      final dec = wmm.calculate(r[2], r[3], r[1] * 3280.8399, at(r[0])).dec; // km -> feet
      expect(dec, closeTo(r[4], 0.05), reason: '$r');
    }
  });

  test('app declination (sea level) matches the NOAA sea-level row', () {
    final r = rows.firstWhere((r) => r[1] == 0);
    expect(ds.declination(UserLocation(r[2], r[3]), at(r[0])), closeTo(r[4], 0.05));
  });

  test('distance to the Kaaba: zero at the Kaaba, known city distances', () {
    expect(ds.distanceKm(kaabaLocation), closeTo(0, 1e-6));
    expect(ds.distanceKm(const UserLocation(51.5074, -0.1278)), closeTo(4790, 15)); // London
    expect(ds.distanceKm(const UserLocation(24.8607, 67.0011)), closeTo(2810, 15)); // Karachi
  });

  test('bearing is the same adhan value the Home screen uses; bad input is a Failure', () {
    final info =
        (repo.infoFor(const UserLocation(51.5074, -0.1278), DateTime(2026)) as Ok<QiblaInfo>).value;
    expect(info.bearing, closeTo(118.99, 0.1)); // London → Makkah, ESE
    expect(repo.infoFor(const UserLocation(123, 0), DateTime(2026)), isA<Err<QiblaInfo>>());
  });
}
