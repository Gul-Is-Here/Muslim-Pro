import 'dart:async';

import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:geocoding/geocoding.dart';
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
    } on TimeoutException {
      // No fresh fix in time (indoors, right after the permission prompt, or a Simulator
      // with no location set): an older OS-cached fix is fine for prayer times.
      AppLog.w('Location fix timed out; using last known position');
      final last = await Geolocator.getLastKnownPosition();
      return last == null ? null : UserLocation.rounded(last.latitude, last.longitude);
    } on Exception catch (e, s) {
      AppLog.e(e, s);
      return null;
    }
  }

  /// City and country for [at] from the phone's own geocoder (Android Geocoder / iOS CLGeocoder:
  /// no API key, but it needs a network connection). Nulls when unavailable.
  Future<({String? name, String? countryCode})> lookupPlace(UserLocation at) async {
    try {
      final marks = await Geocoding()
          .placemarkFromCoordinates(at.lat, at.lng)
          .timeout(const Duration(seconds: 8));
      if (marks.isEmpty) return (name: null, countryCode: null);
      final m = marks.first;
      String? nonEmpty(String? s) => s == null || s.trim().isEmpty ? null : s.trim();
      return (
        name:
            nonEmpty(m.locality) ??
            nonEmpty(m.subAdministrativeArea) ??
            nonEmpty(m.administrativeArea),
        countryCode: nonEmpty(m.isoCountryCode),
      );
    } on Exception catch (e) {
      AppLog.w('Place lookup failed: ${e.runtimeType}'); // offline is normal: keep the cached place
      return (name: null, countryCode: null);
    }
  }

  Future<String?> timeZoneId() async {
    try {
      return (await FlutterTimezone.getLocalTimezone()).identifier;
    } on Exception catch (e, s) {
      AppLog.e(e, s);
      return null;
    }
  }

  Future<bool> openAppSettings() => Geolocator.openAppSettings();
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
}
