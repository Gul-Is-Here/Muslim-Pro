import 'package:equatable/equatable.dart';

final class PrayerSettings extends Equatable {
  const PrayerSettings({this.method = 'muslim_world_league', this.hanafiAsr = false});

  /// The convention most local mosques use in [countryCode] (ISO alpha-2). Applied until the user
  /// picks a method; unknown countries get Muslim World League.
  factory PrayerSettings.forCountry(String? countryCode) => switch (countryCode?.toUpperCase()) {
    'PK' || 'IN' || 'BD' || 'AF' => const PrayerSettings(method: 'karachi', hanafiAsr: true),
    'SA' => const PrayerSettings(method: 'umm_al_qura'),
    'AE' => const PrayerSettings(method: 'dubai'),
    'KW' => const PrayerSettings(method: 'kuwait'),
    'QA' => const PrayerSettings(method: 'qatar'),
    'EG' => const PrayerSettings(method: 'egyptian'),
    'TR' => const PrayerSettings(method: 'turkey'),
    'IR' => const PrayerSettings(method: 'tehran'),
    'SG' || 'MY' || 'ID' || 'BN' => const PrayerSettings(method: 'singapore'),
    'US' || 'CA' => const PrayerSettings(method: 'north_america'),
    _ => const PrayerSettings(),
  };

  factory PrayerSettings.fromJson(Map<String, dynamic> json) => PrayerSettings(
    method: json['method'] as String? ?? 'muslim_world_league',
    hanafiAsr: json['hanafiAsr'] as bool? ?? false,
  );

  /// Name of an adhan `CalculationMethod` value, e.g. 'karachi', 'umm_al_qura'.
  final String method;
  final bool hanafiAsr;

  Map<String, dynamic> toJson() => {'method': method, 'hanafiAsr': hanafiAsr};

  PrayerSettings copyWith({String? method, bool? hanafiAsr}) =>
      PrayerSettings(method: method ?? this.method, hanafiAsr: hanafiAsr ?? this.hanafiAsr);

  @override
  List<Object> get props => [method, hanafiAsr];
}

/// Offline country guess from the device time zone, used until a geocoder lookup succeeds.
/// Only zones whose country has a non-default method are listed.
String? countryForTimeZone(String? zone) => switch (zone) {
  'Asia/Karachi' => 'PK',
  'Asia/Kolkata' || 'Asia/Calcutta' => 'IN',
  'Asia/Dhaka' => 'BD',
  'Asia/Kabul' => 'AF',
  'Asia/Riyadh' => 'SA',
  'Asia/Dubai' => 'AE',
  'Asia/Kuwait' => 'KW',
  'Asia/Qatar' => 'QA',
  'Africa/Cairo' => 'EG',
  'Europe/Istanbul' => 'TR',
  'Asia/Tehran' => 'IR',
  'Asia/Singapore' => 'SG',
  'Asia/Kuala_Lumpur' => 'MY',
  'Asia/Jakarta' => 'ID',
  _ => null,
};
