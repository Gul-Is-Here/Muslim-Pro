import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:quran_pro/core/errors/result.dart';
import 'package:quran_pro/core/services/compass_service.dart';
import 'package:quran_pro/core/services/location_service.dart';
import 'package:quran_pro/core/services/location_sync_service.dart';
import 'package:quran_pro/core/services/maps_service.dart';
import 'package:quran_pro/core/services/settings_service.dart';
import 'package:quran_pro/core/utils/app_log.dart';
import 'package:quran_pro/core/utils/compass_math.dart';
import 'package:quran_pro/data/models/user_location.dart';
import 'package:quran_pro/domain/repositories/qibla_repository.dart';

enum QiblaMode { compass, ar, map }

enum CameraStatus { off, starting, on, denied, unavailable }

final class QiblaViewModel extends GetxController {
  QiblaViewModel(
    this._settings,
    this._location,
    this._sync,
    this._compass,
    this._maps,
    this._qibla,
  );

  /// Within this many degrees counts as facing the Qibla.
  static const alignedWithin = 5.0;

  /// shortcut: assumed horizontal field of view of a phone's main camera in portrait (real ones
  /// are ~50–70°). Only the marker's sideways position uses it; read the real FOV from
  /// CameraX/AVFoundation if the marker needs to sit exactly on landmarks.
  static const arFieldOfView = 60.0;

  final SettingsService _settings;
  final LocationService _location;
  final LocationSyncService _sync;
  final CompassService _compass;
  final MapsService _maps;
  final QiblaRepository _qibla;

  final Rx<QiblaMode> _mode = QiblaMode.compass.obs;
  final Rxn<UserLocation> _loc = Rxn<UserLocation>();
  final Rxn<QiblaInfo> _info = Rxn<QiblaInfo>();
  final Rxn<LocationAccess> _access = Rxn<LocationAccess>();
  final RxnDouble _heading = RxnDouble();
  final RxnDouble _accuracy = RxnDouble();
  final RxBool _aligned = false.obs;
  final RxBool _haptics = true.obs;
  final Rxn<CameraController> _camera = Rxn<CameraController>();
  final Rx<CameraStatus> _cameraStatus = CameraStatus.off.obs;
  final RxBool _torch = false.obs;
  final RxnBool _mapsReady = RxnBool();
  StreamSubscription<Heading>? _sub;
  AppLifecycleListener? _lifecycle;

  QiblaMode get mode => _mode.value;
  UserLocation? get location => _loc.value;
  QiblaInfo? get info => _info.value;
  bool get compassAvailable => _compass.available;
  double? get heading => _heading.value;
  bool get aligned => _aligned.value;
  bool get haptics => _haptics.value;
  CameraController? get camera => _camera.value;
  CameraStatus get cameraStatus => _cameraStatus.value;
  bool get torchOn => _torch.value;
  bool? get mapsReady => _mapsReady.value;
  bool get mapsConfigured => _maps.configured;
  String get placeLabel => _settings.placeName ?? 'your_location'.tr;

  /// Location is missing and the user must act (allow / settings) before anything works.
  bool get needsLocation => _loc.value == null && _access.value != null;
  String get locationActionKey => switch (_access.value) {
    LocationAccess.permanentlyDenied => 'open_app_settings',
    LocationAccess.serviceDisabled => 'open_location_settings',
    _ => 'allow_location',
  };

  /// ± degrees; null when the sensor has not reported it.
  double? get accuracy => _accuracy.value;
  bool get needsCalibration => (_accuracy.value ?? 0) > 30;

  /// Signed turn to face the Qibla: positive = turn right.
  double? get turn {
    final h = _heading.value;
    final q = _info.value?.bearing;
    return h == null || q == null ? null : CompassMath.turn(h, q);
  }

  /// Where the Kaaba sits across the camera view: -1 left edge … 0 centre … 1 right edge.
  /// Beyond ±1 it is off-screen (the view shows an edge arrow).
  double? get arOffset => turn == null ? null : turn! / (arFieldOfView / 2);

  String get bearingLabel {
    final b = _info.value?.bearing;
    return b == null ? '--' : '${b.round()}° ${CompassMath.cardinal(b)}';
  }

  String get distanceLabel {
    final km = _info.value?.distanceKm;
    return km == null
        ? '--'
        : 'km_value'.trParams({
            'km': NumberFormat.decimalPattern(Get.locale?.languageCode).format(km.round()),
          });
  }

  String get declinationLabel {
    final d = _info.value?.declination;
    if (d == null) return '--';
    return '${d.abs().toStringAsFixed(1)}° ${(d >= 0 ? 'east_short' : 'west_short').tr}';
  }

