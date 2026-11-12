import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_pro/core/network/connectivity_service.dart';

final class OfflineBanner extends GetView<ConnectivityService> {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) => Obx(
    () => controller.isOnline
        ? const SizedBox.shrink()
        : Material(
            color: Theme.of(context).colorScheme.errorContainer,
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsetsDirectional.all(8),
                  child: Semantics(
                    liveRegion: true,
                    child: Text('offline_banner'.tr, textAlign: TextAlign.center),
                  ),
                ),
              ),
            ),
          ),
  );
}
