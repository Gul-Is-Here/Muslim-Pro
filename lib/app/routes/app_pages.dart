import 'package:get/get.dart';
import 'package:quran_pro/app/middlewares/auth_middleware.dart';
import 'package:quran_pro/app/routes/app_routes.dart';
import 'package:quran_pro/features/adhkar/bindings/adhkar_binding.dart';
import 'package:quran_pro/features/adhkar/views/adhkar_view.dart';
import 'package:quran_pro/features/auth/bindings/auth_binding.dart';
import 'package:quran_pro/features/auth/views/auth_view.dart';
import 'package:quran_pro/features/auth/views/forgot_password_view.dart';
import 'package:quran_pro/features/auth/views/sign_up_view.dart';
import 'package:quran_pro/features/home/bindings/home_binding.dart';
import 'package:quran_pro/features/home/views/home_view.dart';
import 'package:quran_pro/features/learn/bindings/learn_binding.dart';
import 'package:quran_pro/features/learn/views/learn_view.dart';
import 'package:quran_pro/features/learn/views/lesson_view.dart';
import 'package:quran_pro/features/more/bindings/more_binding.dart';
import 'package:quran_pro/features/more/views/more_view.dart';
import 'package:quran_pro/features/onboarding/bindings/onboarding_binding.dart';
import 'package:quran_pro/features/onboarding/views/onboarding_view.dart';
import 'package:quran_pro/features/prayer_times/bindings/prayer_times_binding.dart';
import 'package:quran_pro/features/prayer_times/views/prayer_times_view.dart';
import 'package:quran_pro/features/qibla/bindings/qibla_binding.dart';
import 'package:quran_pro/features/qibla/views/qibla_view.dart';
import 'package:quran_pro/features/quran/bindings/quran_binding.dart';
import 'package:quran_pro/features/quran/bindings/surah_reader_binding.dart';
import 'package:quran_pro/features/quran/views/quran_view.dart';
import 'package:quran_pro/features/quran/views/surah_reader_view.dart';
import 'package:quran_pro/features/ramadan/bindings/ramadan_binding.dart';
import 'package:quran_pro/features/ramadan/views/ramadan_view.dart';
import 'package:quran_pro/features/settings/bindings/prayer_notifications_binding.dart';
import 'package:quran_pro/features/settings/views/prayer_notifications_view.dart';
import 'package:quran_pro/features/splash/bindings/splash_binding.dart';
import 'package:quran_pro/features/splash/views/splash_view.dart';
import 'package:quran_pro/features/tasbeeh/bindings/tasbeeh_binding.dart';
import 'package:quran_pro/features/tasbeeh/views/tasbeeh_view.dart';

abstract final class AppPages {
  static const String initial = AppRoutes.splash; // then Home; AuthMiddleware redirects as needed

  static final List<GetPage<dynamic>> routes = [
    GetPage(name: AppRoutes.splash, page: () => const SplashView(), binding: SplashBinding()),
    GetPage(
      name: AppRoutes.onboarding,
      page: () => const OnboardingView(),
      binding: OnboardingBinding(),
    ),
    GetPage(name: AppRoutes.auth, page: () => const AuthView(), binding: AuthBinding()),
    GetPage(name: AppRoutes.signUp, page: () => const SignUpView(), binding: SignUpBinding()),
    GetPage(
      name: AppRoutes.forgotPassword,
      page: () => const ForgotPasswordView(),
      binding: ForgotPasswordBinding(),
    ),
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
      name: AppRoutes.learn,
      page: () => const LearnView(),
      binding: LearnBinding(),
      transition: Transition.fadeIn,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.lesson,
      page: () => const LessonView(),
      binding: LessonBinding(),
      transition: Transition.downToUp,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.quran,
      page: () => const QuranView(),
      binding: QuranBinding(),
      transition: Transition.fadeIn,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.surah,
      page: () => const SurahReaderView(),
      binding: SurahReaderBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.ramadan,
      page: () => const RamadanView(),
      binding: RamadanBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.adhkar,
      page: () => const AdhkarView(),
      binding: AdhkarBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.more,
      page: () => const MoreView(),
      binding: MoreBinding(),
      transition: Transition.fadeIn,
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