  String get turnLabel {
    final t = turn;
    if (t == null) return 'compass_waiting'.tr;
    if (_aligned.value) return 'qibla_aligned'.tr;
    return (t > 0 ? 'turn_right' : 'turn_left').trParams({'deg': t.abs().round().toString()});
  }

  LatLng? get userLatLng => _loc.value == null ? null : LatLng(_loc.value!.lat, _loc.value!.lng);
  static final LatLng kaabaLatLng = LatLng(kaabaLocation.lat, kaabaLocation.lng);

  @override
  void onInit() {
    super.onInit();
    _lifecycle = AppLifecycleListener(
      onHide: () => unawaited(stopLiveView()), // never keep the camera on in the background
      onResume: () => unawaited(_loadLocation()), // back from Settings
    );
    _sub = _compass.headings(() => _info.value?.declination ?? 0)?.listen(_onHeading);
    unawaited(_loadLocation());
  }

  Future<void> setMode(QiblaMode m) async {
    if (m == _mode.value) return;
    if (_mode.value == QiblaMode.ar) await stopLiveView();
    _mode.value = m;
    _heading.value = null; // compass and AR read different device axes: don't blend them
    _aligned.value = false;
    if (m == QiblaMode.map) _mapsReady.value = await _maps.ensureReady();
  }

  Future<void> onLocationAction() async {
    switch (_access.value) {
      case LocationAccess.permanentlyDenied:
        await _location.openAppSettings();
      case LocationAccess.serviceDisabled:
        await _location.openLocationSettings();
      case LocationAccess.denied || LocationAccess.granted || null:
        _access.value = await _location.request();
        await _loadLocation();
    }
  }

  void toggleHaptics() => _haptics.toggle();
  Future<void> testHaptic() => HapticFeedback.mediumImpact();
  Future<bool> openAppSettings() => _location.openAppSettings();

  Future<void> toggleLiveView() => _camera.value == null ? startLiveView() : stopLiveView();

  Future<void> startLiveView() async {
    if (_cameraStatus.value == CameraStatus.starting || _camera.value != null) return;
    _cameraStatus.value = CameraStatus.starting;
    try {
      final back = (await availableCameras()).where(
        (c) => c.lensDirection == CameraLensDirection.back,
      );
      if (back.isEmpty) {
        _cameraStatus.value = CameraStatus.unavailable;
        return;
      }
      final c = CameraController(back.first, ResolutionPreset.high, enableAudio: false);
      await c.initialize();
      if (_mode.value != QiblaMode.ar || isClosed) {
        await c.dispose(); // user left AR while the camera was starting
        _cameraStatus.value = CameraStatus.off;
        return;
      }
      _camera.value = c;
      _cameraStatus.value = CameraStatus.on;
    } on CameraException catch (e) {
      AppLog.w('Camera unavailable: ${e.code}');
      _cameraStatus.value = e.code.startsWith('CameraAccess')
          ? CameraStatus.denied
          : CameraStatus.unavailable;
    }
  }

  Future<void> stopLiveView() async {
    final c = _camera.value;
    _camera.value = null;
    _torch.value = false;
    if (_cameraStatus.value != CameraStatus.denied) _cameraStatus.value = CameraStatus.off;
    await c?.dispose(); // also turns the torch off
  }

  Future<void> toggleTorch() async {
    final c = _camera.value;
    if (c == null) return;
    try {
      await c.setFlashMode(_torch.value ? FlashMode.off : FlashMode.torch);
      _torch.toggle();
    } on CameraException catch (e) {
      AppLog.w('Torch unavailable: ${e.code}'); // e.g. no flash on this camera
    }
  }

  Future<void> _loadLocation() async {
    _setLocation(_settings.lastLocation); // cached: shows instantly, works offline
    _access.value = await _sync.sync();
    _setLocation(_settings.lastLocation);
  }

  void _setLocation(UserLocation? loc) {
    _loc.value = loc;
    _info.value = loc == null
        ? null
        : switch (_qibla.infoFor(loc, DateTime.now())) {
            Ok(:final value) => value,
            Err() => null,
          };
  }

  void _onHeading(Heading h) {
    _accuracy.value = h.accuracy;
    final raw = _mode.value == QiblaMode.ar ? h.camera : h.flat;
    if (raw == null) return;
    _heading.value = CompassMath.smooth(_heading.value, raw);
    final t = turn;
    final aligned = t != null && t.abs() <= alignedWithin;
    if (aligned && !_aligned.value && _haptics.value) unawaited(HapticFeedback.mediumImpact());
    _aligned.value = aligned;
  }

  @override
  void onClose() {
    unawaited(_sub?.cancel());
    _lifecycle?.dispose();
    unawaited(stopLiveView());
    super.onClose();
  }
}
