import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:quran_pro/core/localization/app_translations.dart';
import 'package:quran_pro/data/models/prayer_alert_settings.dart';
import 'package:quran_pro/data/models/prayer_settings.dart';
import 'package:quran_pro/data/models/saved_place.dart';
import 'package:quran_pro/data/models/user_location.dart';

/// Device preferences (not user-scoped, not sensitive). Secrets never go here.
final class SettingsService extends GetxService {
  SettingsService(this._box);

  final GetStorage _box;
  final RxInt _prayerInputs = 0.obs;

  static const _kLang = 'lang';
  static const _kTheme = 'themeMode';
  static const _kOnboarded = 'onboarded';
  static const _kPrayer = 'prayerSettings';
  static const _kAlerts = 'prayerAlerts';
  static const _kAlertPrefs = 'prayerAlertPrefs';
  static const _kLocation = 'lastLocation';
  static const _kPlace = 'lastPlace';

  Locale get locale =>
      AppTranslations.resolve(_box.read<String>(_kLang) ?? Get.deviceLocale?.languageCode);
  ThemeMode get themeMode =>
      ThemeMode.values.asNameMap()[_box.read<String>(_kTheme)] ??
      ThemeMode.light; // design is light-first
  bool get onboardingDone => _box.read<bool>(_kOnboarded) ?? false;
  // Reactive so every screen showing the master switch (Home pill, settings) stays in sync.
  late final RxBool _alertsOn = (_box.read<bool>(_kAlerts) ?? true).obs;
  bool get prayerAlertsOn => _alertsOn.value;

  PrayerAlertSettings get prayerAlertSettings {
    final json = _box.read<Map<String, dynamic>>(_kAlertPrefs);
    return json == null ? const PrayerAlertSettings() : PrayerAlertSettings.fromJson(json);
  }

  /// The user's chosen method, else the usual one for the country they are in.
  PrayerSettings get prayerSettings {
    final json = _box.read<Map<String, dynamic>>(_kPrayer);
    return json == null
        ? PrayerSettings.forCountry(lastPlace?.countryCode)
        : PrayerSettings.fromJson(json);
  }

  // Reactive so place labels (Home, Qibla) update as soon as a lookup finishes.
  late final Rxn<SavedPlace> _place = Rxn<SavedPlace>(switch (_box.read<Map<String, dynamic>>(
    _kPlace,
  )) {
    final json? => SavedPlace.fromJson(json),
    null => null,
  });
  SavedPlace? get lastPlace => _place.value;

  /// City name for the stored location, or null when unknown or it describes another place.
  String? get placeName {
    final p = _place.value;
    final loc = lastLocation;
    return p != null && loc != null && p.describes(loc) && p.name.isNotEmpty ? p.name : null;
  }

  UserLocation? get lastLocation {
    final json = _box.read<Map<String, dynamic>>(_kLocation);
    return json == null ? null : UserLocation.fromJson(json);
  }

  /// Emits whenever an input to prayer-time calculation changes.
  Stream<int> get prayerInputsChanged => _prayerInputs.stream;

  Future<void> setLanguage(String code) async {
    await _box.write(_kLang, code);
    await Get.updateLocale(locale);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _box.write(_kTheme, mode.name);
    Get.changeThemeMode(mode);
  }

  Future<void> completeOnboarding() => _box.write(_kOnboarded, true);
  Future<void> setPrayerSettings(PrayerSettings s) => _savePrayerInput(_kPrayer, s.toJson());
  Future<void> setPrayerAlerts({required bool on}) {
    _alertsOn.value = on;
    return _savePrayerInput(_kAlerts, on);
  }

  Future<void> setPrayerAlertSettings(PrayerAlertSettings s) =>
      _savePrayerInput(_kAlertPrefs, s.toJson());
  Future<void> setLastLocation(UserLocation l) => _savePrayerInput(_kLocation, l.toJson());

  /// Also a prayer input: the country picks the default calculation method.
  Future<void> setLastPlace(SavedPlace p) {
    _place.value = p;
    return _savePrayerInput(_kPlace, p.toJson());
  }

  Future<void> _savePrayerInput(String key, Object value) async {
    await _box.write(key, value);
    _prayerInputs.value++;
  }
}
