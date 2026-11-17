import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_pro/core/theme/app_colors.dart';
import 'package:quran_pro/core/theme/app_text_styles.dart';
import 'package:quran_pro/data/models/prayer.dart';
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
      const _QuranCard(),
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Expanded(child: _QiblaTile(onTap: controller.openQibla)),
            const Expanded(child: _TasbeehTile()),
          ],
        ),
      ),
      const IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Expanded(child: _HisnulTile()),
            Expanded(child: _RamadanTile()),
          ],
        ),
      ),
    ],
  );
}

/// Continue reading: the reader's last ayah and how far into the mushaf it is.
final class _QuranCard extends GetView<HomeViewModel> {
  const _QuranCard();

  @override
  Widget build(BuildContext context) => _CardShell(
    onTap: controller.openQuranCard,
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
                  Obx(
                    () => controller.lastRead == null
                        ? const SizedBox.shrink()
                        : _Badge('last_read'.tr, bg: AppColors.amber100, fg: AppColors.amber800),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Obx(() => _SubtitleText(controller.lastReadLabel, size: 12)),
              const SizedBox(height: 6),
              Obx(() {
                final progress = controller.quranProgress;
                return Row(
                  spacing: 8,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: SizedBox(
                        width: 144,
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: AppColors.gray100,
                          color: const Color(0xFF059669),
                        ),
                      ),
                    ),
                    if (progress > 0)
                      Text(
                        '${(progress * 100).toStringAsFixed(progress < 0.1 ? 1 : 0)}%',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.emerald800,
                        ),
                      ),
                  ],
                );
              }),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, color: AppColors.gray400),
      ],
    ),
  );
}

final class _QiblaTile extends GetView<PrayerTimesViewModel> {
  const _QiblaTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _CardShell(
    onTap: onTap,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF093A32), Color(0xFF042822)],
      ),
      border: Border.all(color: AppColors.emerald400.withValues(alpha: 0.4)),
      boxShadow: [
        BoxShadow(
          color: AppColors.emerald950.withValues(alpha: 0.2),
          blurRadius: 6,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Obx(() {
      final bearing = controller.qiblaBearing;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        spacing: 10,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MiniCompass(bearing: bearing),
              const Spacer(),
              if (bearing != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  spacing: 2,
                  children: [
                    Container(
                      padding: const EdgeInsetsDirectional.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.emerald500.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: AppColors.emerald400.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        controller.qiblaDir,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.emerald300,
                        ),
                      ),
                    ),
                    Text(
                      '${bearing.round()}°',
                      style: AppTextStyles.timer.copyWith(
                        fontSize: 9,
                        color: AppColors.emerald200.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                spacing: 4,
                children: [
                  Flexible(
                    child: Text(
                      'qibla_finder'.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const Icon(Icons.explore, size: 14, color: AppColors.emerald300),
                ],
              ),
              _SubtitleText(
                controller.qiblaLabel,
                color: AppColors.amber300,
                weight: FontWeight.w700,
              ),
              _SubtitleText(
                'qibla_tap_hint'.tr,
                size: 9,
                color: AppColors.emerald200.withValues(alpha: 0.7),
              ),
            ],
          ),
        ],
      );
    }),
  );
}

/// Static dial: the needle points at the Qibla bearing from true north.
final class _MiniCompass extends StatelessWidget {
  const _MiniCompass({required this.bearing});

  final double? bearing;

  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.black.withValues(alpha: 0.4),
      border: Border.all(color: AppColors.emerald300.withValues(alpha: 0.3)),
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        Icon(
          Icons.radio_button_unchecked,
          size: 28,
          color: AppColors.emerald300.withValues(alpha: 0.4),
        ),
        Transform.rotate(
          angle: (bearing ?? 0) * math.pi / 180,
          child: Icon(
            Icons.navigation,
            size: 18,
            color: bearing == null ? AppColors.gray400 : AppColors.amber400,
            shadows: const [Shadow(color: Color(0xB3FBBF24), blurRadius: 6)],
          ),
        ),
      ],
    ),
  );
}

final class _TasbeehTile extends GetView<HomeViewModel> {
  const _TasbeehTile();

