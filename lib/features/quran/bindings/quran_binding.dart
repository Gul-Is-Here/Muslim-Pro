import 'package:get/get.dart';
import 'package:quran_pro/features/quran/viewmodels/quran_view_model.dart';

final class QuranBinding extends Bindings {
  @override
  void dependencies() =>
      Get.lazyPut(() => QuranViewModel(Get.find(), Get.find(), Get.find(), Get.find(), Get.find()));
}
