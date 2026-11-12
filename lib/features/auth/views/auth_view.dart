import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_pro/core/utils/validators.dart';
import 'package:quran_pro/core/utils/view_state.dart';
import 'package:quran_pro/features/auth/viewmodels/auth_view_model.dart';

final class AuthView extends GetView<AuthViewModel> {
  const AuthView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.all(24),
        child: AutofillGroup(
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('auth_title'.tr, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 24),
                TextFormField(
                  controller: controller.emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  decoration: InputDecoration(labelText: 'email'.tr),
                  validator: (v) => Validators.email(v)?.tr,
                ),
                const SizedBox(height: 12),
                Obx(
                  () => TextFormField(
                    controller: controller.passwordCtrl,
                    obscureText: controller.obscure,
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(
                      labelText: 'password'.tr,
                      suffixIcon: IconButton(
                        tooltip: 'toggle_password'.tr,
                        onPressed: controller.toggleObscure,
                        icon: Icon(controller.obscure ? Icons.visibility : Icons.visibility_off),
                      ),
                    ),
                    validator: (v) => Validators.password(v)?.tr,
                  ),
                ),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: controller.resetPassword,
                    child: Text('forgot_password'.tr),
                  ),
                ),
                const _StatusText(),
                const SizedBox(height: 12),
                const _SubmitButton(),
                TextButton(
                  onPressed: controller.toggleMode,
                  child: Obx(() => Text((controller.isSignUp ? 'have_account' : 'no_account').tr)),
                ),
                const Divider(height: 32),
                const _ProviderButtons(),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

final class _StatusText extends GetView<AuthViewModel> {
  const _StatusText();

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Obx(
      () => switch (controller.state) {
        ViewError(:final messageKey) => Text(
          messageKey.tr,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
        Success(:final data) => Text(data.tr),
        _ => const SizedBox.shrink(),
      },
    ),
  );
}

final class _SubmitButton extends GetView<AuthViewModel> {
  const _SubmitButton();

  @override
  Widget build(BuildContext context) => Obx(
    () => FilledButton(
      key: const Key('auth_submit'),
      onPressed: controller.isBusy ? null : controller.submitEmail,
      child: controller.isBusy
          ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : Text((controller.isSignUp ? 'sign_up' : 'sign_in').tr),
    ),
  );
}

final class _ProviderButtons extends GetView<AuthViewModel> {
  const _ProviderButtons();

  @override
  Widget build(BuildContext context) => Obx(() {
    final busy = controller.isBusy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        OutlinedButton(
          onPressed: busy ? null : controller.signInWithGoogle,
          child: Text('continue_google'.tr),
        ),
        if (controller.showApple)
          OutlinedButton(
            onPressed: busy ? null : controller.signInWithApple,
            child: Text('continue_apple'.tr),
          ),
        TextButton(
          onPressed: busy ? null : controller.continueAsGuest,
          child: Text('continue_guest'.tr),
        ),
      ],
    );
  });
}
