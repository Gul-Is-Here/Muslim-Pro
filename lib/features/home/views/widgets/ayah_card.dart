import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_pro/core/services/audio_service.dart';
import 'package:quran_pro/core/theme/app_colors.dart';
import 'package:quran_pro/features/home/viewmodels/home_view_model.dart';

final class AyahCard extends GetView<HomeViewModel> {
  const AyahCard({super.key});

  @override
  Widget build(BuildContext context) {
    final translation = controller.ayahTranslation;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.amber200.withValues(alpha: 0.5)),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1))],
      ),
      child: Stack(
        children: [
          const PositionedDirectional(
            start: 0,
            top: 12,
            bottom: 12,
            child: SizedBox(
              width: 6,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadiusDirectional.horizontal(end: Radius.circular(99)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.amber400, Color(0xFF059669)],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  spacing: 6,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.amber50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.amber200.withValues(alpha: 0.6)),
                      ),
                      child: const Icon(Icons.auto_stories, size: 16, color: AppColors.amber700),
                    ),
                    Expanded(
                      child: Text(
                        'ayah_of_day'.tr,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AppColors.amber800,
                        ),
                      ),
                    ),
                    Obx(
                      () => _ReciteButton(
                        status: controller.reciteStatus,
                        onTap: controller.toggleRecite,
                      ),
                    ),
                    Obx(
                      () => _RoundIcon(
                        icon: controller.ayahBookmarked ? Icons.bookmark : Icons.bookmark_border,
                        color: controller.ayahBookmarked ? AppColors.amber600 : AppColors.gray500,
                        tooltip: 'bookmark'.tr,
                        onTap: controller.toggleAyahBookmark,
                      ),
                    ),
                    _RoundIcon(
                      icon: Icons.share,
                      color: AppColors.gray500,
                      tooltip: 'share'.tr,
                      onTap: controller.comingSoon,
                    ),
                  ],
                ),
                const Divider(height: 20, color: AppColors.gray100),
                const Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    HomeViewModel.ayahArabic,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      height: 2.1,
                      color: AppColors.emerald950,
                    ),
                  ),
                ),
                if (translation != null)
                  Text(
                    translation,
                    style: const TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      height: 1.6,
                      color: AppColors.gray700,
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsetsDirectional.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.amber50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.amber200.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        'ayah_ref'.tr,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.amber700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'ayah_location'.tr,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.gray500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final class _ReciteButton extends StatelessWidget {
  const _ReciteButton({required this.status, required this.onTap});

  final AudioStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.emerald50,
    shape: StadiumBorder(side: BorderSide(color: AppColors.emerald200.withValues(alpha: 0.7))),
    child: InkWell(
      customBorder: const StadiumBorder(),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            if (status == AudioStatus.loading)
              const SizedBox.square(
                dimension: 16,
                child: Padding(
                  padding: EdgeInsets.all(2),
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.emerald700),
                ),
              )
            else
              Icon(
                switch (status) {
                  AudioStatus.playing => Icons.pause,
                  AudioStatus.error => Icons.refresh,
                  _ => Icons.play_arrow,
                },
                size: 16,
                color: AppColors.emerald700,
              ),
            Text(
              switch (status) {
                AudioStatus.idle => 'recite',
                AudioStatus.loading => 'audio_loading',
                AudioStatus.playing => 'pause',
                AudioStatus.paused => 'resume',
                AudioStatus.error => 'retry',
              }.tr,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.emerald800,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

final class _RoundIcon extends StatelessWidget {
  const _RoundIcon({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onTap,
    icon: Icon(icon, size: 16, color: color),
    style: IconButton.styleFrom(
      backgroundColor: const Color(0xFFF9FAFB),
      fixedSize: const Size.square(28),
      minimumSize: const Size.square(28),
      padding: EdgeInsets.zero,
    ),
  );
}
