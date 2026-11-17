import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_pro/core/theme/app_colors.dart';
import 'package:quran_pro/core/utils/validators.dart';
import 'package:quran_pro/features/auth/viewmodels/forgot_password_view_model.dart';
import 'package:quran_pro/features/auth/views/widgets/auth_widgets.dart';

/// Ask for the email, then confirm where the link went.
final class ForgotPasswordView extends GetView<ForgotPasswordViewModel> {
  const ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) => AuthScaffold(
    title: 'reset_password'.tr,
    // A plain switch: the form's GlobalKey must never be on screen twice mid-transition.
    child: Obx(() => controller.sentTo == null ? const _Request() : const _Sent()),
  );
}

final class _Request extends GetView<ForgotPasswordViewModel> {
  const _Request();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AuthHeading(icon: Icons.lock_reset_rounded, title: 'forgot_title'.tr, body: 'forgot_body'.tr),
      const SizedBox(height: 24),
      AuthCard(
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
                textInputAction: TextInputAction.send,
                autofillHints: const [AutofillHints.email],
                onSubmitted: (_) => controller.send(),
                validator: (v) => Validators.email(v)?.tr,
              ),
              Obx(() => AuthStatus(state: controller.state)),
              const SizedBox(height: 18),
              Obx(
                () => AuthPrimaryButton(
                  key: const Key('reset_submit'),
                  label: 'send_reset_link'.tr,
                  icon: Icons.send_rounded,
                  busy: controller.isBusy,
                  onPressed: controller.send,
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      AuthSwitchLine(
        question: 'remembered_password'.tr,
        action: 'sign_in'.tr,
        onTap: controller.backToSignIn,
      ),
    ],
  );
}

final class _Sent extends GetView<ForgotPasswordViewModel> {
  const _Sent();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AuthHeading(
        icon: Icons.mark_email_read_outlined,
        title: 'reset_sent_title'.tr,
        body: 'reset_sent_body'.trParams({'email': controller.sentTo ?? ''}),
      ),
      const SizedBox(height: 24),
      AuthCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (icon, key) in const [
              (Icons.mail_outline_rounded, 'reset_tip_open'),
              (Icons.schedule_rounded, 'reset_tip_spam'),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 10,
                  children: [
                    Icon(icon, size: 18, color: AppColors.emerald700),
                    Expanded(
                      child: Text(
                        key.tr,
                        style: const TextStyle(
                          fontSize: 13.5,
                          height: 1.45,
                          color: Color(0xFF404946),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Obx(() => AuthStatus(state: controller.state)),
            const SizedBox(height: 6),
            AuthPrimaryButton(
              label: 'back_to_sign_in'.tr,
              busy: false,
              onPressed: controller.backToSignIn,
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Obx(
                  () => AuthLink(
                    label: 'resend_link'.tr,
                    onTap: controller.isBusy ? null : controller.resend,
                  ),
                ),
                const Text('·', style: TextStyle(color: AppColors.gray400)),
                AuthLink(label: 'use_another_email'.tr, onTap: controller.useAnotherEmail),
              ],
            ),
          ],
        ),
      ),
    ],
  );
}
