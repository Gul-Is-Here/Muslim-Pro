import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:quran_pro/core/utils/validators.dart';
import 'package:quran_pro/features/auth/viewmodels/auth_flow_view_model.dart';

final class SignUpViewModel extends AuthFlowViewModel {
  SignUpViewModel(super.auth);

  final formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final RxInt _strength = 0.obs;

  /// 0 (nothing typed) to 4; see [Validators.passwordStrength].
  int get strength => _strength.value;

  String get strengthKey => const ['', 'pw_weak', 'pw_fair', 'pw_good', 'pw_strong'][strength];

  @override
  void onInit() {
    super.onInit();
    passwordCtrl.addListener(_rate);
  }

  void _rate() => _strength.value = Validators.passwordStrength(passwordCtrl.text);

  Future<void> submit() async {
    if (isBusy || !(formKey.currentState?.validate() ?? false)) return;
    await run(
      () => auth.signUpWithEmail(
        emailCtrl.text.trim(),
        passwordCtrl.text,
        name: nameCtrl.text.trim(),
      ),
    );
  }

  void backToSignIn() => Get.back<void>();

  @override
  void onClose() {
    passwordCtrl.removeListener(_rate);
    nameCtrl.dispose();
    emailCtrl.dispose();
    passwordCtrl.dispose();
    super.onClose();
  }
}
