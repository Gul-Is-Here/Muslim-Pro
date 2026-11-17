import 'package:get/get.dart';
import 'package:quran_pro/features/quran/viewmodels/surah_reader_view_model.dart';

final class SurahReaderBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut(
    () => SurahReaderViewModel(
      Get.find(),
      Get.find(),
      Get.find(),
      Get.find(),
      Get.find(),
      Get.find(),
      (Get.arguments as SurahArgs?) ?? (surah: 1, ayah: null),
    ),
  );
}
