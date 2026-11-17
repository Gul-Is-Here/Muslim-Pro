import 'dart:async';

import 'package:get/get.dart';
import 'package:quran_pro/core/services/location_service.dart';
import 'package:quran_pro/core/services/settings_service.dart';
import 'package:quran_pro/data/models/prayer_settings.dart';
import 'package:quran_pro/data/models/saved_place.dart';

/// Keeps the stored location (and its place name/country) current. Shared by every screen that
/// needs the user's position, so a refresh from one updates all of them.
final class LocationSyncService extends GetxService {
  LocationSyncService(this._location, this._settings);

  final LocationService _location;
  final SettingsService _settings;
  Future<LocationAccess>? _running;

  /// Fresh GPS fix (when permitted) saved over the cached one, then its place looked up.
  /// Concurrent callers share one run. Returns the permission state so screens can prompt.
  Future<LocationAccess> sync() => _running ??= _sync().whenComplete(() => _running = null);

  Future<LocationAccess> _sync() async {
    final access = await _location.status();
    if (access == LocationAccess.granted) {
      final fresh = await _location.current();
      // Saving triggers prayer-time recompute and alert rescheduling.
      if (fresh != null && fresh != _settings.lastLocation) await _settings.setLastLocation(fresh);
    }
    final loc = _settings.lastLocation;
    final known = _settings.lastPlace;
    if (loc == null || (known != null && known.describes(loc) && known.name.isNotEmpty)) {
      return access; // nothing to look up, or the cached name still fits
    }
    final found = await _location.lookupPlace(loc);
    final country =
        found.countryCode ??
        (known != null && known.describes(loc) ? known.countryCode : null) ??
        countryForTimeZone(await _location.timeZoneId());
    final place = SavedPlace(at: loc, name: found.name ?? '', countryCode: country);
    if (place != known) await _settings.setLastPlace(place);
    return access;
  }
}
