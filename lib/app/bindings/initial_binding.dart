import 'dart:io';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:quran_pro/app/session/session_controller.dart';
import 'package:quran_pro/core/network/connectivity_service.dart';
import 'package:quran_pro/core/services/adhkar_service.dart';
import 'package:quran_pro/core/services/audio_service.dart';
import 'package:quran_pro/core/services/auth_service.dart';
import 'package:quran_pro/core/services/compass_service.dart';
import 'package:quran_pro/core/services/learn_service.dart';
import 'package:quran_pro/core/services/location_service.dart';
import 'package:quran_pro/core/services/location_sync_service.dart';
import 'package:quran_pro/core/services/maps_service.dart';
import 'package:quran_pro/core/services/notification_service.dart';
import 'package:quran_pro/core/services/prayer_schedule_service.dart';
import 'package:quran_pro/core/services/quran_service.dart';
import 'package:quran_pro/core/services/ramadan_service.dart';
import 'package:quran_pro/core/services/settings_service.dart';
import 'package:quran_pro/core/services/surah_download_service.dart';
import 'package:quran_pro/core/services/tasbeeh_service.dart';
import 'package:quran_pro/data/datasources/local/adhkar_local_ds.dart';
import 'package:quran_pro/data/datasources/local/learn_local_ds.dart';
import 'package:quran_pro/data/datasources/local/prayer_calc_local_ds.dart';
import 'package:quran_pro/data/datasources/local/qibla_local_ds.dart';
import 'package:quran_pro/data/datasources/local/quran_audio_files.dart';
import 'package:quran_pro/data/datasources/local/quran_local_ds.dart';
import 'package:quran_pro/data/datasources/remote/auth_remote_ds.dart';
import 'package:quran_pro/data/repositories/adhkar_repository_impl.dart';
import 'package:quran_pro/data/repositories/auth_repository_impl.dart';
import 'package:quran_pro/data/repositories/learn_repository_impl.dart';
import 'package:quran_pro/data/repositories/prayer_times_repository_impl.dart';
import 'package:quran_pro/data/repositories/qibla_repository_impl.dart';
import 'package:quran_pro/data/repositories/quran_audio_repository_impl.dart';
import 'package:quran_pro/data/repositories/quran_repository_impl.dart';
import 'package:quran_pro/domain/repositories/adhkar_repository.dart';
import 'package:quran_pro/domain/repositories/auth_repository.dart';
import 'package:quran_pro/domain/repositories/learn_repository.dart';
import 'package:quran_pro/domain/repositories/prayer_times_repository.dart';
import 'package:quran_pro/domain/repositories/qibla_repository.dart';
import 'package:quran_pro/domain/repositories/quran_audio_repository.dart';
import 'package:quran_pro/domain/repositories/quran_repository.dart';

/// Registered once from bootstrap(), before runApp. Feature ViewModels belong in feature bindings.
final class InitialBinding extends Bindings {
  InitialBinding({required this.appSupportDir});

  final Directory appSupportDir;

  @override
  void dependencies() {
    final recitations = QuranAudioFiles(
      Directory('${appSupportDir.path}/recitations/${QuranAudioRepositoryImpl.defaultReciter}'),
    );
    final quranAudio = QuranAudioRepositoryImpl(files: recitations);
    Get
      // Repositories: stateless, created on first use.
      ..lazyPut<AuthRepository>(() => AuthRepositoryImpl(AuthRemoteDataSource()), fenix: true)
      ..lazyPut<PrayerTimesRepository>(
        () => const PrayerTimesRepositoryImpl(PrayerCalcLocalDataSource()),
        fenix: true,
      )
      ..lazyPut<QiblaRepository>(
        () => const QiblaRepositoryImpl(PrayerCalcLocalDataSource(), QiblaLocalDataSource()),
        fenix: true,
      )
      ..put<QuranAudioRepository>(quranAudio, permanent: true)
      ..lazyPut<AdhkarRepository>(
        () => const AdhkarRepositoryImpl(AdhkarLocalDataSource()),
        fenix: true,
      )
      ..lazyPut<QuranRepository>(
        () => const QuranRepositoryImpl(QuranLocalDataSource()),
        fenix: true,
      )
      ..lazyPut<LearnRepository>(
        () => const LearnRepositoryImpl(LearnLocalDataSource()),
        fenix: true,
      )
      // App-wide state: permanent.
      ..put(SettingsService(GetStorage()), permanent: true)
      ..put(ConnectivityService(), permanent: true)
      ..put(TasbeehService(GetStorage()), permanent: true)
      ..put(LearnService(Get.find(), GetStorage()), permanent: true)
      ..put(QuranService(GetStorage()), permanent: true)
      ..put(RamadanService(GetStorage()), permanent: true)
      ..put(AdhkarService(Get.find(), GetStorage()), permanent: true)
      ..put(
        SurahDownloadService(recitations, (s, a) => quranAudio.remoteAyahAudio(surah: s, ayah: a)),
        permanent: true,
      )
      ..put(AuthService(Get.find()), permanent: true)
      // Other services. SmartManagement never disposes a GetxService.
      ..lazyPut(LocationService.new, fenix: true)
      ..lazyPut(() => LocationSyncService(Get.find(), Get.find()), fenix: true)
      ..lazyPut(CompassService.new, fenix: true)
      ..lazyPut(MapsService.new, fenix: true)
      ..lazyPut(() => AudioService(Get.find()), fenix: true)
      ..put(NotificationService())
      ..put(PrayerScheduleService(Get.find(), Get.find(), Get.find()))
      ..put(SessionController(Get.find()));
  }
}
