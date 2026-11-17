import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_pro/core/services/audio_service.dart';
import 'package:quran_pro/core/theme/app_colors.dart';
import 'package:quran_pro/data/models/quran_index.dart';
import 'package:quran_pro/features/quran/viewmodels/quran_view_model.dart';
import 'package:quran_pro/features/quran/views/widgets/star_badge.dart';

const _cardShadow = [BoxShadow(color: Color(0x0A042F2E), blurRadius: 10, offset: Offset(0, 2))];

final class SurahTile extends GetView<QuranViewModel> {
  const SurahTile(this.surah, {super.key});

  final SurahInfo surah;

  @override
  Widget build(BuildContext context) {
    final featured = surah.number == controller.featured.surah;
    final accent = featured ? AppColors.amber700 : AppColors.primaryContainer;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => controller.openSurah(surah.number),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: _cardShadow,
            border: featured
                ? const BorderDirectional(start: BorderSide(color: AppColors.amber500, width: 4))
                : null,
          ),
          padding: const EdgeInsetsDirectional.fromSTEB(12, 12, 4, 12),
          child: Row(
            spacing: 12,
            children: [
              StarBadge(label: '${surah.number}', color: accent),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Row(
                      spacing: 6,
                      children: [
                        Flexible(
                          child: Text(
                            surah.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        _PlacePill(makki: surah.makki),
                        Obx(
                          () => controller.isDownloaded(surah.number)
                              ? Icon(
                                  Icons.download_done_rounded,
                                  size: 16,
                                  color: AppColors.emerald700,
                                  semanticLabel: 'quran_downloaded'.tr,
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                    Text(
                      '${surah.meaning} · ${'quran_ayahs'.trParams({'n': '${surah.ayahs}'})}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5, color: AppColors.gray500),
                    ),
                  ],
                ),
              ),
              Text(
                surah.arabic,
                textDirection: TextDirection.rtl,
                style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 20,
                  height: 1.5,
                  color: AppColors.primary,
                ),
              ),
              Obx(() {
                final status = controller.previewStatus(surah.number);
                return IconButton(
                  tooltip: 'quran_listen'.tr,
                  onPressed: () => controller.togglePreview(surah.number),
                  color: featured ? AppColors.amber700 : AppColors.gray500,
                  icon: switch (status) {
                    AudioStatus.loading => const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    AudioStatus.playing => const Icon(
                      Icons.pause_circle,
                      color: AppColors.emerald700,
                    ),
                    _ => const Icon(Icons.play_circle_outline),
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

final class _PlacePill extends StatelessWidget {
  const _PlacePill({required this.makki});

  final bool makki;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
    decoration: BoxDecoration(
      color: makki ? AppColors.gray100 : AppColors.emerald50,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 3,
      children: [
        Icon(
          makki ? Icons.mosque_outlined : Icons.location_city_outlined,
          size: 11,
          color: makki ? AppColors.gray500 : AppColors.emerald700,
        ),
        Text(
          (makki ? 'quran_makki' : 'quran_madani').tr,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: makki ? AppColors.gray500 : AppColors.emerald700,
          ),
        ),
      ],
    ),
  );
}

final class JuzTile extends GetView<QuranViewModel> {
  const JuzTile(this.juz, {super.key});

  final JuzInfo juz;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => controller.openSurah(juz.surah, ayah: juz.ayah),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), boxShadow: _cardShadow),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'quran_juz_n'.trParams({'n': '${juz.number}'}).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w800,
                    color: AppColors.amber700,
                  ),
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    juz.arabic,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 15,
                      color: AppColors.gray500,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              juz.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            Text(
              '${controller.surahName(juz.surah)} ${juz.surah}:${juz.ayah}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppColors.gray500),
            ),
          ],
        ),
      ),
    ),
  );
}
