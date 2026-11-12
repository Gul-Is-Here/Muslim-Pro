import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_pro/core/theme/app_colors.dart';
import 'package:quran_pro/core/theme/app_text_styles.dart';
import 'package:quran_pro/data/models/prayer.dart';
import 'package:quran_pro/features/home/views/widgets/section_header.dart';
import 'package:quran_pro/features/prayer_times/viewmodels/prayer_times_view_model.dart';

enum _ChipState { passed, next, upcoming }

final class TodayPrayersStrip extends GetView<PrayerTimesViewModel> {
  const TodayPrayersStrip({super.key});

  @override
  Widget build(BuildContext context) => Column(
    spacing: 10,
    children: [
      SectionHeader(
        icon: Icons.schedule,
        title: 'todays_prayers'.tr,
        trailing: Obx(
          () => Container(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.emerald50,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: AppColors.emerald200.withValues(alpha: 0.5)),
            ),
            child: Text(
              'prayers_passed'.trParams({'n': '${controller.passedCount}'}),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.emerald700,
              ),
            ),
          ),
        ),
      ),
      Row(
        spacing: 8,
        children: [for (final p in Prayer.obligatory) Expanded(child: _PrayerChip(p))],
      ),
    ],
  );
}

final class _PrayerChip extends GetView<PrayerTimesViewModel> {
  const _PrayerChip(this.prayer);

  final Prayer prayer;

  static IconData _upcomingIcon(Prayer p) => p == Prayer.isha ? Icons.nights_stay : Icons.schedule;

  @override
  Widget build(BuildContext context) => Obx(() {
    final state = controller.isPassed(prayer)
        ? _ChipState.passed
        : controller.next?.prayer == prayer
        ? _ChipState.next
        : _ChipState.upcoming;
    final isNext = state == _ChipState.next;
    final chip = Container(
      padding: const EdgeInsetsDirectional.symmetric(vertical: 10, horizontal: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: switch (state) {
          _ChipState.passed => Colors.white,
          _ChipState.next => null,
          _ChipState.upcoming => Colors.white.withValues(alpha: 0.7),
        },
        gradient: isNext
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF093A32), Color(0xFF042822)],
              )
            : null,
        border: Border.all(
          color: isNext ? AppColors.emerald400 : AppColors.gray200.withValues(alpha: 0.8),
          width: isNext ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isNext ? const Color(0x4D064E3B) : const Color(0x0D000000),
            blurRadius: isNext ? 12 : 2,
            offset: Offset(0, isNext ? 6 : 1),
          ),
        ],
      ),
      child: Column(
        spacing: 4,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: switch (state) {
                _ChipState.passed => AppColors.emerald100,
                _ChipState.next => AppColors.amber400,
                _ChipState.upcoming => AppColors.gray100,
              },
            ),
            child: Icon(
              switch (state) {
                _ChipState.passed => Icons.done,
                _ChipState.next => Icons.notifications_active,
                _ChipState.upcoming => _upcomingIcon(prayer),
              },
              size: 14,
              color: switch (state) {
                _ChipState.passed => AppColors.emerald700,
                _ChipState.next => AppColors.amber950,
                _ChipState.upcoming => AppColors.gray400,
              },
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              prayer.labelKey.tr,
              style: TextStyle(
                fontSize: 12,
                fontWeight: switch (state) {
                  _ChipState.passed => FontWeight.w700,
                  _ChipState.next => FontWeight.w800,
                  _ChipState.upcoming => FontWeight.w500,
                },
                color: switch (state) {
                  _ChipState.passed => AppColors.gray800,
                  _ChipState.next => AppColors.amber300,
                  _ChipState.upcoming => AppColors.gray700,
                },
              ),
            ),
          ),
          Text(
            controller.timeOf(prayer),
            style: AppTextStyles.timer.copyWith(
              fontSize: 10,
              fontWeight: isNext ? FontWeight.w700 : FontWeight.w500,
              color: switch (state) {
                _ChipState.passed => AppColors.gray500,
                _ChipState.next => Colors.white,
                _ChipState.upcoming => AppColors.gray400,
              },
            ),
          ),
        ],
      ),
    );
    if (!isNext) return chip;
    return Transform.scale(
      scale: 1.04,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          chip,
          Positioned(
            top: -8,
            child: Container(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.amber400,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                'next_badge'.tr,
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: AppColors.amber950,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  });
}
