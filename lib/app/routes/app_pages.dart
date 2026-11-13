import 'package:get/get.dart';
import 'package:quran_pro/app/middlewares/auth_middleware.dart';
import 'package:quran_pro/app/routes/app_routes.dart';
import 'package:quran_pro/features/auth/bindings/auth_binding.dart';
import 'package:quran_pro/features/auth/views/auth_view.dart';
import 'package:quran_pro/features/home/bindings/home_binding.dart';
import 'package:quran_pro/features/home/views/home_view.dart';
import 'package:quran_pro/features/onboarding/bindings/onboarding_binding.dart';
import 'package:quran_pro/features/onboarding/views/onboarding_view.dart';
import 'package:quran_pro/features/prayer_times/bindings/prayer_times_binding.dart';
import 'package:quran_pro/features/prayer_times/views/prayer_times_view.dart';
import 'package:quran_pro/features/qibla/bindings/qibla_binding.dart';
import 'package:quran_pro/features/qibla/views/qibla_view.dart';
import 'package:quran_pro/features/settings/bindings/prayer_notifications_binding.dart';
import 'package:quran_pro/features/settings/views/prayer_notifications_view.dart';
import 'package:quran_pro/features/tasbeeh/bindings/tasbeeh_binding.dart';
import 'package:quran_pro/features/tasbeeh/views/tasbeeh_view.dart';

abstract final class AppPages {
  static const String initial = AppRoutes.home; // AuthMiddleware redirects as needed

  static final List<GetPage<dynamic>> routes = [
    GetPage(
      name: AppRoutes.onboarding,
      page: () => const OnboardingView(),
      binding: OnboardingBinding(),
    ),
    GetPage(name: AppRoutes.auth, page: () => const AuthView(), binding: AuthBinding()),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeView(),
      binding: HomeBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.prayerTimes,
      page: () => const PrayerTimesView(),
      binding: PrayerTimesBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.prayerNotifications,
      page: () => const PrayerNotificationsView(),
      binding: PrayerNotificationsBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.qibla,
      page: () => const QiblaView(),
      binding: QiblaBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.tasbeeh,
      page: () => const TasbeehView(),
      binding: TasbeehBinding(),
      middlewares: [AuthMiddleware()],
    ),
  ];
}
