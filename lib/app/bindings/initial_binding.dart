import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:quran_pro/app/session/session_controller.dart';
import 'package:quran_pro/core/network/connectivity_service.dart';
import 'package:quran_pro/core/services/audio_service.dart';
import 'package:quran_pro/core/services/auth_service.dart';
import 'package:quran_pro/core/services/location_service.dart';
import 'package:quran_pro/core/services/notification_service.dart';
import 'package:quran_pro/core/services/prayer_schedule_service.dart';
import 'package:quran_pro/core/services/settings_service.dart';
import 'package:quran_pro/data/datasources/local/prayer_calc_local_ds.dart';
import 'package:quran_pro/data/datasources/remote/auth_remote_ds.dart';
import 'package:quran_pro/data/repositories/auth_repository_impl.dart';
import 'package:quran_pro/data/repositories/prayer_times_repository_impl.dart';
import 'package:quran_pro/domain/repositories/auth_repository.dart';
import 'package:quran_pro/domain/repositories/prayer_times_repository.dart';

/// Registered once from bootstrap(), before runApp. Feature ViewModels belong in feature bindings.
final class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get
      // Repositories: stateless, created on first use.
      ..lazyPut<AuthRepository>(() => AuthRepositoryImpl(AuthRemoteDataSource()), fenix: true)
      ..lazyPut<PrayerTimesRepository>(
        () => const PrayerTimesRepositoryImpl(PrayerCalcLocalDataSource()),
        fenix: true,
      )
      // App-wide state: permanent.
      ..put(SettingsService(GetStorage()), permanent: true)
      ..put(ConnectivityService(), permanent: true)
      ..put(AuthService(Get.find()), permanent: true)
      // Other services. SmartManagement never disposes a GetxService.
      ..lazyPut(LocationService.new, fenix: true)
      ..lazyPut(AudioService.new, fenix: true)
      ..put(NotificationService())
      ..put(PrayerScheduleService(Get.find(), Get.find(), Get.find()))
      ..put(SessionController(Get.find()));
  }
}
