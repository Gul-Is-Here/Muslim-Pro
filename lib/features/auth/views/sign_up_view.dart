import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_pro/core/theme/app_colors.dart';
import 'package:quran_pro/core/utils/validators.dart';
import 'package:quran_pro/features/auth/viewmodels/sign_up_view_model.dart';
import 'package:quran_pro/features/auth/views/widgets/auth_widgets.dart';

final class SignUpView extends GetView<SignUpViewModel> {
  const SignUpView({super.key});

  @override
  Widget build(BuildContext context) => AuthScaffold(
    title: 'sign_up'.tr,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthHeading(title: 'sign_up_title'.tr, body: 'sign_up_subtitle'.tr),
        const SizedBox(height: 24),
        AuthCard(
          child: AutofillGroup(
            child: Form(
              key: controller.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthField(
                    label: 'full_name'.tr,
                    controller: controller.nameCtrl,
                    icon: Icons.person_outline_rounded,
                    hint: 'name_hint'.tr,
                    keyboardType: TextInputType.name,
                    autofillHints: const [AutofillHints.name],
                    validator: (v) => Validators.name(v)?.tr,
                  ),
                  const SizedBox(height: 16),
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
                      hint: 'password_hint'.tr,
                      obscure: controller.obscure,
                      onToggleObscure: controller.toggleObscure,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.newPassword],
                      onSubmitted: (_) => controller.submit(),
                      validator: (v) => Validators.password(v)?.tr,
                      labelTrailing: controller.strength == 0
                          ? null
                          : Text(
                              controller.strengthKey.tr,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: _strengthColor(controller.strength),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const _StrengthMeter(),
                  Obx(() => AuthStatus(state: controller.state)),
                  const SizedBox(height: 18),
                  Obx(
                    () => AuthPrimaryButton(
                      key: const Key('sign_up_submit'),
                      label: 'create_account'.tr,
                      busy: controller.isBusy,
                      onPressed: controller.submit,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        OrDivider('or_sign_up_with'.tr),
        Obx(() {
          final busy = controller.isBusy;
          final google = ProviderButton.google(
            label: controller.showApple ? 'Google' : 'continue_google'.tr,
            onPressed: busy ? null : controller.signInWithGoogle,
          );
          if (!controller.showApple) return google;
          return Row(
            spacing: 10,
            children: [
              Expanded(
                child: ProviderButton.apple(
                  label: 'Apple',
                  onPressed: busy ? null : controller.signInWithApple,
                ),
              ),
              Expanded(child: google),
            ],
          );
        }),
        const SizedBox(height: 12),
        AuthSwitchLine(
          question: 'have_account'.tr,
          action: 'sign_in'.tr,
          onTap: controller.backToSignIn,
        ),
        const SizedBox(height: 12),
        const PrivacyNote(),
      ],
    ),
  );
}

Color _strengthColor(int s) => switch (s) {
  1 => const Color(0xFFBA1A1A),
  2 => AppColors.amber700,
  3 => AppColors.emerald700,
  _ => AppColors.emerald800,
};

/// Four segments that fill as the password gets stronger, with what would make it stronger.
final class _StrengthMeter extends GetView<SignUpViewModel> {
  const _StrengthMeter();

  @override
  Widget build(BuildContext context) => Obx(() {
    final s = controller.strength;
    final color = _strengthColor(s);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 6,
      children: [
        Row(
          spacing: 6,
          children: [
            for (var i = 1; i <= 4; i++)
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 4,
                  decoration: BoxDecoration(
                    color: i <= s ? color : AppColors.gray200,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
          ],
        ),
        Row(
          spacing: 6,
          children: [
            Icon(
              s == 4 ? Icons.check_circle_rounded : Icons.info_outline_rounded,
              size: 14,
              color: s == 4 ? AppColors.emerald700 : AppColors.gray400,
            ),
            Expanded(
              child: Text(
                (s == 4 ? 'pw_ok' : 'pw_hint').tr,
                style: const TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF404946)),
              ),
            ),
          ],
        ),
      ],
    );
  });
}
