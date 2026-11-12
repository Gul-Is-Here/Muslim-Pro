import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_pro/core/theme/app_colors.dart';
import 'package:quran_pro/features/home/viewmodels/home_view_model.dart';

final class StreakCard extends GetView<HomeViewModel> {
  const StreakCard({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColors.gray200.withValues(alpha: 0.8)),
      boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1))],
    ),
    child: Column(
      spacing: 12,
      children: [
        Row(
          spacing: 8,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.amber100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.local_fire_department, size: 20, color: AppColors.amber600),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'streak_title'.trParams({'n': '${controller.streakDays}'}),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.gray900,
                    ),
                  ),
                  Text(
                    'streak_sub'.trParams({'xp': '${HomeViewModel.streakXp}'}),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.amber700,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                'week_range'.tr,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gray500,
                ),
              ),
            ),
          ],
        ),
        Row(
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
                          color: d.today ? AppColors.amber700 : AppColors.gray500,
                        ),
                      ),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: d.done ? AppColors.amber500 : AppColors.gray100,
                          border: d.today ? Border.all(color: AppColors.amber300, width: 2) : null,
                        ),
                        child: Icon(
                          d.done ? Icons.done : Icons.lock,
                          size: d.done ? 15 : 13,
                          color: d.done ? Colors.white : AppColors.gray400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const _LessonGoal(),
      ],
    ),
  );
}

final class _LessonGoal extends GetView<HomeViewModel> {
  const _LessonGoal();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.emerald200.withValues(alpha: 0.6)),
      gradient: const LinearGradient(
        colors: [AppColors.emerald50, Color(0x99F0FDFA), Color(0x66ECFDF5)],
      ),
    ),
    child: Row(
      spacing: 12,
      children: [
        SizedBox.square(
          dimension: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const SizedBox.square(
                dimension: 40,
                child: CircularProgressIndicator(
                  value: HomeViewModel.lessonProgress,
                  strokeWidth: 4,
                  strokeCap: StrokeCap.round,
                  backgroundColor: AppColors.emerald200,
                  color: AppColors.emerald700,
                ),
              ),
              Text(
                '${(HomeViewModel.lessonProgress * 100).round()}%',
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
                    child: const Text(
                      '+${HomeViewModel.streakXp} XP',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.emerald900,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                HomeViewModel.lessonTitleKey.tr,
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
          onPressed: controller.comingSoon,
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
              Text('resume'.tr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              const Icon(Icons.arrow_forward, size: 14),
            ],
          ),
        ),
      ],
    ),
  );
}
