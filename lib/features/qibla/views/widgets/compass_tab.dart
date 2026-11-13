import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_pro/core/theme/app_colors.dart';
import 'package:quran_pro/core/utils/compass_math.dart';
import 'package:quran_pro/features/qibla/viewmodels/qibla_view_model.dart';
import 'package:quran_pro/features/qibla/views/qibla_view.dart';
import 'package:quran_pro/features/qibla/views/widgets/qibla_painters.dart';

final class CompassTab extends GetView<QiblaViewModel> {
  const CompassTab({super.key});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 32),
    children: const [
      _StatusRow(),
      SizedBox(height: 14),
      QiblaModeSwitcher(),
      SizedBox(height: 16),
      _DialCard(),
      SizedBox(height: 16),
      _InfoGrid(),
      SizedBox(height: 16),
      _SanctuaryCard(),
      SizedBox(height: 16),
      _CalibrationCard(),
    ],
  );
}

final class _Pill extends StatelessWidget {
  const _Pill({required this.child, this.color});

  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsetsDirectional.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: color ?? Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(99),
    ),
    child: child,
  );
}

final class _StatusRow extends GetView<QiblaViewModel> {
  const _StatusRow();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Obx(
      () => Column(
        spacing: 8,
        children: [
          Row(
            spacing: 8,
            children: [
              Flexible(
                child: _Pill(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 6,
                    children: [
                      const Icon(Icons.my_location, size: 14, color: AppColors.emerald700),
                      Flexible(
                        child: Text(
                          [
                            if (controller.placeLabel.isNotEmpty) controller.placeLabel,
                            if (controller.accuracy != null)
                              'accuracy_value'.trParams({
                                'deg': controller.accuracy!.round().toString(),
                              }),
                          ].join(' • '),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _Pill(
                color: AppColors.amber100,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 6,
                  children: [
                    const Icon(Icons.explore, size: 14, color: AppColors.amber800),
                    Text(
                      'distance_to_kaaba'.trParams({'distance': controller.distanceLabel}),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.amber950,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: [
              Icon(
                controller.needsCalibration ? Icons.warning_amber_rounded : Icons.verified,
                size: 16,
                color: controller.needsCalibration ? AppColors.amber600 : AppColors.emerald700,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  (controller.needsCalibration ? 'calibration_recommended' : 'sensors_calibrated')
                      .tr,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => showCalibrationSheet(context),
                icon: const Icon(Icons.sync, size: 16),
                label: Text('recalibrate'.tr),
                style: TextButton.styleFrom(foregroundColor: AppColors.amber700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final class _DialCard extends GetView<QiblaViewModel> {
  const _DialCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsetsDirectional.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, 8)),
        ],
      ),
      child: Obx(() {
        if (!controller.compassAvailable) return const _NoCompass();
        final heading = controller.heading;
        final aligned = controller.aligned;
        return Column(
          children: [
            _AlignmentChip(aligned: aligned, label: controller.turnLabel),
            const SizedBox(height: 16),
            Semantics(
              label: controller.turnLabel,
              child: SizedBox.square(
                dimension: 280,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size.square(280),
                      painter: CompassDialPainter(
                        heading: heading ?? 0,
                        ring: scheme.outlineVariant,
                        muted: scheme.onSurfaceVariant,
                      ),
                    ),
                    if (heading != null && controller.info != null)
                      Transform.rotate(
                        angle: (controller.info!.bearing - heading) * math.pi / 180,
                        child: const SizedBox.square(dimension: 280, child: _KaabaPointer()),
                      ),
                    _Centerpiece(heading: heading, aligned: aligned),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              (aligned ? 'facing_haram' : 'rotate_hint').tr,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'qibla_from_north'.trParams({'bearing': controller.bearingLabel}),
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
            const Divider(height: 28),
            Row(
              children: [
                Expanded(
                  // Own Material so the ripple shows above the card background.
                  child: Material(
                    type: MaterialType.transparency,
                    child: SwitchListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.vibration, color: AppColors.primaryContainer),
                      title: Text(
                        'haptic_feedback'.tr,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text('haptic_feedback_sub'.tr),
                      value: controller.haptics,
                      onChanged: (_) => controller.toggleHaptics(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }
}

final class _AlignmentChip extends StatelessWidget {
  const _AlignmentChip({required this.aligned, required this.label});

  final bool aligned;
  final String label;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 250),
    padding: const EdgeInsetsDirectional.symmetric(horizontal: 14, vertical: 6),
    decoration: BoxDecoration(
      color: aligned ? const Color(0xFF004930) : AppColors.amber100,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: [
        Icon(
          aligned ? Icons.check_circle : Icons.rotate_right,
          size: 16,
          color: aligned ? AppColors.mint : AppColors.amber800,
        ),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: aligned ? Colors.white : AppColors.amber950,
          ),
        ),
      ],
    ),
  );
}

/// Kaaba marker on the dial's rim plus a glowing ray from the centre.
final class _KaabaPointer extends StatelessWidget {
  const _KaabaPointer();

  @override
  Widget build(BuildContext context) => Stack(
    alignment: Alignment.topCenter,
    children: [
      Positioned(
        top: 40,
        child: Container(
          width: 5,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [AppColors.amber500, AppColors.amber500.withValues(alpha: 0)],
            ),
          ),
        ),
      ),
      Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.amber500,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.surfaceContainerLowest, width: 3),
          boxShadow: [BoxShadow(color: AppColors.amber500.withValues(alpha: 0.45), blurRadius: 12)],
        ),
        child: const Icon(Icons.mosque, size: 20, color: AppColors.gray900),
      ),
    ],
  );
}

final class _Centerpiece extends StatelessWidget {
  const _Centerpiece({required this.heading, required this.aligned});

  final double? heading;
  final bool aligned;

  @override
  Widget build(BuildContext context) => Container(
    width: 136,
    height: 136,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.primaryContainer, AppColors.jewelTop, AppColors.primary],
      ),
      boxShadow: [BoxShadow(color: Color(0x4D0D4740), blurRadius: 24, offset: Offset(0, 8))],
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'heading_upper'.tr,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
            color: AppColors.emerald200,
          ),
        ),
        Text(
          heading == null ? '--' : '${heading!.round()}°',
          style: const TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.1,
          ),
        ),
        Text(
          heading == null ? '' : CompassMath.cardinal(heading!),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.amber200,
          ),
        ),
        if (aligned)
          Text(
            'aligned_short'.tr,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.mint,
            ),
          ),
      ],
    ),
  );
}

final class _NoCompass extends GetView<QiblaViewModel> {
  const _NoCompass();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.symmetric(vertical: 24),
    child: Column(
      spacing: 12,
      children: [
        const Icon(Icons.explore_off_outlined, size: 48),
        Text('no_compass'.tr, textAlign: TextAlign.center),
        Text('qibla_from_north'.trParams({'bearing': controller.bearingLabel})),
        FilledButton.tonal(
          onPressed: () => unawaited(controller.setMode(QiblaMode.map)),
          child: Text('mode_map'.tr),
        ),
      ],
    ),
  );
}

final class _InfoGrid extends GetView<QiblaViewModel> {
  const _InfoGrid();

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        Expanded(
          child: Obx(
            () => _InfoTile(
              icon: Icons.near_me_outlined,
              badge: controller.declinationLabel,
              title: 'true_north'.tr,
              body: 'declination_note'.tr,
            ),
          ),
        ),
        Expanded(
          child: _InfoTile(
            icon: Icons.mosque_outlined,
            badge: 'salah_badge'.tr,
            title: 'facing_qibla'.tr,
            body: 'facing_qibla_note'.tr,
            accent: true,
          ),
        ),
      ],
    ),
  );
}

