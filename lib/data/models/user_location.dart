import 'package:equatable/equatable.dart';

final class UserLocation extends Equatable {
  const UserLocation(this.lat, this.lng);

  /// ~1 km precision: accurate enough for prayer times, avoids storing a precise home location.
  factory UserLocation.rounded(double lat, double lng) => UserLocation(_r(lat), _r(lng));

  factory UserLocation.fromJson(Map<String, dynamic> json) =>
      UserLocation((json['lat'] as num).toDouble(), (json['lng'] as num).toDouble());

  final double lat;
  final double lng;

  static double _r(double v) => (v * 100).roundToDouble() / 100;

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng};

  @override
  List<Object> get props => [lat, lng];
}
