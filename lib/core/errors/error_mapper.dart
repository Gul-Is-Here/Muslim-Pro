/// Maps backend error codes to translation keys shown to the user.
abstract final class ErrorMapper {
  static const _cancellations = {'cancelled', 'canceled', 'web-context-canceled'};

  static const _keys = <String, String>{
    'invalid-credential': 'err_invalid_credential',
    'wrong-password': 'err_invalid_credential',
    'user-not-found': 'err_invalid_credential',
    'invalid-email': 'err_invalid_email',
    'weak-password': 'err_weak_password',
    'email-already-in-use': 'err_email_in_use',
    'too-many-requests': 'err_too_many_requests',
    'network-request-failed': 'err_network',
    'unavailable': 'err_network',
    'deadline-exceeded': 'err_network',
    'permission-denied': 'err_permission',
    'not-found': 'err_not_found',
    'google-sign-in-failed': 'err_google_failed',
    'invalid-location': 'err_invalid_location',
  };

  static bool isCancellation(String code) => _cancellations.contains(code);
  static String keyFor(String code) => _keys[code] ?? 'err_unknown';
}
