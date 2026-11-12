import 'package:quran_pro/core/errors/app_exception.dart';
import 'package:quran_pro/core/errors/failure.dart';
import 'package:quran_pro/core/errors/result.dart';
import 'package:quran_pro/core/utils/app_log.dart';

Future<Result<T>> runCatching<T>(Future<T> Function() call) async {
  try {
    return Ok(await call());
  } on AppException catch (e) {
    return Err(Failure(e.code));
  } on Object catch (e, s) {
    AppLog.e(e, s); // unexpected: goes to Crashlytics in staging/prod
    return const Err(Failure(AppException.unknown));
  }
}
