import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_pro/core/theme/app_colors.dart';
import 'package:quran_pro/features/qibla/viewmodels/qibla_view_model.dart';
import 'package:quran_pro/features/qibla/views/widgets/ar_tab.dart';
import 'package:quran_pro/features/qibla/views/widgets/compass_tab.dart';
import 'package:quran_pro/features/qibla/views/widgets/map_tab.dart';

final class QiblaView extends GetView<QiblaViewModel> {
  const QiblaView({super.key});

  @override
  Widget build(BuildContext context) => Obx(() {
    final overlay = controller.mode != QiblaMode.compass; // camera / map fill the screen
    return Scaffold(
      extendBodyBehindAppBar: overlay,
      appBar: _QiblaAppBar(onImage: overlay),
      body: controller.needsLocation
          ? const _LocationPrompt()
          : switch (controller.mode) {
              QiblaMode.compass => const CompassTab(),
              QiblaMode.ar => const ArTab(),
              QiblaMode.map => const MapTab(),
            },
    );
  });
}

final class _QiblaAppBar extends GetView<QiblaViewModel> implements PreferredSizeWidget {
  const _QiblaAppBar({required this.onImage});

  final bool onImage;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = onImage ? Colors.white : scheme.onSurface;
    return AppBar(
      backgroundColor: onImage ? Colors.black.withValues(alpha: 0.35) : scheme.surface,
      foregroundColor: fg,
      titleSpacing: 0,
      title: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'qibla_finder'.tr,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            Row(
              spacing: 6,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: controller.needsCalibration ? AppColors.amber500 : AppColors.emerald400,
                  ),
                ),
                Flexible(
                  child: Text(
                    [
                      if (controller.placeLabel.isNotEmpty) controller.placeLabel,
                      (controller.needsCalibration ? 'qibla_needs_calibration' : 'qibla_calibrated')
                          .tr,
                    ].join(' • '),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: fg.withValues(alpha: 0.75)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'mode_map'.tr,
          icon: const Icon(Icons.map_outlined),
          onPressed: () => unawaited(controller.setMode(QiblaMode.map)),
        ),
        IconButton(
          tooltip: 'accuracy_details'.tr,
          icon: const Icon(Icons.info_outline),
          onPressed: () => showAccuracySheet(context, controller),
        ),
      ],
    );
  }
}

/// Compass / AR Finder / World Map switcher, shared by all three tabs.
final class QiblaModeSwitcher extends GetView<QiblaViewModel> {
  const QiblaModeSwitcher({super.key, this.onImage = false});

  final bool onImage;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Obx(
      () => SegmentedButton<QiblaMode>(
        showSelectedIcon: false,
        style: SegmentedButton.styleFrom(
          backgroundColor: onImage
              ? Colors.black.withValues(alpha: 0.45)
              : scheme.surfaceContainerHigh,
          foregroundColor: onImage ? Colors.white70 : scheme.onSurfaceVariant,
          selectedBackgroundColor: onImage
              ? AppColors.primaryContainer
              : scheme.surfaceContainerLowest,
          selectedForegroundColor: onImage ? Colors.white : AppColors.primaryContainer,
          side: BorderSide.none,
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        segments: [
          ButtonSegment(
            value: QiblaMode.compass,
            icon: const Icon(Icons.explore_outlined, size: 18),
            label: Text('mode_compass'.tr),
          ),
          ButtonSegment(
            value: QiblaMode.ar,
            icon: const Icon(Icons.view_in_ar_outlined, size: 18),
            label: Text('mode_ar'.tr),
          ),
          ButtonSegment(
            value: QiblaMode.map,
            icon: const Icon(Icons.public, size: 18),
            label: Text('mode_map'.tr),
          ),
        ],
        selected: {controller.mode},
        onSelectionChanged: (s) => unawaited(controller.setMode(s.first)),
      ),
    );
  }
}

final class _LocationPrompt extends GetView<QiblaViewModel> {
  const _LocationPrompt();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsetsDirectional.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 16,
        children: [
          const Icon(Icons.location_on_outlined, size: 48),
          Text('qibla_location_needed'.tr, textAlign: TextAlign.center),
          FilledButton(
            onPressed: () => unawaited(controller.onLocationAction()),
            child: Text(controller.locationActionKey.tr),
          ),
        ],
      ),
    ),
  );
}

void showCalibrationSheet(BuildContext context) => unawaited(
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Row(
              spacing: 12,
              children: [
                const Icon(Icons.all_inclusive, size: 32, color: AppColors.primaryContainer),
                Text('figure8_title'.tr, style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            Text('figure8_body'.tr, style: const TextStyle(height: 1.5)),
            Text(
              'figure8_note'.tr,
              style: TextStyle(height: 1.5, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    ),
  ),
);

void showAccuracySheet(BuildContext context, QiblaViewModel vm) {
  unawaited(
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Obx(
          () => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 8),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('accuracy_title'.tr, style: Theme.of(context).textTheme.titleLarge),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.sensors),
                title: Text('accuracy_sensor'.tr),
                trailing: Text(
                  vm.accuracy == null
                      ? 'accuracy_unknown'.tr
                      : 'accuracy_value'.trParams({'deg': vm.accuracy!.round().toString()}),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.near_me_outlined),
                title: Text('qibla_bearing_label'.tr),
                trailing: Text(vm.bearingLabel),
              ),
              ListTile(
                leading: const Icon(Icons.explore_outlined),
                title: Text('declination_label'.tr),
                trailing: Text(vm.declinationLabel),
              ),
              ListTile(
                leading: const Icon(Icons.straighten),
                title: Text('distance_label'.tr),
                trailing: Text(vm.distanceLabel),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(24, 4, 24, 16),
                child: Text(
                  'accuracy_explainer'.tr,
                  style: TextStyle(
                    height: 1.5,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
