import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:quran_pro/app/routes/app_routes.dart';
import 'package:quran_pro/features/auth/viewmodels/auth_flow_view_model.dart';

/// Sign in with email, a provider, or as a guest.
final class AuthViewModel extends AuthFlowViewModel {
  AuthViewModel(super.auth);

  final formKey = GlobalKey<FormState>();
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  Future<void> continueAsGuest() => run(auth.signInAnonymously);

  Future<void> submitEmail() async {
    if (isBusy || !(formKey.currentState?.validate() ?? false)) return;
    await run(() => auth.signInWithEmail(emailCtrl.text.trim(), passwordCtrl.text));
  }

  void openSignUp() => unawaited(Get.toNamed<void>(AppRoutes.signUp));

  /// Carries over whatever was typed, so it need not be typed twice.
  void openForgotPassword() =>
      unawaited(Get.toNamed<void>(AppRoutes.forgotPassword, arguments: emailCtrl.text.trim()));

  @override
  void onClose() {
    emailCtrl.dispose();
    passwordCtrl.dispose();
    super.onClose();
  }
}
