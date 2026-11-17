import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_pro/core/services/audio_service.dart';
import 'package:quran_pro/core/theme/app_colors.dart';
import 'package:quran_pro/features/quran/viewmodels/surah_reader_view_model.dart';

/// Docked recitation player: what is playing, how far into the surah, and every control
/// (previous/next ayah, play/pause, repeat, speed). Mirrors the notification player.
final class ReaderPlayer extends GetView<SurahReaderViewModel> {
  const ReaderPlayer({super.key});

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      boxShadow: [BoxShadow(color: Color(0x1F042F2E), blurRadius: 24, offset: Offset(0, -4))],
    ),
    child: SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
        child: Obx(() {
          final info = controller.info;
          if (info == null) return const SizedBox(height: 120);
          final status = controller.status;
          final ayah = controller.playingAyah;
          final idle = status == AudioStatus.idle || status == AudioStatus.error;
          final title = idle
              ? 'quran_recite_surah'.trParams({'name': info.name})
              : controller.onBismillah
              ? 'quran_bismillah'.tr
              : 'quran_ayah_of'.trParams({'n': '${ayah ?? 1}', 'total': '${info.ayahs}'});
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          'quran_reciter_full'.tr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppColors.gray500),
                        ),
                      ],
                    ),
                  ),
                  _SpeedChip(speed: controller.speed, onTap: controller.cycleSpeed),
                  const SizedBox(width: 4),
                  _RepeatButton(mode: controller.repeat, onTap: controller.cycleRepeat),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: idle || ayah == null ? 0 : ayah / info.ayahs,
                  minHeight: 4,
                  color: AppColors.emerald500,
                  backgroundColor: AppColors.gray100,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 20,
                children: [
                  IconButton(
                    tooltip: 'quran_prev_ayah'.tr,
                    onPressed: idle ? null : controller.previous,
                    iconSize: 30,
                    color: AppColors.primary,
                    icon: const Icon(Icons.skip_previous_rounded),
                  ),
                  _PlayPause(status: status, onTap: controller.togglePlay),
                  IconButton(
                    tooltip: 'quran_next_ayah'.tr,
                    onPressed: idle ? null : controller.next,
                    iconSize: 30,
                    color: AppColors.primary,
                    icon: const Icon(Icons.skip_next_rounded),
                  ),
                ],
              ),
            ],
          );
        }),
      ),
    ),
  );
}

final class _PlayPause extends StatelessWidget {
  const _PlayPause({required this.status, required this.onTap});

  final AudioStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: (status == AudioStatus.playing ? 'quran_pause' : 'quran_play').tr,
    child: Material(
      color: AppColors.primaryContainer,
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: AppColors.primaryContainer.withValues(alpha: 0.4),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox.square(
          dimension: 60,
          child: Center(
            child: switch (status) {
              AudioStatus.loading => const SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.mint),
              ),
              AudioStatus.playing => const Icon(
                Icons.pause_rounded,
                size: 34,
                color: AppColors.mint,
              ),
              _ => const Icon(Icons.play_arrow_rounded, size: 36, color: AppColors.mint),
            },
          ),
        ),
      ),
    ),
  );
}

final class _SpeedChip extends StatelessWidget {
  const _SpeedChip({required this.speed, required this.onTap});

  final double speed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = speed == speed.roundToDouble() ? '${speed.toInt()}×' : '$speed×';
    return Tooltip(
      message: 'quran_speed'.tr,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: speed == 1 ? AppColors.gray100 : AppColors.amber100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: speed == 1 ? AppColors.gray700 : AppColors.amber800,
            ),
          ),
        ),
      ),
    );
  }
}

final class _RepeatButton extends StatelessWidget {
  const _RepeatButton({required this.mode, required this.onTap});

  final AudioRepeat mode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: switch (mode) {
      AudioRepeat.off => 'quran_repeat_off',
      AudioRepeat.one => 'quran_repeat_one',
      AudioRepeat.all => 'quran_repeat_all',
    }.tr,
    onPressed: onTap,
    style: IconButton.styleFrom(
      backgroundColor: mode == AudioRepeat.off ? Colors.transparent : AppColors.emerald50,
    ),
    icon: Icon(
      mode == AudioRepeat.one ? Icons.repeat_one_rounded : Icons.repeat_rounded,
      color: mode == AudioRepeat.off ? AppColors.gray400 : AppColors.emerald700,
    ),
  );
}
