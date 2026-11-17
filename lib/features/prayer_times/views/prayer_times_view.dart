import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_pro/core/theme/app_colors.dart';
import 'package:quran_pro/core/utils/view_state.dart';
import 'package:quran_pro/core/widgets/error_retry.dart';
import 'package:quran_pro/data/models/prayer.dart';
import 'package:quran_pro/features/home/views/widgets/home_bottom_nav.dart';
import 'package:quran_pro/features/home/views/widgets/home_header.dart';
import 'package:quran_pro/features/prayer_times/viewmodels/prayer_times_view_model.dart';
import 'package:quran_pro/features/prayer_times/views/widgets/next_prayer_card.dart';

final class PrayerTimesView extends GetView<PrayerTimesViewModel> {
  const PrayerTimesView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.surface,
    extendBody: true, // the schedule scrolls under the floating nav
    bottomNavigationBar: const HomeBottomNav(current: NavTab.prayer),
    body: SafeArea(
      bottom: false,
      child: Column(
        children: [
          const HomeHeader(), // same brand bar as Home, Learn and Quran
          Expanded(
            child: Obx(
              () => switch (controller.state) {
                Idle() || Loading() => const Center(
                  child: CircularProgressIndicator(color: AppColors.emerald700),
                ),
                Empty() => const _LocationRationale(),
                ViewError(:final messageKey) => ErrorRetry(
                  messageKey: messageKey,
                  onRetry: controller.load,
                ),
                Success() => RefreshIndicator(
                  color: AppColors.emerald700,
                  onRefresh: controller.load,
                  child: ListView(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      16,
                      12,
                      16,
                      120,
                    ), // clear of the nav
                    children: [
                      const _TitleRow(),
                      const SizedBox(height: 16),
                      if (controller.next != null) ...[
                        const NextPrayerCard(),
                        const SizedBox(height: 24),
                      ],
                      Obx(
                        () => controller.remindersOn
                            ? const SizedBox.shrink()
                            : const Padding(
                                padding: EdgeInsets.only(bottom: 12),
                                child: _RemindersOffNote(),
                              ),
                      ),
                      const _Schedule(),
                      const SizedBox(height: 16),
                      const _CalculationNote(),
                    ],
                  ),
                ),
              },
            ),
          ),
        ],
      ),
    ),
  );
}

/// Matches the Quran tab's title row: eyebrow, large title, Arabic on the end.
final class _TitleRow extends GetView<PrayerTimesViewModel> {
  const _TitleRow();

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    spacing: 8,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              spacing: 2,
              children: [
                const Icon(Icons.place_outlined, size: 13, color: AppColors.gray500),
                Flexible(
                  child: Text(
                    controller.placeLabel.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gray500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'prayer_times'.tr,
              style: const TextStyle(
                fontSize: 26,
                height: 1.25,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
      const Text(
        'الصَّلَاةُ',
        textDirection: TextDirection.rtl,
        style: TextStyle(fontFamily: 'Amiri', fontSize: 20, color: AppColors.primary),
      ),
      Material(
        color: Colors.white,
        shape: const CircleBorder(side: BorderSide(color: AppColors.gray200)),
        child: IconButton(
          tooltip: 'prayer_notifications'.tr,
          onPressed: controller.openNotificationSettings,
          icon: const Icon(Icons.notifications_none, size: 20, color: AppColors.gray700),
        ),
      ),
    ],
  );
}

final class _Schedule extends StatelessWidget {
  const _Schedule();

  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColors.gray200.withValues(alpha: 0.7)),
    ),
    child: Column(
      children: [
        for (final p in Prayer.values) ...[
          if (p != Prayer.values.first)
            const Divider(height: 1, thickness: 1, indent: 68, color: AppColors.gray100),
          _PrayerRow(p),
        ],
      ],
    ),
  );
}

final class _PrayerRow extends GetView<PrayerTimesViewModel> {
  const _PrayerRow(this.prayer);

  final Prayer prayer;

  static IconData _icon(Prayer p) => switch (p) {
    Prayer.fajr || Prayer.maghrib => Icons.wb_twilight,
    Prayer.sunrise => Icons.wb_sunny_outlined,
    Prayer.dhuhr => Icons.light_mode_outlined,
    Prayer.asr => Icons.brightness_5_outlined,
    Prayer.isha => Icons.nights_stay_outlined,
  };

