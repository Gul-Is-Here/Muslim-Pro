import 'package:get/get.dart';
import 'package:quran_pro/features/auth/viewmodels/auth_view_model.dart';
import 'package:quran_pro/features/auth/viewmodels/forgot_password_view_model.dart';
import 'package:quran_pro/features/auth/viewmodels/sign_up_view_model.dart';

final class AuthBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut(() => AuthViewModel(Get.find()), fenix: true);
}

final class SignUpBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut(() => SignUpViewModel(Get.find()));
}

final class ForgotPasswordBinding extends Bindings {
  @override
  void dependencies() =>
      Get.lazyPut(() => ForgotPasswordViewModel(Get.find(), email: Get.arguments as String?));
}