final class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.badge,
    required this.title,
    required this.body,
    this.accent = false,
  });

  final IconData icon;
  final String badge;
  final String title;
  final String body;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsetsDirectional.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accent ? AppColors.amber100 : scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: accent ? AppColors.amber800 : AppColors.primaryContainer,
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  badge,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(body, style: TextStyle(fontSize: 12, height: 1.45, color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

final class _SanctuaryCard extends GetView<QiblaViewModel> {
  const _SanctuaryCard();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsetsDirectional.fromSTEB(18, 18, 14, 18),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.primaryContainer, AppColors.jewelBottom],
      ),
    ),
    child: Row(
      spacing: 14,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.amber500.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.mosque, color: AppColors.amber300, size: 28),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'target_sanctuary'.tr,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: AppColors.emerald200,
                ),
              ),
              Text(
                'kaaba_makkah'.tr,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Obx(
          () => Container(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              controller.distanceLabel,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

final class _CalibrationCard extends GetView<QiblaViewModel> {
  const _CalibrationCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsetsDirectional.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 14,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.all_inclusive, color: AppColors.primaryContainer),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'figure8_title'.tr,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  'figure8_short'.tr,
                  style: TextStyle(fontSize: 12, height: 1.45, color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    FilledButton.icon(
                      onPressed: () => unawaited(controller.testHaptic()),
                      icon: const Icon(Icons.touch_app, size: 16),
                      label: Text('test_haptic'.tr),
                      style: FilledButton.styleFrom(backgroundColor: AppColors.primaryContainer),
                    ),
                    TextButton(
                      onPressed: () => showAccuracySheet(context, controller),
                      child: Text('accuracy_details'.tr),
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
