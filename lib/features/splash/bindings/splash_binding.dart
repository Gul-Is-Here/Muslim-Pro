import 'package:get/get.dart';
import 'package:quran_pro/features/splash/viewmodels/splash_view_model.dart';

final class SplashBinding extends Bindings {
  @override
  void dependencies() {
    // Eager on purpose: the view never reads the controller, so a lazyPut would never
    // create it and the hand-off timer would never start.
    Get.put(SplashViewModel());
  }
}
