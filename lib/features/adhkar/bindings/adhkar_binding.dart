import 'package:get/get.dart';
import 'package:quran_pro/data/models/adhkar.dart';
import 'package:quran_pro/features/adhkar/viewmodels/adhkar_view_model.dart';

final class AdhkarBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut(
    () => AdhkarViewModel(
      Get.find(),
      Get.find(),
      (Get.arguments as AdhkarCategory?) ?? AdhkarViewModel.forNow,
    ),
  );
}
