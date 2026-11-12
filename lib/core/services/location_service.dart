import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:quran_pro/core/utils/app_log.dart';
import 'package:quran_pro/data/models/user_location.dart';

enum LocationAccess { granted, denied, permanentlyDenied, serviceDisabled }

final class LocationService extends GetxService {
  Future<LocationAccess> status() => _resolve(request: false);

  /// Call only after the rationale UI has been shown.
  Future<LocationAccess> request() => _resolve(request: true);

  Future<LocationAccess> _resolve({required bool request}) async {
    if (!await Geolocator.isLocationServiceEnabled()) return LocationAccess.serviceDisabled;
    var permission = await Geolocator.checkPermission();
    if (request && permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return switch (permission) {
      LocationPermission.always || LocationPermission.whileInUse => LocationAccess.granted,
      LocationPermission.deniedForever => LocationAccess.permanentlyDenied,
      _ => LocationAccess.denied,
    };
  }

  /// City-level fix: enough for prayer times, kinder to battery and privacy.
  Future<UserLocation?> current() async {
    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return UserLocation.rounded(p.latitude, p.longitude);
    } on Exception catch (e, s) {
      AppLog.e(e, s);
      return null;
    }
  }

  /// Coarse place label from the device time zone ("Asia/Karachi" → "Karachi"); no geocoding call.
  Future<String> approximatePlaceName() async {
    try {
      return (await FlutterTimezone.getLocalTimezone()).identifier
          .split('/')
          .last
          .replaceAll('_', ' ');
    } on Exception catch (e, s) {
      AppLog.e(e, s);
      return '';
    }
  }

  Future<bool> openAppSettings() => Geolocator.openAppSettings();
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
}
