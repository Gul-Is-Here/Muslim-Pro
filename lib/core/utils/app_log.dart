import 'package:logger/logger.dart';
import 'package:quran_pro/core/config/flavor_config.dart';

/// The only logging entry point (`avoid_print` is on). Never log PII: email, names, coordinates.
abstract final class AppLog {
  static final Logger _logger = Logger(
    level: switch (FlavorConfig.instance.flavor) {
      Flavor.dev => Level.debug,
      Flavor.staging => Level.warning,
      Flavor.prod => Level.off,
    },
    printer: PrettyPrinter(methodCount: 0),
  );

  /// Set in bootstrap (staging/prod) to forward non-fatal errors to Crashlytics.
  static void Function(Object error, StackTrace? stack)? errorSink;

  static void d(String message) => _logger.d(message);
  static void w(String message) => _logger.w(message);

  static void e(Object error, [StackTrace? stack]) {
    _logger.e('error', error: error, stackTrace: stack);
    errorSink?.call(error, stack);
  }
}
