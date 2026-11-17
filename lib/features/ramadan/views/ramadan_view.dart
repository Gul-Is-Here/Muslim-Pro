import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_pro/core/theme/app_colors.dart';
import 'package:quran_pro/features/ramadan/viewmodels/ramadan_view_model.dart';
import 'package:quran_pro/features/ramadan/views/widgets/ramadan_cards.dart';
import 'package:quran_pro/features/ramadan/views/widgets/ramadan_hero.dart';

final class RamadanView extends GetView<RamadanViewModel> {
  const RamadanView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.surface,
    appBar: AppBar(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      title: Text(
        'ramadan_title'.tr,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.gray900),
      ),
      actions: [
        if (controller.canPreview)
          Obx(
            () => TextButton.icon(
              onPressed: controller.togglePreview,
              icon: Icon(
                controller.previewing ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 18,
              ),
              label: Text(controller.previewing ? 'ramadan_preview_off'.tr : 'ramadan_preview'.tr),
              style: TextButton.styleFrom(foregroundColor: AppColors.amber800),
            ),
          ),
        const SizedBox(width: 4),
      ],
    ),
    body: Obx(
      () => ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          const RamadanHero(),
          const SizedBox(height: 20),
          const FastCalendar(),
          if (controller.inRamadan) ...[
            const SizedBox(height: 20),
            const DeedsChecklist(),
            const SizedBox(height: 20),
            const KhatamCard(),
          ],
          const SizedBox(height: 20),
          const LastTenCard(),
          const SizedBox(height: 20),
          const QadaCard(),
          const SizedBox(height: 20),
          const DuasSection(),
        ],
      ),
    ),
  );
}
