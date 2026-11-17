import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_pro/core/services/audio_service.dart';
import 'package:quran_pro/core/theme/app_colors.dart';
import 'package:quran_pro/features/home/viewmodels/home_view_model.dart';

final class AyahCard extends GetView<HomeViewModel> {
  const AyahCard({super.key});

  @override
  Widget build(BuildContext context) => Obx(_card);

  Widget _card() {
    final translation = controller.ayahTranslation;
    final divider = AppColors.amber200.withValues(alpha: 0.5);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.amber200.withValues(alpha: 0.6)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x80FFFBEB), Colors.white, Color(0x4DECFDF5)],
        ),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1))],
      ),
      child: Stack(
        children: [
          const PositionedDirectional(end: -40, top: -40, child: _Glow(color: Color(0x4DFDE68A))),
          const PositionedDirectional(
            start: -40,
            bottom: -40,
            child: _Glow(color: Color(0x33A7F3D0)),
          ),
          const PositionedDirectional(
            start: 0,
            top: 16,
            bottom: 16,
            child: SizedBox(
              width: 6,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadiusDirectional.horizontal(end: Radius.circular(99)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.amber400, AppColors.amber500, Color(0xFF059669)],
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
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          begin: Alignment.bottomLeft,
                          end: Alignment.topRight,
                          colors: [AppColors.amber500, AppColors.amber300],
                        ),
                      ),
                      child: const Icon(Icons.menu_book, size: 18, color: AppColors.amber950),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'daily_tadabbur'.tr,
                                  style: const TextStyle(
                                    letterSpacing: 1.2,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.emerald800,
                                  ),
                                ),
                                const TextSpan(
                                  text: '  •  ',
                                  style: TextStyle(color: Color(0xFFD1D5DB)),
                                ),
                                TextSpan(
                                  text: controller.ayahShortRef,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.amber800,
                                  ),
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 9),
                          ),
                          Text(
                            'ayah_of_day'.tr,
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
                      icon: Icons.copy_rounded,
                      color: AppColors.gray500,
                      tooltip: 'quran_copy'.tr,
                      onTap: controller.copyAyah,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(height: 1, color: divider),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 16, 4, 12),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: controller.ayahArabic ?? ''),
                        const TextSpan(
                          text: ' ۝',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w400,
                            color: AppColors.amber600,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      height: 2.1,
                      color: AppColors.emerald950,
                    ),
                  ),
                ),
                if (translation != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      translation,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        height: 1.6,
                        color: AppColors.gray700,
                      ),
                    ),
                  ),
                Divider(height: 1, color: divider),
                const SizedBox(height: 8),
                Row(
                  spacing: 6,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsetsDirectional.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.amber50,
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: AppColors.amber200.withValues(alpha: 0.6)),
                        ),
                        child: Text(
                          controller.ayahRef,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF78350F),
                          ),
                        ),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        controller.ayahLocation,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.gray400,
                        ),
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: controller.readAyahInContext,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'read_in_context'.tr,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.emerald800,
                              ),
                            ),
                            const Icon(Icons.chevron_right, size: 14, color: AppColors.emerald800),
                          ],
                        ),
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

final class _Glow extends StatelessWidget {
  const _Glow({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: 144,
      height: 144,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    ),
  );
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
      backgroundColor: Colors.white,
      side: BorderSide(color: AppColors.gray200.withValues(alpha: 0.8)),
      fixedSize: const Size.square(28),
      minimumSize: const Size.square(28),
      padding: EdgeInsets.zero,
    ),
  );
}
