import 'package:get/get.dart';
import 'package:quran_pro/features/ramadan/viewmodels/ramadan_view_model.dart';

final class RamadanBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut(
    () => RamadanViewModel(Get.find(), Get.find(), Get.find(), Get.find(), Get.find()),
  );
}
