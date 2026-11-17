import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_pro/core/services/audio_service.dart';
import 'package:quran_pro/core/theme/app_colors.dart';
import 'package:quran_pro/features/quran/viewmodels/quran_view_model.dart';
import 'package:quran_pro/features/quran/views/widgets/star_badge.dart';

/// Jade hero card: the surah the Sunnah recommends today, with its opening ayah.
final class FeaturedSurahCard extends GetView<QuranViewModel> {
  const FeaturedSurahCard({super.key});

  @override
  Widget build(BuildContext context) {
    final f = controller.featured;
    final s = controller.featuredSurah;
    if (s == null) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.jewelTop, AppColors.primaryContainer, AppColors.jewelBottom],
          ),
        ),
        child: Stack(
          children: [
            const PositionedDirectional(
              end: -44,
              bottom: -44,
              child: SizedBox.square(
                dimension: 210,
                child: CustomPaint(painter: StarPainter(Color(0x149CD1C7))),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.amber400,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 4,
                          children: [
                            const Icon(Icons.auto_awesome, size: 13, color: AppColors.amber950),
                            Text(
                              f.badgeKey.tr.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                letterSpacing: 0.8,
                                fontWeight: FontWeight.w800,
                                color: AppColors.amber950,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        s.arabic,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 22,
                          color: AppColors.emerald200.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'quran_surah_named'.trParams({'name': s.name}),
                    style: const TextStyle(
                      fontSize: 24,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${s.meaning} · ${'quran_ayahs'.trParams({'n': '${s.ayahs}'})}',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.emerald200.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 4,
                      children: [
                        Text(
                          f.arabic,
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 19,
                            height: 1.9,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '“${f.translation}”',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.45,
                            fontStyle: FontStyle.italic,
                            color: AppColors.emerald100.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    spacing: 10,
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: FilledButton.icon(
                            onPressed: () => controller.openSurah(s.number),
                            iconAlignment: IconAlignment.end,
                            icon: const Icon(Icons.arrow_forward, size: 20),
                            label: Text('quran_read_surah'.tr),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primary,
                              textStyle: const TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Obx(
                        () => _PlayButton(
                          status: controller.previewStatus(s.number),
                          onTap: () => controller.togglePreview(s.number),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.status, required this.onTap});

  final AudioStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 46,
    child: IconButton.filled(
      tooltip: 'quran_listen'.tr,
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: AppColors.primaryContainer,
        foregroundColor: AppColors.mint,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: AppColors.emerald200.withValues(alpha: 0.25)),
      ),
      icon: switch (status) {
        AudioStatus.loading => const SizedBox.square(
          dimension: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.mint),
        ),
        AudioStatus.playing => const Icon(Icons.pause),
        _ => const Icon(Icons.play_arrow),
      },
    ),
  );
}
