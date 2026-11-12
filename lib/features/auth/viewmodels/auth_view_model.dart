import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:quran_pro/core/errors/result.dart';
import 'package:quran_pro/core/utils/validators.dart';
import 'package:quran_pro/core/utils/view_state.dart';
import 'package:quran_pro/domain/repositories/auth_repository.dart';

/// Navigation after sign-in is SessionController's job; this ViewModel only reports state.
final class AuthViewModel extends GetxController {
  AuthViewModel(this._auth);

  final AuthRepository _auth;

  final formKey = GlobalKey<FormState>();
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  final _state = Rx<ViewState<String>>(const Idle()); // Success carries an info message key
  final RxBool _signUp = false.obs;
  final RxBool _obscure = true.obs;

  ViewState<String> get state => _state.value;
  bool get isBusy => _state.value is Loading;
  bool get isSignUp => _signUp.value;
  bool get obscure => _obscure.value;
  bool get showApple => GetPlatform.isIOS;

  void toggleMode() => _signUp.toggle();
  void toggleObscure() => _obscure.toggle();

  Future<void> continueAsGuest() => _run(_auth.signInAnonymously);
  Future<void> signInWithGoogle() => _run(_auth.signInWithGoogle);
  Future<void> signInWithApple() => _run(_auth.signInWithApple);

  Future<void> submitEmail() async {
    if (isBusy || !(formKey.currentState?.validate() ?? false)) return;
    final email = emailCtrl.text.trim();
    final password = passwordCtrl.text;
    await _run(
      () => isSignUp
          ? _auth.signUpWithEmail(email, password)
          : _auth.signInWithEmail(email, password),
    );
  }

  Future<void> resetPassword() async {
    final invalid = Validators.email(emailCtrl.text);
    if (invalid != null) {
      _state.value = ViewError(invalid);
      return;
    }
    await _run(
      () => _auth.sendPasswordReset(emailCtrl.text.trim()),
      successKey: 'reset_email_sent',
    );
  }

  Future<void> _run<T>(Future<Result<T>> Function() action, {String? successKey}) async {
    if (isBusy) return; // duplicate-tap guard
    _state.value = const Loading();
    final result = await action();
    if (isClosed) return; // route may be gone after a successful sign-in
    _state.value = switch (result) {
      Ok() => successKey == null ? const Idle() : Success(successKey),
      Err(:final failure) when failure.isCancelled => const Idle(),
      Err(:final failure) => ViewError(failure.messageKey),
    };
  }

  @override
  void onClose() {
    emailCtrl.dispose();
    passwordCtrl.dispose();
    super.onClose();
  }
}
