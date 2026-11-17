/// Return a translation key when invalid, null when valid.
/// Security rules re-validate everything server-side.
abstract final class Validators {
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String? v) =>
      v != null && _email.hasMatch(v.trim()) ? null : 'err_invalid_email';

  static String? password(String? v) => v != null && v.length >= 8 ? null : 'err_weak_password';

  static String? name(String? v) => v != null && v.trim().length >= 2 ? null : 'err_name_required';

  /// 0 (empty) to 4: one point each for 8+ characters, mixed case, a digit and a symbol.
  /// Under 8 characters it never rates above 1. Only [password] is enforced.
  static int passwordStrength(String v) {
    if (v.isEmpty) return 0;
    final score = [
      v.length >= 8,
      v.contains(RegExp('[a-z]')) && v.contains(RegExp('[A-Z]')),
      v.contains(RegExp(r'\d')),
      v.contains(RegExp('[^A-Za-z0-9]')),
    ].where((ok) => ok).length;
    return v.length < 8 ? 1 : score.clamp(1, 4);
  }
}
