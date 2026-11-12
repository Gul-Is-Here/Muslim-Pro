import 'package:equatable/equatable.dart';

final class PrayerSettings extends Equatable {
  const PrayerSettings({this.method = 'muslim_world_league', this.hanafiAsr = false});

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
