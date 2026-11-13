import 'package:equatable/equatable.dart';
import 'package:quran_pro/data/models/user_location.dart';

/// Human name and country for a stored location, cached so it shows offline.
final class SavedPlace extends Equatable {
  const SavedPlace({required this.at, required this.name, this.countryCode});

  factory SavedPlace.fromJson(Map<String, dynamic> json) => SavedPlace(
    at: UserLocation.fromJson((json['at'] as Map).cast<String, dynamic>()),
    name: json['name'] as String? ?? '',
    countryCode: json['country'] as String?,
  );

  /// Where the name was looked up.
  final UserLocation at;

  /// City/town, or empty when the lookup failed (offline, no geocoder).
  final String name;

  /// ISO 3166 alpha-2, e.g. 'PK'. From the geocoder, else guessed from the time zone.
  final String? countryCode;

  /// Still describes [loc]: within ~5 km of where it was looked up.
  bool describes(UserLocation loc) =>
      (at.lat - loc.lat).abs() < 0.05 && (at.lng - loc.lng).abs() < 0.05;

  Map<String, dynamic> toJson() => {'at': at.toJson(), 'name': name, 'country': countryCode};

  @override
  List<Object?> get props => [at, name, countryCode];
}
