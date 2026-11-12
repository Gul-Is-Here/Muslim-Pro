import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:quran_pro/core/localization/app_translations.dart';
import 'package:quran_pro/data/models/prayer_settings.dart';
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
  static const _kLocation = 'lastLocation';

  Locale get locale =>
      AppTranslations.resolve(_box.read<String>(_kLang) ?? Get.deviceLocale?.languageCode);
  ThemeMode get themeMode =>
      ThemeMode.values.asNameMap()[_box.read<String>(_kTheme)] ??
      ThemeMode.light; // design is light-first
  bool get onboardingDone => _box.read<bool>(_kOnboarded) ?? false;
  bool get prayerAlertsOn => _box.read<bool>(_kAlerts) ?? true;

  PrayerSettings get prayerSettings {
    final json = _box.read<Map<String, dynamic>>(_kPrayer);
    return json == null ? const PrayerSettings() : PrayerSettings.fromJson(json);
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
  Future<void> setPrayerAlerts({required bool on}) => _savePrayerInput(_kAlerts, on);
  Future<void> setLastLocation(UserLocation l) => _savePrayerInput(_kLocation, l.toJson());

  Future<void> _savePrayerInput(String key, Object value) async {
    await _box.write(key, value);
    _prayerInputs.value++;
  }
}
