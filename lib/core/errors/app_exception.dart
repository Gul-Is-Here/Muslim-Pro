/// Thrown by datasources only, carrying a backend-neutral error code.
final class AppException implements Exception {
  const AppException(this.code);

  final String code;

  static const cancelled = 'cancelled';
  static const unknown = 'unknown';

  @override
  String toString() => 'AppException($code)';
}
