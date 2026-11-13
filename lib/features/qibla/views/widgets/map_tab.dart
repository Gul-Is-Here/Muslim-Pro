import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:quran_pro/core/theme/app_colors.dart';
import 'package:quran_pro/features/qibla/viewmodels/qibla_view_model.dart';
import 'package:quran_pro/features/qibla/views/qibla_view.dart';

final class MapTab extends GetView<QiblaViewModel> {
  const MapTab({super.key});

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Obx(() {
        final user = controller.userLatLng;
        return switch (controller.mapsReady) {
          null => const ColoredBox(
            color: AppColors.jewelBottom,
            child: Center(child: CircularProgressIndicator()),
          ),
          false => _MapUnavailable(configured: controller.mapsConfigured),
          true when user == null => const SizedBox.shrink(),
          true => _QiblaMap(user: user!),
        };
      }),
      const SafeArea(
        child: Column(
          children: [
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsetsDirectional.symmetric(horizontal: 20),
              child: QiblaModeSwitcher(onImage: true),
            ),
            Spacer(),
            _RouteCard(),
          ],
        ),
      ),
    ],
  );
}

final class _QiblaMap extends StatelessWidget {
  const _QiblaMap({required this.user});

  final LatLng user;

  @override
  Widget build(BuildContext context) {
    final kaaba = QiblaViewModel.kaabaLatLng;
    final bounds = LatLngBounds(
      southwest: LatLng(
        math.min(user.latitude, kaaba.latitude),
        math.min(user.longitude, kaaba.longitude),
      ),
      northeast: LatLng(
        math.max(user.latitude, kaaba.latitude),
        math.max(user.longitude, kaaba.longitude),
      ),
    );
    return GoogleMap(
      initialCameraPosition: CameraPosition(target: bounds.northeast, zoom: 2),
      onMapCreated: (map) => unawaited(
        // After the first frame so the map has a size to fit the bounds into.
        Future<void>.delayed(
          const Duration(milliseconds: 300),
          () => map.animateCamera(CameraUpdate.newLatLngBounds(bounds, 72)),
        ),
      ),
      myLocationButtonEnabled: false,
      mapToolbarEnabled: false,
      zoomControlsEnabled: false,
      padding: const EdgeInsets.only(top: 120, bottom: 140),
      markers: {
        Marker(
          markerId: const MarkerId('me'),
          position: user,
          infoWindow: InfoWindow(title: 'your_location'.tr),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
        Marker(
          markerId: const MarkerId('kaaba'),
          position: kaaba,
          infoWindow: InfoWindow(title: 'kaaba_makkah'.tr),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ),
      },
      polylines: {
        Polyline(
          polylineId: const PolylineId('qibla'),
          points: [user, kaaba],
          geodesic: true, // great circle: the true shortest path, curved on the flat map
          color: AppColors.amber500,
          width: 4,
        ),
      },
    );
  }
}

final class _MapUnavailable extends StatelessWidget {
  const _MapUnavailable({required this.configured});

  final bool configured;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.jewelBottom,
    child: Center(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            const Icon(Icons.map_outlined, size: 48, color: AppColors.emerald200),
            Text(
              (configured ? 'maps_failed' : 'maps_not_configured').tr,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, height: 1.5),
            ),
          ],
        ),
      ),
    ),
  );
}

final class _RouteCard extends GetView<QiblaViewModel> {
  const _RouteCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 12),
      padding: const EdgeInsetsDirectional.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 20)],
      ),
      child: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 6,
          children: [
            Row(
              spacing: 10,
              children: [
                const Icon(Icons.mosque, color: AppColors.amber600),
                Expanded(
                  child: Text(
                    'kaaba_makkah'.tr,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
                Text(controller.distanceLabel, style: const TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
            Text(
              'qibla_from_north'.trParams({'bearing': controller.bearingLabel}),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              'great_circle_note'.tr,
              style: TextStyle(fontSize: 12, height: 1.4, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
