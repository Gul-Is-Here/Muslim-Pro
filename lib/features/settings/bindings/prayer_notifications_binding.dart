import 'package:get/get.dart';
import 'package:quran_pro/features/settings/viewmodels/prayer_notifications_view_model.dart';

final class PrayerNotificationsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () =>
          PrayerNotificationsViewModel(Get.find(), Get.find(), Get.find(), Get.find(), Get.find()),
    );
  }
}
