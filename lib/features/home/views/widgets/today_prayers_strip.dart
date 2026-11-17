import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_pro/core/theme/app_colors.dart';
import 'package:quran_pro/core/theme/app_text_styles.dart';
import 'package:quran_pro/data/models/prayer.dart';
import 'package:quran_pro/features/home/viewmodels/home_view_model.dart';
import 'package:quran_pro/features/prayer_times/viewmodels/prayer_times_view_model.dart';

enum _ChipState { passed, next, upcoming }

final class TodayPrayersStrip extends StatelessWidget {
  const TodayPrayersStrip({super.key});

  @override
  Widget build(BuildContext context) => Column(
    spacing: 10,
    children: [
      const _Header(),
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 6,
          children: [for (final p in Prayer.obligatory) Expanded(child: _PrayerCard(p))],
        ),
      ),
    ],
  );
}

final class _Header extends GetView<HomeViewModel> {
  const _Header();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.symmetric(horizontal: 4),
    child: Row(
      spacing: 8,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.emerald50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.emerald200.withValues(alpha: 0.6)),
          ),
          child: const Icon(Icons.schedule, size: 15, color: AppColors.emerald800),
        ),
        Flexible(
          child: Text(
            'todays_prayers'.tr,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.gray900,
            ),
          ),
        ),
        const _DoneBadge(),
        const Spacer(),
        TextButton.icon(
          onPressed: controller.openPrayerTimes,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.gray500,
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
            minimumSize: const Size(0, 28),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          icon: const Icon(Icons.notifications_none, size: 15, color: AppColors.emerald700),
          label: Text('timetable'.tr),
        ),
      ],
    ),
  );
}

final class _DoneBadge extends GetView<PrayerTimesViewModel> {
  const _DoneBadge();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsetsDirectional.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: AppColors.emerald50,
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: AppColors.emerald200.withValues(alpha: 0.6)),
    ),
    child: Obx(
      () => Text(
        'prayers_done'.trParams({'n': '${controller.passedCount}'}),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.emerald800,
        ),
      ),
    ),
  );
}

final class _PrayerCard extends GetView<PrayerTimesViewModel> {
  const _PrayerCard(this.prayer);

  final Prayer prayer;

  static const _jewel = BoxDecoration(
    borderRadius: BorderRadius.all(Radius.circular(16)),
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF093A32), AppColors.primaryContainer, Color(0xFF042822)],
    ),
    border: Border.fromBorderSide(BorderSide(color: Color(0x99FBBF24), width: 2)),
    boxShadow: [BoxShadow(color: Color(0x40022C22), blurRadius: 8, offset: Offset(0, 4))],
  );

  static final _plain = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: AppColors.gray200.withValues(alpha: 0.7)),
    boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1))],
  );

  @override
  Widget build(BuildContext context) => Obx(() {
    final state = controller.isPassed(prayer)
        ? _ChipState.passed
        : controller.next?.prayer == prayer
        ? _ChipState.next
        : _ChipState.upcoming;
    final isNext = state == _ChipState.next;
    return Container(
      constraints: const BoxConstraints(minHeight: 110),
      padding: const EdgeInsets.all(8),
      decoration: isNext ? _jewel : _plain,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  prayer.arabicName,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 10,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    color: isNext ? AppColors.amber300 : AppColors.gray400,
                  ),
                ),
              ),
              _StatusMark(prayer: prayer, state: state),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  spacing: 4,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          prayer.labelKey.tr,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isNext ? FontWeight.w800 : FontWeight.w700,
                            color: isNext ? Colors.white : AppColors.gray700,
                          ),
                        ),
                      ),
                    ),
                    if (isNext) const CircleAvatar(radius: 2, backgroundColor: AppColors.amber400),
                  ],
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown, // "12:05 PM" must stay on one line in a narrow card
                  child: Text(
                    controller.timeOf(prayer),
                    maxLines: 1,
                    style: AppTextStyles.timer.copyWith(
                      fontSize: isNext ? 13 : 12,
                      fontWeight: switch (state) {
                        _ChipState.next => FontWeight.w800,
                        _ChipState.passed => FontWeight.w700,
                        _ChipState.upcoming => FontWeight.w600,
                      },
                      color: switch (state) {
                        _ChipState.next => AppColors.amber300,
                        _ChipState.passed => AppColors.gray900,
                        _ChipState.upcoming => AppColors.gray800,
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          _Footer(prayer: prayer, state: state, hint: controller.hintFor(prayer)),
        ],
      ),
    );
  });
}

final class _StatusMark extends StatelessWidget {
  const _StatusMark({required this.prayer, required this.state});

  final Prayer prayer;
  final _ChipState state;

  @override
  Widget build(BuildContext context) => switch (state) {
    _ChipState.passed => const CircleAvatar(radius: 3, backgroundColor: AppColors.emerald500),
    _ChipState.next => const Icon(Icons.notifications_active, size: 13, color: AppColors.amber300),
    _ChipState.upcoming => Icon(
      switch (prayer) {
        Prayer.maghrib => Icons.wb_twilight,
        Prayer.isha => Icons.nights_stay_outlined,
        Prayer.fajr => Icons.wb_twilight,
        _ => Icons.wb_sunny_outlined,
      },
      size: 13,
      color: prayer == Prayer.maghrib ? AppColors.amber500 : AppColors.gray400,
    ),
  };
}

final class _Footer extends StatelessWidget {
  const _Footer({required this.prayer, required this.state, required this.hint});

  final Prayer prayer;
  final _ChipState state;
  final String hint;

  @override
  Widget build(BuildContext context) {
    if (state == _ChipState.passed) {
      return Container(
        padding: const EdgeInsets.only(top: 4),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.gray100)),
        ),
        child: Row(
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  hint,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: AppColors.gray400,
                  ),
                ),
              ),
            ),
            const Icon(Icons.check, size: 12, color: Color(0xFF059669)),
          ],
        ),
      );
    }
    final (bg, border, fg) = switch (state) {
      _ChipState.next => (
        Colors.white.withValues(alpha: 0.15),
        Colors.white.withValues(alpha: 0.15),
        AppColors.emerald100,
      ),
      _ when prayer == Prayer.maghrib => (
        AppColors.amber50,
        AppColors.amber200.withValues(alpha: 0.5),
        const Color(0xFF78350F),
      ),
      _ => (const Color(0xFFF9FAFB), AppColors.gray100, AppColors.gray500),
    };
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border),
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            state == _ChipState.next ? hint.toUpperCase() : hint,
            style: TextStyle(
              fontSize: 8,
              letterSpacing: 0.3,
              fontWeight: state == _ChipState.next ? FontWeight.w800 : FontWeight.w700,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}
