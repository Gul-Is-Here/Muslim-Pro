import 'package:get/get.dart';
import 'package:quran_pro/features/learn/viewmodels/learn_view_model.dart';
import 'package:quran_pro/features/learn/viewmodels/lesson_view_model.dart';

final class LearnBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut(() => LearnViewModel(Get.find(), Get.find(), Get.find()));
}

final class LessonBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut(
    () => LessonViewModel(
      Get.find(),
      Get.find(),
      Get.find(),
      (Get.arguments as LessonArgs?) ?? (lessonId: null, review: false),
    ),
  );
}
