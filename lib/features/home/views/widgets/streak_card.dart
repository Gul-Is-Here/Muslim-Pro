import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_pro/core/theme/app_colors.dart';
import 'package:quran_pro/features/home/viewmodels/home_view_model.dart';

final class StreakCard extends GetView<HomeViewModel> {
  const StreakCard({super.key});

  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColors.amber200.withValues(alpha: 0.6)),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0x99FFFBEB), Colors.white, Color(0x4DFFF7ED)],
      ),
      boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1))],
    ),
    child: Stack(
      children: [
        PositionedDirectional(
          end: -32,
          top: -32,
          child: IgnorePointer(
            child: Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.amber400.withValues(alpha: 0.2),
                    AppColors.amber400.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(16),
          child: Column(spacing: 14, children: [_StreakHeader(), _WeekRow(), _LessonGoal()]),
        ),
      ],
    ),
  );
}

final class _StreakHeader extends GetView<HomeViewModel> {
  const _StreakHeader();

  @override
  Widget build(BuildContext context) => Obx(
    () => Row(
      spacing: 10,
      children: [
        SizedBox.square(
          dimension: 36,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                    colors: [AppColors.amber500, AppColors.amber400],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.amber500.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.local_fire_department, size: 22, color: Colors.white),
                ),
              ),
              PositionedDirectional(
                end: -3,
                top: -3,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.emerald500,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                spacing: 4,
                children: [
                  Flexible(
                    child: Text(
                      controller.streakDays == 0
                          ? 'streak_start'.tr
                          : 'streak_title'.trParams({'n': '${controller.streakDays}'}),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.gray900,
                      ),
                    ),
                  ),
                  const Icon(Icons.bolt, size: 14, color: AppColors.amber500),
                ],
              ),
              Text(
                'streak_glow'.tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.amber800,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.amber100.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: AppColors.amber300.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 4,
            children: [
              const CircleAvatar(radius: 3, backgroundColor: AppColors.amber500),
              Text(
                'xp_today'.trParams({'xp': '${controller.xpToday}'}),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF78350F),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

final class _WeekRow extends GetView<HomeViewModel> {
  const _WeekRow();

  @override
  Widget build(BuildContext context) => Obx(
    () => Row(
      children: [
        for (final d in controller.week)
          Expanded(
            child: Opacity(
              opacity: d.locked ? 0.45 : 1,
              child: Column(
                spacing: 4,
                children: [
                  Text(
                    d.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: d.today ? FontWeight.w800 : FontWeight.w600,
                      color: d.today
                          ? AppColors.amber800
                          : d.locked
                          ? AppColors.gray400
                          : AppColors.gray500,
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: d.locked ? AppColors.gray100 : AppColors.amber500,
                      gradient: d.today
                          ? const LinearGradient(
                              begin: Alignment.bottomLeft,
                              end: Alignment.topRight,
                              colors: [AppColors.amber500, AppColors.amber400],
                            )
                          : null,
                      border: d.locked
                          ? Border.all(color: AppColors.gray200.withValues(alpha: 0.7))
                          : null,
                      boxShadow: d.today
                          ? const [
                              BoxShadow(color: Colors.white, spreadRadius: 1),
                              BoxShadow(color: AppColors.amber300, spreadRadius: 3),
                            ]
                          : null,
                    ),
                    child: Icon(
                      d.today
                          ? Icons.local_fire_department
                          : d.locked
                          ? Icons.lock
                          : Icons.done,
                      size: d.locked ? 13 : 16,
                      color: d.locked ? AppColors.gray400 : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}

final class _LessonGoal extends GetView<HomeViewModel> {
  const _LessonGoal();

  @override
  Widget build(BuildContext context) => Obx(
    () => Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.emerald200.withValues(alpha: 0.6)),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 2, offset: Offset(0, 1))],
      ),
      child: Row(
        spacing: 12,
        children: [
          SizedBox.square(
            dimension: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.square(
                  dimension: 40,
                  child: CircularProgressIndicator(
                    value: controller.lessonProgress,
                    strokeWidth: 4,
                    strokeCap: StrokeCap.round,
                    backgroundColor: AppColors.emerald100,
                    color: AppColors.emerald700,
                  ),
                ),
                Text(
                  '${(controller.lessonProgress * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.emerald800,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  spacing: 6,
                  children: [
                    Text(
                      'lesson_goal'.tr,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppColors.emerald800,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsetsDirectional.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.emerald200.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '+${controller.lessonXp} XP',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.emerald900,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  controller.lessonTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gray900,
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: controller.continueLearning,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryContainer,
              minimumSize: const Size(0, 36),
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 4,
              children: [
                Text(
                  'resume'.tr,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                const Icon(Icons.arrow_forward, size: 14),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
