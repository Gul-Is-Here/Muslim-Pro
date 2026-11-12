import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_pro/core/theme/app_colors.dart';
import 'package:quran_pro/features/home/viewmodels/home_view_model.dart';

/// Floating frosted pill navigation. Only Home and Prayer exist so far.
final class HomeBottomNav extends GetView<HomeViewModel> {
  const HomeBottomNav({super.key});

  @override
  Widget build(BuildContext context) => SafeArea(
    minimum: const EdgeInsets.only(bottom: 10),
    child: Center(
      heightFactor: 1,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 384),
        margin: const EdgeInsetsDirectional.symmetric(horizontal: 16),
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x2E042F2E),
              blurRadius: 40,
              offset: Offset(0, 12),
              spreadRadius: -6,
            ),
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 8,
              offset: Offset(0, 2),
              spreadRadius: -1,
            ),
          ],
        ),
        child: Row(
          children: [
            _NavItem(icon: Icons.mosque, labelKey: 'nav_home', active: true, onTap: () {}),
            _NavItem(
              icon: Icons.auto_stories_outlined,
              labelKey: 'nav_learn',
              dot: true,
              onTap: controller.comingSoon,
            ),
            _NavItem(
              icon: Icons.menu_book_outlined,
              labelKey: 'nav_quran',
              onTap: controller.comingSoon,
            ),
            _NavItem(
              icon: Icons.schedule,
              labelKey: 'nav_prayer',
              onTap: controller.openPrayerTimes,
            ),
            _NavItem(icon: Icons.grid_view, labelKey: 'nav_more', onTap: controller.comingSoon),
          ],
        ),
      ),
    ),
  );
}

final class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.labelKey,
    required this.onTap,
    this.active = false,
    this.dot = false,
  });

  final IconData icon;
  final String labelKey;
  final VoidCallback onTap;
  final bool active;
  final bool dot;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Semantics(
      selected: active,
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(99),
        onTap: onTap,
        child: SizedBox(
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (active)
                    Container(
                      width: 32,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.emerald100.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Icon(icon, size: 20, color: AppColors.emerald800),
                    )
                  else
                    Icon(icon, size: 22, color: AppColors.gray500),
                  Text(
                    labelKey.tr,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                      color: active ? AppColors.emerald800 : AppColors.gray500,
                    ),
                  ),
                ],
              ),
              if (dot)
                const PositionedDirectional(
                  top: 6,
                  end: 16,
                  child: CircleAvatar(radius: 3, backgroundColor: AppColors.amber500),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
