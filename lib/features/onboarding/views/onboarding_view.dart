import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_pro/features/onboarding/viewmodels/onboarding_view_model.dart';

final class OnboardingView extends GetView<OnboardingViewModel> {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: PageView(
              controller: controller.pageController,
              onPageChanged: controller.onPageChanged,
              children: [
                const _OnboardingPage(icon: Icons.mosque_outlined, n: 1),
                _OnboardingPage(
                  icon: Icons.notifications_active_outlined,
                  n: 2,
                  action: OutlinedButton(
                    onPressed: controller.enableNotifications,
                    child: Text('onboarding_enable_alerts'.tr),
                  ),
                ),
                const _OnboardingPage(icon: Icons.menu_book_outlined, n: 3),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.all(24),
            child: SizedBox(
              width: double.infinity,
              child: Obx(
                () => FilledButton(
                  onPressed: controller.next,
                  child: Text((controller.isLast ? 'get_started' : 'next').tr),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

final class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.icon, required this.n, this.action});

  final IconData icon;
  final int n;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.all(32),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 72, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 24),
        Text(
          'onboarding_title_$n'.tr,
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text('onboarding_body_$n'.tr, textAlign: TextAlign.center),
        if (action != null) ...[const SizedBox(height: 24), action!],
      ],
    ),
  );
}