  @override
  Widget build(BuildContext context) => Obx(() {
    final isNext = controller.next?.prayer == prayer;
    final passed = !isNext && controller.isPassed(prayer);
    final isSunrise = prayer == Prayer.sunrise;
    final time = controller.timeParts(prayer);
    final ink = passed
        ? AppColors.gray400
        : isNext
        ? AppColors.emerald900
        : AppColors.gray900;
    final (iconBg, iconFg) = switch ((isNext, passed, isSunrise)) {
      (true, _, _) => (AppColors.emerald700, Colors.white),
      (_, true, _) => (AppColors.gray100, AppColors.gray400),
      (_, _, true) => (AppColors.amber50, AppColors.amber600),
      _ => (AppColors.emerald50, AppColors.emerald700),
    };
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 6, 12),
      decoration: BoxDecoration(
        color: isNext ? AppColors.emerald50.withValues(alpha: 0.7) : null,
        border: isNext
            ? const BorderDirectional(start: BorderSide(color: Color(0xFF059669), width: 3))
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(_icon(prayer), size: 20, color: iconFg),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prayer.labelKey.tr,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isNext ? FontWeight.w700 : FontWeight.w600,
                    color: ink,
                  ),
                ),
                if (isNext)
                  Text(
                    controller.hintFor(prayer),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF059669),
                    ),
                  )
                else
                  Text(
                    prayer.arabicName,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 13,
                      height: 1.3,
                      color: passed ? AppColors.gray400 : AppColors.gray500,
                    ),
                  ),
              ],
            ),
          ),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: time.hm),
                TextSpan(
                  text: ' ${time.period}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: ink,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (isSunrise)
            const SizedBox(width: 48)
          else
            _BellButton(prayer: prayer, on: controller.alertOn(prayer)),
        ],
      ),
    );
  });
}

final class _BellButton extends GetView<PrayerTimesViewModel> {
  const _BellButton({required this.prayer, required this.on});

  final Prayer prayer;
  final bool on;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'reminder_for'.trParams({'prayer': prayer.labelKey.tr}),
    isSelected: on,
    onPressed: () => controller.toggleAlert(prayer),
    icon: const Icon(Icons.notifications_off_outlined, size: 20, color: AppColors.gray400),
    selectedIcon: const Icon(Icons.notifications_active, size: 20, color: AppColors.emerald700),
  );
}

final class _RemindersOffNote extends GetView<PrayerTimesViewModel> {
  const _RemindersOffNote();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsetsDirectional.fromSTEB(14, 6, 6, 6),
    decoration: BoxDecoration(
      color: AppColors.amber50,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.amber200.withValues(alpha: 0.6)),
    ),
    child: Row(
      spacing: 10,
      children: [
        const Icon(Icons.notifications_off_outlined, size: 18, color: AppColors.amber700),
        Expanded(
          child: Text(
            'reminders_off'.tr,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.amber800,
            ),
          ),
        ),
        TextButton(
          onPressed: controller.openNotificationSettings,
          style: TextButton.styleFrom(foregroundColor: AppColors.emerald800),
          child: Text('manage'.tr),
        ),
      ],
    ),
  );
}

final class _CalculationNote extends GetView<PrayerTimesViewModel> {
  const _CalculationNote();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(Icons.info_outline, size: 16, color: AppColors.gray400),
        ),
        Expanded(
          child: Obx(
            () => Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '${'calculated_for'.tr}\n'),
                  TextSpan(
                    text: controller.calculationLabel,
                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.gray700),
                  ),
                ],
              ),
              style: const TextStyle(fontSize: 12, height: 1.5, color: AppColors.gray500),
            ),
          ),
        ),
      ],
    ),
  );
}

final class _LocationRationale extends GetView<PrayerTimesViewModel> {
  const _LocationRationale();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsetsDirectional.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(color: AppColors.emerald50, shape: BoxShape.circle),
            child: const Icon(Icons.location_on_outlined, size: 32, color: AppColors.emerald700),
          ),
          const SizedBox(height: 20),
          Text(
            'location_rationale'.tr,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, height: 1.5, color: AppColors.gray700),
          ),
          const SizedBox(height: 20),
          Obx(
            () => FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.primaryContainer),
              onPressed: controller.onPermissionAction,
              child: Text(controller.permissionActionKey.tr),
            ),
          ),
        ],
      ),
    ),
  );
}
