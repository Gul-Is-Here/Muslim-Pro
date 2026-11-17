import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_pro/core/utils/validators.dart';
import 'package:quran_pro/features/auth/viewmodels/auth_view_model.dart';
import 'package:quran_pro/features/auth/views/widgets/auth_widgets.dart';

/// Sign in: email form in a card, then providers and guest access.
final class AuthView extends GetView<AuthViewModel> {
  const AuthView({super.key});

  @override
  Widget build(BuildContext context) => AuthScaffold(
    title: 'sign_in'.tr,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthHeading(title: 'auth_title'.tr, body: 'auth_subtitle'.tr),
        const SizedBox(height: 24),
        AuthCard(
          child: AutofillGroup(
            child: Form(
              key: controller.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthField(
                    label: 'email'.tr,
                    controller: controller.emailCtrl,
                    icon: Icons.mail_outline_rounded,
                    hint: 'email_hint'.tr,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    validator: (v) => Validators.email(v)?.tr,
                  ),
                  const SizedBox(height: 16),
                  Obx(
                    () => AuthField(
                      label: 'password'.tr,
                      controller: controller.passwordCtrl,
                      icon: Icons.lock_outline_rounded,
                      hint: '••••••••',
                      obscure: controller.obscure,
                      onToggleObscure: controller.toggleObscure,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onSubmitted: (_) => controller.submitEmail(),
                      validator: (v) => Validators.password(v)?.tr,
                      labelTrailing: AuthLink(
                        label: 'forgot_password'.tr,
                        onTap: controller.openForgotPassword,
                      ),
                    ),
                  ),
                  Obx(() => AuthStatus(state: controller.state)),
                  const SizedBox(height: 18),
                  Obx(
                    () => AuthPrimaryButton(
                      key: const Key('auth_submit'),
                      label: 'sign_in'.tr,
                      busy: controller.isBusy,
                      onPressed: controller.submitEmail,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        OrDivider('or_continue_with'.tr),
        Obx(() {
          final busy = controller.isBusy;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 10,
            children: [
              if (controller.showApple)
                ProviderButton.apple(
                  label: 'continue_apple'.tr,
                  onPressed: busy ? null : controller.signInWithApple,
                ),
              ProviderButton.google(
                label: 'continue_google'.tr,
                onPressed: busy ? null : controller.signInWithGoogle,
              ),
              SizedBox(
                height: 46,
                child: TextButton.icon(
                  onPressed: busy ? null : controller.continueAsGuest,
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFEAEFEE),
                    foregroundColor: const Color(0xFF404946),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: Theme.of(context).textTheme.labelLarge
                        ?.copyWith(fontSize: 13.5, fontWeight: FontWeight.w700),
                  ),
                  icon: const Icon(Icons.person_outline_rounded, size: 18),
                  label: Text('continue_guest'.tr),
                ),
              ),
            ],
          );
        }),
        const SizedBox(height: 12),
        AuthSwitchLine(
          question: 'no_account'.tr,
          action: 'sign_up_link'.tr,
          onTap: controller.openSignUp,
        ),
        const SizedBox(height: 12),
        const PrivacyNote(),
      ],
    ),
  );
}
