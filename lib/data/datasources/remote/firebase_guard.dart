import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:quran_pro/core/errors/app_exception.dart';

/// Converts SDK exceptions into backend-neutral AppExceptions. Wrap every remote call.
Future<T> guard<T>(Future<T> Function() call) async {
  try {
    return await call();
  } on FirebaseException catch (e) {
    // FirebaseAuthException is a FirebaseException subtype.
    throw AppException(e.code);
  } on GoogleSignInException catch (e) {
    throw AppException(
      e.code == GoogleSignInExceptionCode.canceled
          ? AppException.cancelled
          : 'google-sign-in-failed',
    );
  }
}
