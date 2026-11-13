import 'package:get/get.dart';
import 'package:quran_pro/features/prayer_times/viewmodels/prayer_times_view_model.dart';

final class PrayerTimesBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut(
    () => PrayerTimesViewModel(Get.find(), Get.find(), Get.find(), Get.find()),
    fenix: true,
  );
}
