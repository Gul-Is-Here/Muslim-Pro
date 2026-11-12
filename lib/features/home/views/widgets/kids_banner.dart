import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_pro/core/theme/app_colors.dart';
import 'package:quran_pro/features/home/viewmodels/home_view_model.dart';

final class KidsBanner extends GetView<HomeViewModel> {
  const KidsBanner({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      gradient: const LinearGradient(
        colors: [AppColors.emerald900, AppColors.teal900, AppColors.primary],
      ),
      boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 8, offset: Offset(0, 4))],
    ),
    child: Row(
      spacing: 12,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.amber400,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.child_care, size: 24, color: AppColors.amber950),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                spacing: 6,
                children: [
                  Flexible(
                    child: Text(
                      'kids_family'.tr,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsetsDirectional.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      'interactive'.tr,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.emerald200,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                'kids_sub'.tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: AppColors.emerald100.withValues(alpha: 0.7)),
              ),
            ],
          ),
        ),
        Semantics(
          label: 'kids_toggle'.tr,
          child: Obx(
            () => Switch(
              value: controller.kidsMode,
              onChanged: (on) => controller.kidsMode = on,
              activeTrackColor: AppColors.amber400,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.25),
              inactiveThumbColor: Colors.white,
              thumbColor: const WidgetStatePropertyAll(Colors.white),
              trackOutlineColor: WidgetStatePropertyAll(Colors.white.withValues(alpha: 0.2)),
            ),
          ),
        ),
      ],
    ),
  );
}
