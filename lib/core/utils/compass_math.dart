/// Angle helpers on the 0–360° circle.
abstract final class CompassMath {
  /// Signed shortest turn from [from] to [to], in (-180, 180]; positive = turn clockwise (right).
  static double turn(double from, double to) {
    final d = (to - from) % 360; // Dart's % is non-negative for a positive divisor
    return d > 180 ? d - 360 : d;
  }

  /// Low-pass filter that follows the shortest way round (359° → 1° moves 2°, not 358°).
  static double smooth(double? previous, double next, {double alpha = 0.25}) =>
      previous == null ? next % 360 : (previous + turn(previous, next) * alpha) % 360;

  static const _points = [
    'N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE', //
    'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW',
  ];

  /// 16-point compass label, e.g. 119° → ESE.
  static String cardinal(double degrees) => _points[((degrees % 360) / 22.5).round() % 16];
}
