import 'package:get/get.dart';
import 'package:quran_pro/features/home/viewmodels/home_view_model.dart';
import 'package:quran_pro/features/prayer_times/bindings/prayer_times_binding.dart';

final class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => HomeViewModel(Get.find(), Get.find(), Get.find(), Get.find(), Get.find()),
      fenix: true,
    );
    PrayerTimesBinding()
        .dependencies(); // the hero card and prayer strip share the feature ViewModel
  }
}
