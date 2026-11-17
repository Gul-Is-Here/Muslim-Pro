import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_pro/core/theme/app_colors.dart';
import 'package:quran_pro/core/theme/app_text_styles.dart';
import 'package:quran_pro/data/models/prayer.dart';
import 'package:quran_pro/features/prayer_times/viewmodels/prayer_times_view_model.dart';

/// Next prayer, live countdown, and the sun's path between sunrise and sunset.
final class NextPrayerCard extends GetView<PrayerTimesViewModel> {
  const NextPrayerCard({super.key});

  @override
  Widget build(BuildContext context) {
    final muted = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: Colors.white.withValues(alpha: 0.7),
    );
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(22, 20, 22, 18),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(28)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primaryContainer, Color(0xFF07332E)],
        ),
        boxShadow: [BoxShadow(color: Color(0x33022C22), blurRadius: 24, offset: Offset(0, 12))],
      ),
      child: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'next_prayer_upper'.tr,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: AppColors.emerald200.withValues(alpha: 0.85),
                  ),
                ),
                const Spacer(),
                Text(controller.adhanAtLabel, style: muted),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    controller.nextName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 34,
                      height: 1.1,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  controller.countdownLabel,
                  style: AppTextStyles.timer.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppColors.amber300,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 84,
              child: CustomPaint(
                painter: _SunArcPainter(
                  progress: controller.daylightProgress,
                  daytime: controller.isDaytime,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.wb_sunny_outlined, size: 14, color: muted.color),
                const SizedBox(width: 6),
                Text(
                  '${Prayer.sunrise.labelKey.tr}  ${controller.timeOf(Prayer.sunrise)}',
                  style: muted,
                ),
                const Spacer(),
                Text('${'sunset'.tr}  ${controller.timeOf(Prayer.maghrib)}', style: muted),
                const SizedBox(width: 6),
                Icon(Icons.wb_twilight, size: 14, color: muted.color),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Half-ellipse from sunrise (left) to sunset (right); the sun sits at [progress] along it.
final class _SunArcPainter extends CustomPainter {
  const _SunArcPainter({required this.progress, required this.daytime});

  final double progress;
  final bool daytime;

  @override
  void paint(Canvas canvas, Size size) {
    const inset = 8.0;
    final base = size.height - 2;
    final rect = Rect.fromLTRB(inset, inset, size.width - inset, base * 2 - inset);
    final horizon = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, base), Offset(size.width, base), horizon);

    // Dotted path of the whole day.
    final dots = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.22);
    const steps = 48;
    for (var i = 0; i <= steps; i++) {
      canvas.drawArc(rect, math.pi + math.pi * i / steps, 0.005, false, dots);
    }

    if (daytime && progress > 0) {
      canvas.drawArc(
        rect,
        math.pi,
        math.pi * progress,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..shader = const LinearGradient(colors: [AppColors.emerald300, AppColors.amber400])
              .createShader(rect),
      );
    }

    final angle = math.pi + math.pi * progress;
    final sun =
        rect.center + Offset(math.cos(angle) * rect.width / 2, math.sin(angle) * rect.height / 2);
    if (daytime) {
      canvas
        ..drawCircle(sun, 12, Paint()..color = AppColors.amber400.withValues(alpha: 0.22))
        ..drawCircle(sun, 6, Paint()..color = AppColors.amber300);
    } else {
      // Below the horizon: a hollow marker resting at sunrise or sunset.
      canvas.drawCircle(
        sun,
        5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = Colors.white.withValues(alpha: 0.4),
      );
    }
  }

  @override
  bool shouldRepaint(_SunArcPainter old) => old.progress != progress || old.daytime != daytime;
}
