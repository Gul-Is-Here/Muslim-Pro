import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_pro/core/utils/formatters.dart';
import 'package:quran_pro/core/utils/view_state.dart';
import 'package:quran_pro/core/widgets/error_retry.dart';
import 'package:quran_pro/data/models/prayer.dart';
import 'package:quran_pro/features/prayer_times/viewmodels/prayer_times_view_model.dart';
import 'package:quran_pro/features/prayer_times/views/widgets/next_prayer_card.dart';

final class PrayerTimesView extends GetView<PrayerTimesViewModel> {
  const PrayerTimesView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('prayer_times'.tr)),
    body: Obx(
      () => switch (controller.state) {
        Idle() || Loading() => const Center(child: CircularProgressIndicator()),
        Empty() => const _LocationRationale(),
        ViewError(:final messageKey) => ErrorRetry(
          messageKey: messageKey,
          onRetry: controller.load,
        ),
        Success(:final data) => RefreshIndicator(
          onRefresh: controller.load,
          child: ListView(
            padding: const EdgeInsetsDirectional.all(16),
            children: [
              const NextPrayerCard(),
              for (final p in Prayer.values) _PrayerRow(prayer: p, at: data.times[p]!),
            ],
          ),
        ),
      },
    ),
  );
}

final class _PrayerRow extends GetView<PrayerTimesViewModel> {
  const _PrayerRow({required this.prayer, required this.at});

  final Prayer prayer;
  final DateTime at;

  @override
  Widget build(BuildContext context) => Obx(
    () => ListTile(
      selected: controller.next?.prayer == prayer,
      title: Text(prayer.labelKey.tr),
      trailing: Text(Formatters.time(at)),
    ),
  );
}

final class _LocationRationale extends GetView<PrayerTimesViewModel> {
  const _LocationRationale();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsetsDirectional.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on_outlined, size: 48),
          const SizedBox(height: 16),
          Text('location_rationale'.tr, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Obx(
            () => FilledButton(
              onPressed: controller.onPermissionAction,
              child: Text(controller.permissionActionKey.tr),
            ),
          ),
        ],
      ),
    ),
  );
}
