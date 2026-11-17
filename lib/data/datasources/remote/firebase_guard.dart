import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:quran_pro/core/errors/app_exception.dart';
import 'package:quran_pro/core/utils/app_log.dart';

/// Converts SDK exceptions into backend-neutral AppExceptions. Wrap every remote call.
Future<T> guard<T>(Future<T> Function() call) async {
  try {
    return await call();
  } on FirebaseException catch (e) {
    // FirebaseAuthException is a FirebaseException subtype.
    throw AppException(e.code);
  } on GoogleSignInException catch (e) {
    AppLog.w('Google sign-in: ${e.code.name} ${e.description ?? ''}'); // no PII in either
    throw AppException(googleSignInCode(e.code, e.description));
  }
}

/// Android reports a missing SHA-1 / wrong OAuth client as "canceled" with "[16] Account reauth
/// failed"; treating that as the user closing the picker made the button silently do nothing.
String googleSignInCode(GoogleSignInExceptionCode code, String? description) => switch (code) {
  GoogleSignInExceptionCode.canceled when description?.contains('[16]') ?? false =>
    'google-not-configured',
  GoogleSignInExceptionCode.canceled => AppException.cancelled,
  GoogleSignInExceptionCode.clientConfigurationError ||
  GoogleSignInExceptionCode.providerConfigurationError => 'google-not-configured',
  _ => 'google-sign-in-failed',
};
