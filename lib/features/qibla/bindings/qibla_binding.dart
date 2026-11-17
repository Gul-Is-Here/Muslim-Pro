import 'package:get/get.dart';
import 'package:quran_pro/features/qibla/viewmodels/qibla_view_model.dart';

final class QiblaBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => QiblaViewModel(Get.find(), Get.find(), Get.find(), Get.find(), Get.find(), Get.find()),
    );
  }
}
