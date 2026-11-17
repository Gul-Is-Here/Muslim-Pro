import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_pro/core/theme/app_colors.dart';
import 'package:quran_pro/core/utils/compass_math.dart';
import 'package:quran_pro/features/qibla/viewmodels/qibla_view_model.dart';
import 'package:quran_pro/features/qibla/views/qibla_view.dart';
import 'package:quran_pro/features/qibla/views/widgets/qibla_painters.dart';

const _glass = Color(0xA6283044);

final class ArTab extends GetView<QiblaViewModel> {
  const ArTab({super.key});

  @override
  Widget build(BuildContext context) => const Stack(
    fit: StackFit.expand,
    children: [
      _CameraLayer(),
      // Scrim keeps overlay text readable on any scene.
      IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xB3002F2A), Color(0x14002F2A), Color(0xD9002F2A)],
              stops: [0, 0.45, 1],
            ),
          ),
        ),
      ),
      SafeArea(
        child: Column(
          children: [
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsetsDirectional.symmetric(horizontal: 20),
              child: QiblaModeSwitcher(onImage: true),
            ),
            SizedBox(height: 10),
            _Telemetry(),
            // Shrinks the HUD on short screens instead of letting the bottom card cover it.
            Expanded(
              child: Center(
                child: FittedBox(fit: BoxFit.scaleDown, child: _Hud()),
              ),
            ),
            _BottomCard(),
          ],
        ),
      ),
    ],
  );
}

final class _CameraLayer extends GetView<QiblaViewModel> {
  const _CameraLayer();

  @override
  Widget build(BuildContext context) => Obx(() {
    final c = controller.camera;
    if (c == null || !c.value.isInitialized) {
      return const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.jewelTop, AppColors.jewelBottom],
          ),
        ),
      );
    }
    // Cover the screen like a viewfinder, keeping the preview's aspect ratio.
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: c.value.previewSize?.height ?? 1080,
          height: c.value.previewSize?.width ?? 1920,
          child: CameraPreview(c),
        ),
      ),
    );
  });
}

final class _Telemetry extends GetView<QiblaViewModel> {
  const _Telemetry();

