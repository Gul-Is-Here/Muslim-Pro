import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_pro/core/theme/app_colors.dart';
import 'package:quran_pro/features/home/viewmodels/home_view_model.dart';

enum NavTab { home, learn, quran, prayer, more }

/// Floating frosted pill navigation, shared by every tab.
final class HomeBottomNav extends GetView<HomeViewModel> {
  const HomeBottomNav({this.current = NavTab.home, super.key});

  final NavTab current;

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
            _NavItem(
              icon: Icons.mosque,
              labelKey: 'nav_home',
              active: current == NavTab.home,
              onTap: current == NavTab.home ? () {} : () => controller.openHome(),
            ),
            _NavItem(
              icon: current == NavTab.learn ? Icons.auto_stories : Icons.auto_stories_outlined,
              labelKey: 'nav_learn',
              active: current == NavTab.learn,
              dot: current != NavTab.learn,
              onTap: current == NavTab.learn ? () {} : () => controller.openLearn(),
            ),
            _NavItem(
              icon: current == NavTab.quran ? Icons.menu_book : Icons.menu_book_outlined,
              labelKey: 'nav_quran',
              active: current == NavTab.quran,
              onTap: current == NavTab.quran ? () {} : () => controller.openQuran(),
            ),
            _NavItem(
              icon: current == NavTab.prayer ? Icons.watch_later : Icons.schedule,
              labelKey: 'nav_prayer',
              active: current == NavTab.prayer,
              onTap: current == NavTab.prayer ? () {} : () => controller.openPrayerTimes(),
            ),
            _NavItem(
              icon: current == NavTab.more ? Icons.grid_view_rounded : Icons.grid_view,
              labelKey: 'nav_more',
              active: current == NavTab.more,
              onTap: current == NavTab.more ? () {} : () => controller.openMore(),
            ),
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
