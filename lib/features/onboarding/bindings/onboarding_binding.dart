import 'package:get/get.dart';
import 'package:quran_pro/features/onboarding/viewmodels/onboarding_view_model.dart';

final class OnboardingBinding extends Bindings {
  @override
  void dependencies() =>
      Get.lazyPut(() => OnboardingViewModel(Get.find(), Get.find()), fenix: true);
}
