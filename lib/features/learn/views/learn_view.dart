import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_pro/data/models/learn_progress.dart';
import 'package:quran_pro/features/home/views/widgets/home_bottom_nav.dart';
import 'package:quran_pro/features/home/views/widgets/home_header.dart';
import 'package:quran_pro/features/learn/viewmodels/learn_view_model.dart';
import 'package:quran_pro/features/learn/views/widgets/learn_colors.dart';
import 'package:quran_pro/features/learn/views/widgets/learn_path.dart';
import 'package:quran_pro/features/learn/views/widgets/practice_section.dart';

final class LearnView extends GetView<LearnViewModel> {
  const LearnView({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: LearnColors.surface,
    extendBody: true, // content scrolls under the floating nav
    bottomNavigationBar: HomeBottomNav(current: NavTab.learn),
    body: SafeArea(
      bottom: false,
      child: Column(
        children: [
          HomeHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsetsDirectional.fromSTEB(16, 12, 16, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StatsBar(),
                  SizedBox(height: 16),
                  PracticeSection(),
                  SizedBox(height: 24),
                  _TrackChips(), // filters the lessons below, so it stays with them
                  SizedBox(height: 12),
                  LearnPathCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

final class _StatsBar extends GetView<LearnViewModel> {
  const _StatsBar();

  @override
  Widget build(BuildContext context) {
    const value = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: LearnColors.onSurface,
    );
    const unit = TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: LearnColors.onVariant);
    Widget divider() => Container(width: 1, height: 24, color: LearnColors.container);
    Widget stat(IconData icon, String n, String suffix, {Color color = LearnColors.gold}) => Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: [
        Icon(icon, size: 18, color: color),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: n),
              TextSpan(text: suffix, style: unit),
            ],
          ),
          style: value,
        ),
      ],
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: LearnColors.shadow,
      ),
      child: Obx(
        () => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 6,
              children: [
                const Icon(Icons.military_tech, size: 20, color: LearnColors.gold),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'learn_level'.trParams({'n': '${controller.level}'}).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: LearnColors.onVariant,
                      ),
                    ),
                    Text(
                      controller.rank,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: LearnColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            divider(),
            stat(Icons.stars, '${controller.xp} ', 'xp_unit'.tr),
            divider(),
            stat(Icons.local_fire_department, '${controller.streak}', 'days_short'.tr),
            divider(),
            Semantics(
              button: true,
              label: 'hearts'.tr,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: controller.heartsInfo,
                child: stat(
                  Icons.favorite,
                  '${controller.hearts}',
                  '/${LearnProgress.maxHearts}',
                  color: LearnColors.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _TrackChips extends GetView<LearnViewModel> {
  const _TrackChips();

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Obx(
      () => Row(
        spacing: 6,
        children: [
          _Chip(
            selected: !controller.kidsOnly,
            onTap: controller.kidsOnly ? controller.toggleKids : null,
            icon: Icons.menu_book_outlined,
            label: 'all_units'.tr,
          ),
          _Chip(
            selected: controller.kidsOnly,
            onTap: controller.kidsOnly ? null : controller.toggleKids,
            icon: Icons.star_rounded,
            iconColor: LearnColors.gold,
            label: 'kids_mode'.tr,
            badge: 'new_badge'.tr,
          ),
          _Chip(
            selected: false,
            onTap: () => showLanguageSheet(context, controller),
            icon: Icons.translate,
            label: 'learn_language'.tr,
          ),
        ],
      ),
    ),
  );
}

final class _Chip extends StatelessWidget {
  const _Chip({
    required this.selected,
    required this.onTap,
    required this.icon,
    required this.label,
    this.iconColor,
    this.badge,
  });

  final bool selected;
  final VoidCallback? onTap;
  final IconData icon;
  final Color? iconColor;
  final String label;
  final String? badge;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? LearnColors.primary : Colors.white,
    shape: const StadiumBorder(),
    elevation: 1,
    shadowColor: const Color(0x330F5C4A),
    child: InkWell(
      customBorder: const StadiumBorder(),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? Colors.white : (iconColor ?? LearnColors.onVariant),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : LearnColors.onSurface,
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: LearnColors.goldFixed,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: LearnColors.onGoldFixed,
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

void showLanguageSheet(BuildContext context, LearnViewModel vm) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  backgroundColor: LearnColors.surface,
  builder: (_) => SafeArea(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'choose_language'.tr,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        for (final (code, label) in const [('en', 'English'), ('ur', 'اردو'), ('ar', 'العربية')])
          ListTile(
            title: Text(label),
            trailing: vm.languageCode == code
                ? const Icon(Icons.check_circle, color: LearnColors.primary)
                : null,
            onTap: () => vm.setLanguage(code),
          ),
        const SizedBox(height: 8),
      ],
    ),
  ),
);
