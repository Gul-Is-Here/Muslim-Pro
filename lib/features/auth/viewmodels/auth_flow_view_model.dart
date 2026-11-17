import 'package:get/get.dart';
import 'package:quran_pro/core/errors/result.dart';
import 'package:quran_pro/core/utils/view_state.dart';
import 'package:quran_pro/domain/repositories/auth_repository.dart';

/// What the sign-in, sign-up and reset screens share: one request at a time, its state, and
/// the provider buttons. Navigation after sign-in is SessionController's job.
abstract base class AuthFlowViewModel extends GetxController {
  AuthFlowViewModel(this.auth);

  final AuthRepository auth;
  final _state = Rx<ViewState<String>>(const Idle()); // Success carries an info message key
  final RxBool _obscure = true.obs;

  ViewState<String> get state => _state.value;
  bool get isBusy => _state.value is Loading;
  bool get obscure => _obscure.value;
  bool get showApple => GetPlatform.isIOS;

  void toggleObscure() => _obscure.toggle();
  void clearStatus() => _state.value = const Idle();

  Future<void> signInWithGoogle() => run(auth.signInWithGoogle);
  Future<void> signInWithApple() => run(auth.signInWithApple);

  /// Returns true on success.
  Future<bool> run<T>(Future<Result<T>> Function() action, {String? successKey}) async {
    if (isBusy) return false; // duplicate-tap guard
    _state.value = const Loading();
    final result = await action();
    if (isClosed) return result is Ok; // route may be gone after a successful sign-in
    _state.value = switch (result) {
      Ok() => successKey == null ? const Idle() : Success(successKey),
      Err(:final failure) when failure.isCancelled => const Idle(),
      Err(:final failure) => ViewError(failure.messageKey),
    };
    return result is Ok;
  }
}