  @override
  Widget build(BuildContext context) => _CardShell(
    onTap: controller.openTasbeeh,
    decoration: _tileDecoration(AppColors.emerald200.withValues(alpha: 0.7)),
    child: Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        spacing: 10,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _IconTile(
                icon: Icons.fingerprint,
                bg: AppColors.emerald50,
                fg: AppColors.emerald800,
              ),
              const Spacer(),
              Flexible(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  spacing: 2,
                  children: [
                    _Badge(
                      controller.tasbeehBadge,
                      bg: AppColors.emerald900,
                      fg: AppColors.emerald100,
                      mono: true,
                    ),
                    _SubtitleText(
                      controller.tasbeehRound.toUpperCase(),
                      size: 8,
                      weight: FontWeight.w700,
                      color: AppColors.emerald700,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                spacing: 4,
                children: [
                  Expanded(
                    child: Text(
                      'digital_tasbeeh'.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray900,
                      ),
                    ),
                  ),
                  // Counts without leaving Home; the rest of the tile opens the full counter.
                  Material(
                    color: AppColors.emerald50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                      side: BorderSide(color: AppColors.emerald200.withValues(alpha: 0.6)),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: controller.tasbeehTap,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Text(
                          'tap_plus_one'.tr,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.emerald700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                controller.tasbeehDhikr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                  color: AppColors.emerald900,
                ),
              ),
              if (controller.tasbeehLeft.isNotEmpty) _SubtitleText(controller.tasbeehLeft, size: 9),
            ],
          ),
        ],
      ),
    ),
  );
}

final class _HisnulTile extends GetView<HomeViewModel> {
  const _HisnulTile();

  @override
  Widget build(BuildContext context) => _CardShell(
    onTap: controller.openAdhkar,
    decoration: _tileDecoration(const Color(0x9999F6E4)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      spacing: 10,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _IconTile(
              icon: controller.isMorning ? Icons.wb_sunny_outlined : Icons.nights_stay_outlined,
              bg: AppColors.teal50,
              fg: AppColors.teal800,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Align(
                alignment: AlignmentDirectional.topEnd,
                child: Obx(
                  () => _Badge(
                    controller.adhkarBadge,
                    bg: const Color(0xB3CCFBF1),
                    fg: AppColors.teal900,
                  ),
                ),
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'hisnul_muslim'.tr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.gray900,
              ),
            ),
            _SubtitleText(
              controller.adhkarLabel,
              size: 10,
              weight: FontWeight.w600,
              color: AppColors.teal800,
            ),
          ],
        ),
      ],
    ),
  );
}

final class _RamadanTile extends GetView<HomeViewModel> {
  const _RamadanTile();

  @override
  Widget build(BuildContext context) => _CardShell(
    onTap: controller.openRamadan,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.amber50, Color(0x99FEF3C7)],
      ),
      border: Border.all(color: AppColors.amber200),
      boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1))],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      spacing: 8,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.amber400,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.light_mode, size: 20, color: AppColors.amber950),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Align(
                alignment: AlignmentDirectional.topEnd,
                child: _Badge(
                  controller.ramadanBadge,
                  bg: AppColors.amber300,
                  fg: AppColors.amber950,
                ),
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ramadan_tracker'.tr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.amber950,
              ),
            ),
            const _MaghribCountdown(),
            const _FastFooter(),
          ],
        ),
      ],
    ),
  );
}

final class _FastFooter extends GetView<PrayerTimesViewModel> {
  const _FastFooter();

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 4),
    padding: const EdgeInsets.only(top: 4),
    decoration: BoxDecoration(
      border: Border(top: BorderSide(color: AppColors.amber200.withValues(alpha: 0.5))),
    ),
    child: Obx(
      () => Row(
        spacing: 4,
        children: [
          Expanded(
            child: _SubtitleText(
              '${Prayer.maghrib.labelKey.tr} ${controller.timeOf(Prayer.maghrib)}',
              size: 9,
              color: AppColors.amber700,
            ),
          ),
          Flexible(
            child: _SubtitleText(
              controller.fastLengthLabel,
              size: 9,
              weight: FontWeight.w700,
              color: const Color(0xFF78350F),
            ),
          ),
        ],
      ),
    ),
  );
}

BoxDecoration _tileDecoration(Color border) => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: border),
  boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1))],
);

final class _CardShell extends StatelessWidget {
  const _CardShell({required this.child, required this.onTap, this.decoration});

  final Widget child;
  final VoidCallback onTap;

  /// Defaults to the white 24-radius card; tiles pass their own 16-radius styles.
  final BoxDecoration? decoration;

  @override
  Widget build(BuildContext context) {
    final deco =
        decoration ??
        BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.gray200.withValues(alpha: 0.8)),
          boxShadow: const [
            BoxShadow(color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1)),
          ],
        );
    final radius = deco.borderRadius! as BorderRadius;
    return Material(
      type: MaterialType.transparency,
      child: Ink(
        decoration: deco,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(padding: EdgeInsets.all(decoration == null ? 16 : 14), child: child),
        ),
      ),
    );
  }
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

final class _MaghribCountdown extends GetView<PrayerTimesViewModel> {
  const _MaghribCountdown();

  @override
  Widget build(BuildContext context) => Obx(
    () => Text(
      controller.maghribCountdownLabel,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.timer.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.amber800,
      ),
    ),
  );
}
