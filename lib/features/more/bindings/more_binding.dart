import 'package:get/get.dart';
import 'package:quran_pro/features/more/viewmodels/more_view_model.dart';

final class MoreBinding extends Bindings {
  @override
  void dependencies() =>
      Get.lazyPut(() => MoreViewModel(Get.find(), Get.find(), Get.find(), Get.find(), Get.find()));
}
