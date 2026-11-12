import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_pro/core/theme/app_colors.dart';
import 'package:quran_pro/features/home/viewmodels/home_view_model.dart';

final class HomeHeader extends GetView<HomeViewModel> {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) => Container(
    height: 72,
    padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
    decoration: const BoxDecoration(
      color: AppColors.surface,
      border: Border(bottom: BorderSide(color: Color(0x0A000000))),
    ),
    child: Row(
      spacing: 10,
      children: [
        const _AppMark(),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                spacing: 6,
                children: [
                  Text(
                    'Noor',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      height: 1,
                    ),
                  ),
                  Text(
                    'نُور',
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.amber600,
                      height: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                spacing: 6,
                children: [
                  Container(
                    padding: const EdgeInsetsDirectional.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.emerald50,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: AppColors.emerald200.withValues(alpha: 0.6)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 4,
                      children: [
                        const CircleAvatar(radius: 3, backgroundColor: AppColors.emerald500),
                        Text(
                          controller.hijriLabel,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.emerald800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    controller.gregorianLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.gray500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const _ProfileChip(),
      ],
    ),
  );
}

final class _AppMark extends StatelessWidget {
  const _AppMark();

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 40,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
              colors: [AppColors.primaryContainer, Color(0xFF1BB58D)],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.emerald950.withValues(alpha: 0.2),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF07332E),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(child: Icon(Icons.mosque, size: 22, color: AppColors.mint)),
          ),
        ),
        PositionedDirectional(
          end: -2,
          bottom: -2,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.amber400,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.surface, width: 2),
            ),
          ),
        ),
      ],
    ),
  );
}

final class _ProfileChip extends GetView<HomeViewModel> {
  const _ProfileChip();

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'profile'.tr,
    child: Material(
      color: Colors.white,
      shape: const StadiumBorder(side: BorderSide(color: AppColors.gray200)),
      elevation: 1,
      shadowColor: Colors.black12,
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: controller.comingSoon,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(6, 4, 10, 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                    colors: [AppColors.primaryContainer, Color(0xFF126E5D)],
                  ),
                ),
                child: controller.initials.isEmpty
                    ? const Icon(Icons.person, size: 16, color: Colors.white)
                    : Text(
                        controller.initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
              const Icon(Icons.local_fire_department, size: 16, color: AppColors.amber600),
              Text(
                '${controller.streakDays}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.amber700,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
