import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_pro/core/theme/app_colors.dart';
import 'package:quran_pro/core/theme/app_text_styles.dart';
import 'package:quran_pro/features/home/viewmodels/home_view_model.dart';
import 'package:quran_pro/features/home/views/widgets/section_header.dart';
import 'package:quran_pro/features/prayer_times/viewmodels/prayer_times_view_model.dart';

final class EssentialsSection extends GetView<HomeViewModel> {
  const EssentialsSection({super.key});

  @override
  Widget build(BuildContext context) => Column(
    spacing: 10,
    children: [
      SectionHeader(
        icon: Icons.apps,
        title: 'spiritual_essentials'.tr,
        trailing: Text(
          'quick_access'.tr,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.emerald800,
          ),
        ),
      ),
      _QuranCard(onTap: controller.comingSoon),
      Row(
        spacing: 12,
        children: [
          Expanded(
            child: _Tile(
              icon: Icons.explore,
              iconBg: AppColors.amber50,
              iconFg: AppColors.amber700,
              trailing: const Icon(Icons.navigation, size: 16, color: AppColors.amber600),
              title: 'qibla_finder'.tr,
              subtitle: const _QiblaSubtitle(),
              onTap: controller.comingSoon,
            ),
          ),
          Expanded(
            child: _Tile(
              icon: Icons.touch_app,
              iconBg: AppColors.emerald50,
              iconFg: AppColors.emerald800,
              trailing: Obx(
                () => _Badge(
                  '${controller.tasbeehCount} / ${HomeViewModel.tasbeehTarget}',
                  bg: AppColors.primaryContainer,
                  fg: AppColors.emerald100,
                  mono: true,
                ),
              ),
              title: 'digital_tasbeeh'.tr,
              subtitle: _SubtitleText(
                'سُبْحَانَ اللَّه • ${'tap_me'.tr}',
                color: AppColors.emerald800,
                weight: FontWeight.w600,
              ),
              onTap: controller.tapTasbeeh,
            ),
          ),
        ],
      ),
      Row(
        spacing: 12,
        children: [
          Expanded(
            child: _Tile(
              icon: Icons.import_contacts,
              iconBg: AppColors.teal50,
              iconFg: AppColors.teal800,
              trailing: _Badge('daily'.tr, bg: const Color(0xB3CCFBF1), fg: AppColors.teal900),
              title: 'hisnul_muslim'.tr,
              subtitle: _SubtitleText(controller.adhkarKey.tr),
              onTap: controller.comingSoon,
            ),
          ),
          Expanded(
            child: _Tile(
              icon: Icons.volunteer_activism,
              iconBg: AppColors.amber50,
              iconFg: AppColors.amber700,
              trailing: _Badge(
                controller.hijriShortLabel,
                bg: AppColors.amber200.withValues(alpha: 0.7),
                fg: const Color(0xFF78350F),
              ),
              title: 'ramadan_tracker'.tr,
              subtitle: const _MaghribCountdown(),
              onTap: controller.comingSoon,
            ),
          ),
        ],
      ),
    ],
  );
}

final class _QuranCard extends StatelessWidget {
  const _QuranCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _CardShell(
    onTap: onTap,
    child: Row(
      spacing: 12,
      children: [
        const _IconTile(
          icon: Icons.menu_book,
          size: 48,
          iconSize: 26,
          bg: AppColors.emerald50,
          fg: AppColors.emerald800,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                spacing: 8,
                children: [
                  Flexible(
                    child: Text(
                      'noble_quran'.tr,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray900,
                      ),
                    ),
                  ),
                  _Badge('last_read'.tr, bg: AppColors.amber100, fg: AppColors.amber800),
                ],
              ),
              const SizedBox(height: 2),
              _SubtitleText('last_read_ref'.tr, size: 12),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: const SizedBox(
                  width: 144,
                  child: LinearProgressIndicator(
                    value: HomeViewModel.quranProgress,
                    minHeight: 6,
                    backgroundColor: AppColors.gray100,
                    color: Color(0xFF059669),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, color: AppColors.gray400),
      ],
    ),
  );
}

final class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.trailing,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final Widget trailing;
  final String title;
  final Widget subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _CardShell(
    onTap: onTap,
    child: SizedBox(
      height: 92,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _IconTile(icon: icon, bg: iconBg, fg: iconFg),
              trailing,
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gray900,
                ),
              ),
              subtitle,
            ],
          ),
        ],
      ),
    ),
  );
}

final class _CardShell extends StatelessWidget {
  const _CardShell({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: BorderSide(color: AppColors.gray200.withValues(alpha: 0.8)),
    ),
    elevation: 0.5,
    shadowColor: Colors.black26,
    child: InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  );
}

final class _IconTile extends StatelessWidget {
  const _IconTile({
    required this.icon,
    required this.bg,
    required this.fg,
    this.size = 40,
    this.iconSize = 22,
  });

  final IconData icon;
  final Color bg;
  final Color fg;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: fg.withValues(alpha: 0.15)),
    ),
    child: Icon(icon, size: iconSize, color: fg),
  );
}

final class _Badge extends StatelessWidget {
  const _Badge(this.text, {required this.bg, required this.fg, this.mono = false});

  final String text;
  final Color bg;
  final Color fg;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    const base = TextStyle(fontSize: 10, fontWeight: FontWeight.w700);
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Text(text, style: (mono ? AppTextStyles.timer.merge(base) : base).copyWith(color: fg)),
    );
  }
}

final class _SubtitleText extends StatelessWidget {
  const _SubtitleText(
    this.text, {
    this.color = AppColors.gray500,
    this.weight = FontWeight.w500,
    this.size = 11,
  });

  final String text;
  final Color color;
  final FontWeight weight;
  final double size;

  @override
  Widget build(BuildContext context) => Text(
    text,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: TextStyle(fontSize: size, fontWeight: weight, color: color),
  );
}

final class _QiblaSubtitle extends GetView<PrayerTimesViewModel> {
  const _QiblaSubtitle();

  @override
  Widget build(BuildContext context) => Obx(() => _SubtitleText(controller.qiblaLabel));
}

final class _MaghribCountdown extends GetView<PrayerTimesViewModel> {
  const _MaghribCountdown();

  @override
  Widget build(BuildContext context) => Obx(
    () => Text(
      controller.maghribCountdownLabel,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.timer.copyWith(fontSize: 11, color: AppColors.amber700),
    ),
  );
}