  @override
  Widget build(BuildContext context) => Obx(() {
    final live = controller.cameraStatus == CameraStatus.on;
    return Container(
      margin: const EdgeInsetsDirectional.symmetric(horizontal: 20),
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: _glass, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: controller.needsCalibration ? AppColors.amber400 : const Color(0xFF4EDEA3),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              [
                if (controller.placeLabel.isNotEmpty) controller.placeLabel,
                if (controller.accuracy != null)
                  'accuracy_value'.trParams({'deg': controller.accuracy!.round().toString()}),
              ].join(' • '),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Icon(
            live ? Icons.videocam : Icons.videocam_off_outlined,
            size: 15,
            color: AppColors.amber200,
          ),
          const SizedBox(width: 4),
          Text(
            (live ? 'ar_live' : 'camera_off').tr,
            style: const TextStyle(
              color: AppColors.amber200,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  });
}

final class _Hud extends GetView<QiblaViewModel> {
  const _Hud();

  @override
  Widget build(BuildContext context) => Obx(() {
    final heading = controller.heading;
    final offset = controller.arOffset;
    final aligned = controller.aligned;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (heading != null) ...[
          SizedBox(
            width: 300,
            height: 52,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: HeadingRibbonPainter(
                      heading: heading,
                      qibla: controller.info?.bearing,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsetsDirectional.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.amber500,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    '${heading.round()}° ${CompassMath.cardinal(heading)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        Builder(
          builder: (context) {
            const size = 240.0;
            final inView = offset != null && offset.abs() <= 1;
            // Sideways position follows the angle; the reticle centre is straight ahead.
            final dx = (offset ?? 0).clamp(-1.0, 1.0) * (size / 2 - 40);
            return Semantics(
              label: controller.turnLabel,
              child: SizedBox.square(
                dimension: size,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const _Brackets(),
                    const Divider(color: Color(0x664EDEA3), thickness: 1),
                    const VerticalDivider(color: Color(0x664EDEA3), thickness: 1),
                    if (offset != null && inView)
                      Transform.translate(
                        offset: Offset(dx, 0),
                        child: _KaabaBeacon(aligned: aligned),
                      ),
                    if (offset != null && !inView)
                      Align(
                        alignment: offset > 0 ? Alignment.centerRight : Alignment.centerLeft,
                        child: Icon(
                          offset > 0
                              ? Icons.keyboard_double_arrow_right
                              : Icons.keyboard_double_arrow_left,
                          size: 48,
                          color: AppColors.amber400,
                        ),
                      ),
                    if (offset == null)
                      const CircularProgressIndicator(color: Colors.white54, strokeWidth: 2),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: aligned ? const Color(0xE6004930) : _glass,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              Icon(
                aligned ? Icons.verified : Icons.explore,
                size: 16,
                color: aligned ? const Color(0xFF24C189) : AppColors.amber300,
              ),
              Text(
                controller.turnLabel.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: aligned ? const Color(0xFF24C189) : Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 12, vertical: 3),
          decoration: BoxDecoration(color: _glass, borderRadius: BorderRadius.circular(99)),
          child: Text(
            '${'masjid_haram'.tr} • ${controller.distanceLabel} • ${controller.bearingLabel}',
            style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  });
}

final class _Brackets extends StatelessWidget {
  const _Brackets();

  @override
  Widget build(BuildContext context) {
    const side = BorderSide(color: Color(0xFF4EDEA3), width: 3);
    Widget corner(Alignment a, Border b) => Align(
      alignment: a,
      child: Container(width: 24, height: 24, decoration: BoxDecoration(border: b)),
    );
    return Stack(
      children: [
        corner(Alignment.topLeft, const Border(top: side, left: side)),
        corner(Alignment.topRight, const Border(top: side, right: side)),
        corner(Alignment.bottomLeft, const Border(bottom: side, left: side)),
        corner(Alignment.bottomRight, const Border(bottom: side, right: side)),
      ],
    );
  }
}

final class _KaabaBeacon extends StatelessWidget {
  const _KaabaBeacon({required this.aligned});

  final bool aligned;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(color: AppColors.amber500, shape: BoxShape.circle),
        child: const Icon(Icons.north, size: 18, color: Colors.white),
      ),
      const SizedBox(height: 4),
      AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryContainer, AppColors.primary, Color(0xFF283044)],
          ),
          boxShadow: [
            BoxShadow(
              color: (aligned ? const Color(0xFF4EDEA3) : AppColors.amber300).withValues(
                alpha: 0.55,
              ),
              blurRadius: aligned ? 28 : 14,
            ),
          ],
        ),
        child: const Icon(Icons.mosque, size: 36, color: Color(0xFFFFDCC3)),
      ),
    ],
  );
}

final class _BottomCard extends GetView<QiblaViewModel> {
  const _BottomCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final translation = 'ayah_2_144_translation'.tr;
    return Container(
      margin: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 12),
      padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 16, 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 24)],
      ),
      child: Obx(() {
        final status = controller.cameraStatus;
        final live = status == CameraStatus.on;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              spacing: 10,
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primaryContainer,
                  child: Icon(Icons.vibration, size: 18, color: Color(0xFF80B5AB)),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (controller.aligned ? 'ar_aligned_title' : 'ar_find_title').tr,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                      Text(switch (status) {
                        CameraStatus.denied => 'camera_denied'.tr,
                        CameraStatus.unavailable => 'camera_unavailable'.tr,
                        _ => 'ar_hint'.tr,
                      }, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                ActionChip(
                  visualDensity: VisualDensity.compact,
                  avatar: Icon(controller.haptics ? Icons.vibration : Icons.mobile_off, size: 14),
                  label: Text((controller.haptics ? 'haptic_on_short' : 'haptic_off_short').tr),
                  onPressed: controller.toggleHaptics,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsetsDirectional.all(10),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 2,
                children: [
                  const Text(
                    'فَوَلِّ وَجْهَكَ شَطْرَ الْمَسْجِدِ الْحَرَامِ ۚ وَحَيْثُ مَا كُنْتُمْ فَوَلُّوا وُجُوهَكُمْ شَطْرَهُ',
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'Amiri', fontSize: 17, height: 1.8),
                  ),
                  if (translation.isNotEmpty)
                    Text(
                      translation,
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  Text(
                    'ayah_2_144_ref'.tr,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.amber700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              spacing: 8,
              children: [
                Expanded(
                  child: _Utility(
                    icon: controller.torchOn ? Icons.flash_on : Icons.flash_off,
                    label: 'torch'.tr,
                    active: controller.torchOn,
                    onTap: live ? controller.toggleTorch : null,
                  ),
                ),
                Expanded(
                  child: _Utility(
                    icon: Icons.rotate_right,
                    label: 'recalibrate'.tr,
                    onTap: () async => showCalibrationSheet(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryContainer,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: switch (status) {
                CameraStatus.starting => null,
                CameraStatus.denied => () => unawaited(controller.openAppSettings()),
                _ => () => unawaited(controller.toggleLiveView()),
              },
              icon: status == CameraStatus.starting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(live ? Icons.videocam_off_outlined : Icons.photo_camera_outlined),
              label: Text(
                switch (status) {
                  CameraStatus.on => 'stop_live_view',
                  CameraStatus.denied => 'open_app_settings',
                  _ => 'start_live_view',
                }.tr,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            TextButton(
              onPressed: () => unawaited(controller.setMode(QiblaMode.compass)),
              child: Text.rich(
                TextSpan(
                  text: '${'switch_to_dial_q'.tr} ',
                  style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                  children: [
                    TextSpan(
                      text: 'switch_to_dial'.tr,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

final class _Utility extends StatelessWidget {
  const _Utility({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final Future<void> Function()? onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: active ? AppColors.amber500 : scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap == null ? null : () => unawaited(onTap!()),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 6,
            children: [
              Icon(
                icon,
                size: 18,
                color: onTap == null
                    ? scheme.outline
                    : (active ? Colors.white : AppColors.amber700),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: onTap == null
                      ? scheme.outline
                      : (active ? Colors.white : scheme.onSurface),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
