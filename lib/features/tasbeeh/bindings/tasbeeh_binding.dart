import 'package:get/get.dart';
import 'package:quran_pro/features/tasbeeh/viewmodels/tasbeeh_view_model.dart';

final class TasbeehBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut(() => TasbeehViewModel(Get.find()));
}
