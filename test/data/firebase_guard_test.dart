import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:quran_pro/core/errors/app_exception.dart';
import 'package:quran_pro/data/datasources/remote/firebase_guard.dart';

void main() {
  test('a misconfigured Google sign-in is reported, a real cancel is not', () {
    expect(
      googleSignInCode(GoogleSignInExceptionCode.canceled, '[16] Account reauth failed.'),
      'google-not-configured',
    );
    expect(
      googleSignInCode(GoogleSignInExceptionCode.canceled, 'activity is cancelled by the user.'),
      AppException.cancelled,
    );
    expect(
      googleSignInCode(GoogleSignInExceptionCode.providerConfigurationError, null),
      'google-not-configured',
    );
    expect(googleSignInCode(GoogleSignInExceptionCode.unknownError, null), 'google-sign-in-failed');
  });
}
