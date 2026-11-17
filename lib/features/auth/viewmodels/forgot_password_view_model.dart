import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:quran_pro/features/auth/viewmodels/auth_flow_view_model.dart';

/// Sends a reset link, then shows where it went.
final class ForgotPasswordViewModel extends AuthFlowViewModel {
  ForgotPasswordViewModel(super.auth, {String? email})
    : emailCtrl = TextEditingController(text: email);

  final formKey = GlobalKey<FormState>();
  final TextEditingController emailCtrl;
  final _sentTo = RxnString();

  /// The address the last link went to; null until one was sent.
  String? get sentTo => _sentTo.value;

  Future<void> send() async {
    if (isBusy || !(formKey.currentState?.validate() ?? false)) return;
    final email = emailCtrl.text.trim();
    if (await run(() => auth.sendPasswordReset(email))) _sentTo.value = email;
  }

  /// Same address again: the form is no longer on screen to validate.
  Future<void> resend() async {
    final email = sentTo;
    if (email != null) {
      await run(() => auth.sendPasswordReset(email), successKey: 'reset_email_sent');
    }
  }

  void useAnotherEmail() {
    clearStatus();
    _sentTo.value = null;
  }

  void backToSignIn() => Get.back<void>();

  @override
  void onClose() {
    emailCtrl.dispose();
    super.onClose();
  }
}
