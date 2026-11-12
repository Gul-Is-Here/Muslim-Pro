/// Return a translation key when invalid, null when valid.
/// Security rules re-validate everything server-side.
abstract final class Validators {
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String? v) =>
      v != null && _email.hasMatch(v.trim()) ? null : 'err_invalid_email';

  static String? password(String? v) => v != null && v.length >= 8 ? null : 'err_weak_password';
}
