import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_pro/core/theme/app_colors.dart';
import 'package:quran_pro/core/theme/app_text_styles.dart';
import 'package:quran_pro/features/home/viewmodels/home_view_model.dart';
import 'package:quran_pro/features/prayer_times/viewmodels/prayer_times_view_model.dart';

/// "Jewel" card: next prayer, live countdown, daylight ring and prayer timeline.
final class PrayerHeroCard extends GetView<PrayerTimesViewModel> {
  const PrayerHeroCard({super.key});

  static const _jewel = BoxDecoration(
    borderRadius: BorderRadius.all(Radius.circular(24)),
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.jewelTop, AppColors.primaryContainer, AppColors.jewelBottom],
      stops: [0, 0.45, 1],
    ),
    boxShadow: [BoxShadow(color: Color(0x40022C22), blurRadius: 32, offset: Offset(0, 16))],
  );

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: _jewel,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          // Ambient glows + geometric star, purely decorative.
          const Positioned.fill(child: _Glows()),
          const PositionedDirectional(
            end: -40,
            bottom: -40,
            child: _Star(size: 240, color: Color(0x0DFFFFFF)),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Obx(() => controller.next == null ? const _NoLocation() : const _HeroContent()),
          ),
        ],
      ),
    ),
  );
}

final class _HeroContent extends GetView<PrayerTimesViewModel> {
  const _HeroContent();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 16,
    children: [
      const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        spacing: 8,
        children: [
          Flexible(child: _LocationPill()),
          _AdhanToggle(),
        ],
      ),
      Row(
        children: [
          Expanded(
            // Obx: name/adhan time change when the next prayer rolls over.
            child: Obx(
              () => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    spacing: 6,
                    children: [
                      const Icon(Icons.wb_twilight, size: 17, color: AppColors.emerald300),
                      Text(
                        'next_prayer_upper'.tr,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AppColors.emerald300,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsetsDirectional.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.amber400.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.amber300.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          controller.nextName,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.amber300,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    spacing: 8,
                    children: [
                      Text(
                        controller.nextName,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'prayer_in'.tr,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.emerald200.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Obx(
                      () => Text(
                        controller.countdownLabel,
                        style: AppTextStyles.timer.copyWith(
                          fontSize: 34,
                          height: 1.2,
                          color: AppColors.amber300,
                          shadows: const [
                            Shadow(color: Color(0x59FE932C), blurRadius: 12, offset: Offset(0, 2)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    controller.adhanAtLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.emerald200.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const _DaylightRing(),
        ],
      ),
      const _Timeline(),
    ],
  );
}

final class _LocationPill extends GetView<HomeViewModel> {
  const _LocationPill();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsetsDirectional.symmetric(horizontal: 12, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.25),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: [
        const CircleAvatar(radius: 4, backgroundColor: AppColors.emerald400),
        const Icon(Icons.near_me, size: 14, color: AppColors.emerald200),
        Flexible(
          child: Obx(
            () => Text(
              controller.placeLabel,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.emerald200,
              ),
            ),
          ),
        ),
        Text('•', style: TextStyle(color: Colors.white.withValues(alpha: 0.4))),
        const _Clock(),
      ],
    ),
  );
}

final class _Clock extends GetView<PrayerTimesViewModel> {
  const _Clock();

  @override
  Widget build(BuildContext context) => Obx(
    () => Text(
      controller.clockLabel,
      style: AppTextStyles.timer.copyWith(fontSize: 11, color: Colors.white.withValues(alpha: 0.9)),
    ),
  );
}

final class _AdhanToggle extends GetView<HomeViewModel> {
  const _AdhanToggle();

  @override
  Widget build(BuildContext context) => Obx(() {
    final on = controller.alertsOn;
    return Material(
      color: Colors.white.withValues(alpha: 0.15),
      shape: StadiumBorder(side: BorderSide(color: Colors.white.withValues(alpha: 0.15))),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: controller.openNotificationSettings,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 10, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              Icon(
                on ? Icons.volume_up : Icons.volume_off,
                size: 15,
                color: on ? AppColors.amber300 : AppColors.gray400,
              ),
              Text(
                (on ? 'adhan_on' : 'adhan_off').tr,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.emerald100,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  });
}

final class _DaylightRing extends GetView<PrayerTimesViewModel> {
  const _DaylightRing();

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 96,
    child: Obx(() {
      final value = controller.daylightProgress;
      return Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.square(
            dimension: 84,
            child: CircularProgressIndicator(
              value: value,
              strokeWidth: 8,
              strokeCap: StrokeCap.round,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              color: AppColors.amber400,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(value * 100).round()}%',
                style: AppTextStyles.timer.copyWith(fontSize: 14, color: AppColors.amber300),
              ),
              Text(
                'daylight'.tr,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      );
    }),
  );
}

final class _Timeline extends GetView<PrayerTimesViewModel> {
  const _Timeline();

  @override
  Widget build(BuildContext context) {
    final muted = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: AppColors.emerald200.withValues(alpha: 0.8),
    );
    return Obx(
      () => Column(
        spacing: 6,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(controller.previousLabel, style: muted),
              Text(
                controller.remainingLabel,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.amber300,
                ),
              ),
              Text(controller.nextLabelShort, style: muted),
            ],
          ),
          Container(
            height: 8,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: FractionallySizedBox(
                widthFactor: controller.segmentProgress,
                heightFactor: 1,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(99)),
                    gradient: LinearGradient(
                      colors: [AppColors.emerald400, AppColors.amber300, AppColors.amber400],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown until a location is known: explains why and asks for it.
final class _NoLocation extends GetView<PrayerTimesViewModel> {
  const _NoLocation();

  @override
  Widget build(BuildContext context) => Column(
    spacing: 12,
    children: [
      const Icon(Icons.location_on_outlined, size: 36, color: AppColors.amber300),
      Text(
        'location_rationale'.tr,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.emerald100, fontSize: 13),
      ),
      Obx(
        () => FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.amber400,
            foregroundColor: AppColors.amber950,
          ),
          onPressed: controller.onPermissionAction,
          child: Text(controller.permissionActionKey.tr),
        ),
      ),
    ],
  );
}

final class _Glows extends StatelessWidget {
  const _Glows();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(
      gradient: RadialGradient(
        center: Alignment(0.7, -0.7),
        radius: 0.9,
        colors: [Color(0x386FFBBE), Color(0x006FFBBE)],
      ),
    ),
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.8, 0.7),
          radius: 0.8,
          colors: [Color(0x2EFE932C), Color(0x00FE932C)],
        ),
      ),
    ),
  );
}

final class _Star extends StatelessWidget {
  const _Star({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _StarPainter(color));
}

final class _StarPainter extends CustomPainter {
  const _StarPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final outer = size.width / 2;
    final inner = outer * 0.42;
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? outer : inner;
      final a = -math.pi / 2 + i * math.pi / 5;
      final p = c + Offset(math.cos(a) * r, math.sin(a) * r);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path..close(), Paint()..color = color);
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.color != color;
}
