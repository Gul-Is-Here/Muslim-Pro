import 'package:get/get.dart';
import 'package:quran_pro/features/auth/viewmodels/auth_view_model.dart';

final class AuthBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut(() => AuthViewModel(Get.find()), fenix: true);
}
