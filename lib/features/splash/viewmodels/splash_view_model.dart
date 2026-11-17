import 'dart:async';

import 'package:get/get.dart';
import 'package:quran_pro/app/routes/app_routes.dart';

/// Holds the brand mark long enough to be read, then hands over to Home
/// (AuthMiddleware sends new users to sign-in or onboarding from there).
final class SplashViewModel extends GetxController {
  SplashViewModel({this.hold = const Duration(milliseconds: 2200)});

  final Duration hold;
  Timer? _timer;

  @override
  void onReady() {
    super.onReady();
    _timer = Timer(hold, () => unawaited(Get.offAllNamed<void>(AppRoutes.home)));
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
