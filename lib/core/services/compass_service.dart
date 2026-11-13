import 'package:flutter_compass/flutter_compass.dart';
import 'package:get/get.dart';

/// Device headings in degrees clockwise from TRUE north.
/// `flat`: where the top of the phone points (held flat). `camera`: where the back camera points
/// (held upright). `accuracy`: ± degrees, null when unknown.
typedef Heading = ({double? flat, double? camera, double? accuracy});

final class CompassService extends GetxService {
  /// False when the device has no compass sensor.
  bool get available => FlutterCompass.events != null;

  /// [declination] (east-positive) converts magnetic readings to true north.
  /// What flutter_compass 0.8.1 actually reports (read from its sources):
  /// - Android: `heading` is magnetic; the plugin itself remaps axes once the phone is tilted
  ///   upright, so the same value then follows the back camera. `headingForCameraMode` is never
  ///   set (always 0) and must not be used. Accuracy is a coarse 15/30/45° bucket.
  /// - iOS: `heading` is CoreLocation's true heading (-1 until it has a location fix);
  ///   `headingForCameraMode` is magnetic (CoreMotion xMagneticNorthZVertical).
  Stream<Heading>? headings(double Function() declination) => FlutterCompass.events?.map((e) {
    final d = declination();
    double? norm(double? v) => v == null ? null : v % 360;
    if (GetPlatform.isIOS) {
      final flat = e.heading;
      final cam = e.headingForCameraMode;
      return (
        flat: flat == null || flat < 0 ? null : norm(flat),
        camera: cam == null ? null : norm(cam + d),
        accuracy: e.accuracy,
      );
    }
    final h = e.heading == null ? null : norm(e.heading! + d);
    return (flat: h, camera: h, accuracy: e.accuracy);
  });
}
