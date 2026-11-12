import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_pro/core/utils/formatters.dart';
import 'package:quran_pro/features/prayer_times/viewmodels/prayer_times_view_model.dart';

final class NextPrayerCard extends GetView<PrayerTimesViewModel> {
  const NextPrayerCard({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    // Outer Obx depends on `next` (changes ~5×/day); inner Obx alone ticks every second.
    return Obx(
      () => controller.next == null
          ? const SizedBox.shrink()
          : Card(
              child: Padding(
                padding: const EdgeInsetsDirectional.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(controller.nextLabel, style: text.titleMedium),
                    const SizedBox(height: 8),
                    Obx(
                      () => Text(
                        Formatters.countdown(controller.remaining),
                        style: text.displaySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
