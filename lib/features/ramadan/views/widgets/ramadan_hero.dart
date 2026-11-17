import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_pro/core/theme/app_colors.dart';
import 'package:quran_pro/features/ramadan/viewmodels/ramadan_view_model.dart';

/// Night-sky card: in Ramadan, the live countdown to iftar or the end of suhoor;
/// before it, how many days are left.
final class RamadanHero extends GetView<RamadanViewModel> {
  const RamadanHero({super.key});

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(24),
    child: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B2E35), AppColors.primaryContainer, AppColors.jewelBottom],
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: _StarsPainter())),
          PositionedDirectional(
            end: -18,
            top: -12,
            child: Icon(
              Icons.nightlight_round,
              size: 130,
              color: AppColors.amber300.withValues(alpha: 0.16),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Obx(() => controller.inRamadan ? const _InRamadan() : const _BeforeRamadan()),
          ),
        ],
      ),
    ),
  );
}

final class _InRamadan extends GetView<RamadanViewModel> {
  const _InRamadan();

  @override
  Widget build(BuildContext context) {
    final next = controller.next;
    final label = switch (next?.event) {
      FastEvent.suhoorEnds => 'ramadan_suhoor_ends_in'.tr,
      FastEvent.iftar => 'ramadan_iftar_in'.tr,
      null => 'ramadan_set_location'.tr,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Eyebrow(
          'ramadan_day_of'.trParams({'n': '${controller.today}', 'year': '${controller.year}'}),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.emerald200.withValues(alpha: 0.9),
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      controller.countdown,
                      style: const TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        color: AppColors.amber300,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _FastRing(
              fraction: controller.fastFraction,
              fasted: controller.fasted,
              days: RamadanViewModel.days,
            ),
          ],
        ),
        const SizedBox(height: 16),
        const _TimesRow(),
      ],
    );
  }
}

final class _BeforeRamadan extends GetView<RamadanViewModel> {
  const _BeforeRamadan();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _Eyebrow('ramadan_year'.trParams({'year': '${controller.year}'})),
      const SizedBox(height: 12),
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        spacing: 10,
        children: [
          Text(
            '${controller.daysUntil}',
            style: const TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 52,
              height: 1,
              fontWeight: FontWeight.w700,
              color: AppColors.amber300,
            ),
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                'ramadan_days_to_go'.tr,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 6),
      Text(
        'ramadan_expected'.trParams({'date': controller.startDateLabel}),
        style: TextStyle(fontSize: 13, color: AppColors.emerald200.withValues(alpha: 0.9)),
      ),
      const SizedBox(height: 16),
      Text(
        'ramadan_today_voluntary'.tr.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          letterSpacing: 1,
          fontWeight: FontWeight.w800,
          color: Colors.white.withValues(alpha: 0.6),
        ),
      ),
      const SizedBox(height: 8),
      const _TimesRow(),
    ],
  );
}

final class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: AppColors.amber400, borderRadius: BorderRadius.circular(99)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 5,
      children: [
        const Icon(Icons.nightlight_round, size: 13, color: AppColors.amber950),
        Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 10.5,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w800,
            color: AppColors.amber950,
          ),
        ),
      ],
    ),
  );
}

/// Suhoor ends (Fajr) and iftar (Maghrib) for today.
final class _TimesRow extends GetView<RamadanViewModel> {
  const _TimesRow();

  @override
  Widget build(BuildContext context) => Row(
    spacing: 10,
    children: [
      Expanded(
        child: _TimeTile(
          icon: Icons.wb_twilight_rounded,
          label: 'ramadan_suhoor_ends'.tr,
          time: controller.timeLabel(controller.suhoorEnds),
        ),
      ),
      Expanded(
        child: _TimeTile(
          icon: Icons.restaurant_rounded,
          label: 'ramadan_iftar'.tr,
          time: controller.timeLabel(controller.iftar),
        ),
      ),
    ],
  );
}

final class _TimeTile extends StatelessWidget {
  const _TimeTile({required this.icon, required this.label, required this.time});

  final IconData icon;
  final String label;
  final String time;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.22),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
    ),
    child: Row(
      spacing: 10,
      children: [
        Icon(icon, size: 20, color: AppColors.amber300),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.7)),
              ),
              Text(
                time,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Outer ring: today's fast so far; centre: fasts kept this Ramadan.
final class _FastRing extends StatelessWidget {
  const _FastRing({required this.fraction, required this.fasted, required this.days});

  final double fraction;
  final int fasted;
  final int days;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 92,
    child: Stack(
      alignment: Alignment.center,
      children: [
        SizedBox.expand(
          child: CircularProgressIndicator(
            value: fraction,
            strokeWidth: 7,
            strokeCap: StrokeCap.round,
            color: AppColors.amber400,
            backgroundColor: Colors.white.withValues(alpha: 0.12),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$fasted/$days',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Text(
              'ramadan_fasts'.tr,
              style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.7)),
            ),
          ],
        ),
      ],
    ),
  );
}

/// A few fixed stars, so the card reads as night without an image asset.
final class _StarsPainter extends CustomPainter {
  const _StarsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(7); // fixed seed: same sky every frame
    final paint = Paint()..color = Colors.white;
    for (var i = 0; i < 26; i++) {
      paint.color = Colors.white.withValues(alpha: 0.08 + rng.nextDouble() * 0.25);
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
        0.6 + rng.nextDouble() * 1.2,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StarsPainter old) => false;
}
