import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:quran_pro/app/routes/app_routes.dart';
import 'package:quran_pro/core/errors/result.dart';
import 'package:quran_pro/core/services/location_service.dart';
import 'package:quran_pro/core/services/location_sync_service.dart';
import 'package:quran_pro/core/services/settings_service.dart';
import 'package:quran_pro/core/utils/app_log.dart';
import 'package:quran_pro/core/utils/formatters.dart';
import 'package:quran_pro/core/utils/hijri.dart';
import 'package:quran_pro/core/utils/view_state.dart';
import 'package:quran_pro/data/models/day_prayer_times.dart';
import 'package:quran_pro/data/models/prayer.dart';
import 'package:quran_pro/data/models/user_location.dart';
import 'package:quran_pro/domain/repositories/prayer_times_repository.dart';

final class PrayerTimesViewModel extends GetxController {
  PrayerTimesViewModel(this._prayers, this._location, this._settings, this._sync);

  final PrayerTimesRepository _prayers;
  final LocationService _location;
  final SettingsService _settings;
  final LocationSyncService _sync;

  final _state = Rx<ViewState<DayPrayerTimes>>(const Idle());
  final Rx<LocationAccess> _access = LocationAccess.granted.obs;
  final _next = Rxn<NextPrayer>();
  final Rx<Duration> _remaining = Duration.zero.obs;
  final Rx<DateTime> _now =
      DateTime.now().obs; // ticks every second; drives all time-derived getters
  final Rxn<double> _qibla = Rxn<double>();
  Timer? _ticker;
  StreamSubscription<int>? _inputsSub;
  AppLifecycleListener? _lifecycle;

  ViewState<DayPrayerTimes> get state => _state.value;
  NextPrayer? get next => _next.value;
  Duration get remaining => _remaining.value;

  String get nextLabel {
    final n = _next.value;
    return n == null
        ? ''
        : 'next_prayer'.trParams({'prayer': n.prayer.labelKey.tr, 'time': Formatters.time(n.at)});
  }

  DayPrayerTimes? get _today => switch (_state.value) {
    Success(:final data) => data,
    _ => null,
  };

  String get clockLabel => Formatters.clock(_now.value);
  String get nextName => _next.value?.prayer.labelKey.tr ?? '';
  String get countdownLabel => Formatters.countdown(_remaining.value);
  String get adhanAtLabel {
    final n = _next.value;
    return n == null ? '' : 'adhan_at'.trParams({'time': Formatters.clock(n.at)});
  }

  String get remainingLabel => 'remaining_hm'.trParams({
    'h': '${_remaining.value.inHours}',
    'm': '${_remaining.value.inMinutes % 60}',
  });

  /// Last obligatory prayer whose time has passed today (null before Fajr).
  NextPrayer? get previous {
    final today = _today;
    if (today == null) return null;
    NextPrayer? last;
    for (final p in Prayer.obligatory) {
      final at = today.times[p]!;
      if (!at.isAfter(_now.value)) last = (prayer: p, at: at);
    }
    return last;
  }

  String get previousLabel => _label(previous);
  String get nextLabelShort => _label(_next.value);
  String _label(NextPrayer? p) =>
      p == null ? '' : '${p.prayer.labelKey.tr} ${Formatters.clock(p.at)}';

  bool isPassed(Prayer p) => !(_today?.times[p]?.isAfter(_now.value) ?? true);
  int get passedCount => Prayer.obligatory.where(isPassed).length;
  String timeOf(Prayer p) {
    final at = _today?.times[p];
    return at == null ? '--:--' : Formatters.clock(at);
  }

  /// 0..1 between the previous and the next prayer (timeline bar).
  double get segmentProgress => _fraction(previous?.at, _next.value?.at);

  /// 0..1 of daylight elapsed between sunrise and maghrib.
  double get daylightProgress =>
      _fraction(_today?.times[Prayer.sunrise], _today?.times[Prayer.maghrib]);

  double _fraction(DateTime? from, DateTime? to) {
    if (from == null || to == null) return 0;
    final total = to.difference(from).inSeconds;
    if (total <= 0) return 0;
    return (_now.value.difference(from).inSeconds / total).clamp(0, 1).toDouble();
  }

  /// "Iftar in 03:06:15" during Ramadan, "Maghrib in …" otherwise; empty after Maghrib.
  String get maghribCountdownLabel {
    final at = _today?.times[Prayer.maghrib];
    final left = at?.difference(_now.value);
    if (left == null || left.isNegative) return '--:--:--';
    final key = Hijri.fromGregorian(_now.value).month == 9 ? 'iftar_in' : 'maghrib_in';
    return key.trParams({'time': Formatters.countdown(left)});
  }

  String get qiblaLabel {
    final b = _qibla.value;
    if (b == null) return 'qibla_unknown'.tr;
    const dirs = ['n', 'ne', 'e', 'se', 's', 'sw', 'w', 'nw'];
    return 'qibla_bearing'.trParams({
      'deg': '${b.round()}',
      'dir': 'dir_${dirs[(b / 45).round() % 8]}'.tr,
    });
  }

  String get permissionActionKey => switch (_access.value) {
    LocationAccess.permanentlyDenied => 'open_app_settings',
    LocationAccess.serviceDisabled => 'open_location_settings',
    _ => 'allow_location',
  };

  @override
  void onInit() {
    super.onInit();
    _inputsSub = _settings.prayerInputsChanged.listen((_) => _compute());
    // Returning from system settings, or after a long background: refresh.
    _lifecycle = AppLifecycleListener(onResume: () => unawaited(load()));
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    unawaited(load());
  }

  Future<void> load() async {
    if (_state.value is Loading) return;
    _state.value = const Loading();
    try {
      // Fresh GPS fix + place lookup; saving either recomputes times and reschedules alerts.
      _access.value = await _sync.sync();
    } on Object catch (e, s) {
      AppLog.e(e, s); // fall back to the cached location below
    }
    _compute();
  }

  /// "Burewala · Karachi method · Hanafi Asr": what the times are calculated for.
  String get calculationLabel {
    final s = _settings.prayerSettings;
    return [
      ?_settings.placeName,
      'method_${s.method}'.tr,
      (s.hanafiAsr ? 'asr_hanafi' : 'asr_standard').tr,
    ].join(' · ');
  }

  void openNotificationSettings() => Get.toNamed<void>(AppRoutes.prayerNotifications);

  Future<void> onPermissionAction() async {
    switch (_access.value) {
      case LocationAccess.permanentlyDenied:
        await _location.openAppSettings();
      case LocationAccess.serviceDisabled:
        await _location.openLocationSettings();
      case LocationAccess.denied || LocationAccess.granted:
        _access.value = await _location.request();
        await load();
    }
  }

  void _compute() {
    final loc = _settings.lastLocation;
    if (loc == null) {
      _next.value = null;
      _state.value = const Empty(); // view shows the location rationale
      return;
    }
    _qibla.value = switch (_prayers.qiblaFor(loc)) {
      Ok(:final value) => value,
      Err() => null,
    };
    final now = DateTime.now();
    switch (_prayers.timesFor(now, loc, _settings.prayerSettings)) {
      case Err(:final failure):
        _state.value = ViewError(failure.messageKey);
      case Ok(:final value):
        _state.value = Success(value);
        _next.value = value.nextAfter(now) ?? _tomorrowFajr(loc, now);
        _tick();
    }
  }

  NextPrayer? _tomorrowFajr(UserLocation loc, DateTime now) => switch (_prayers.timesFor(
    DateTime(now.year, now.month, now.day + 1),
    loc,
    _settings.prayerSettings,
  )) {
    Ok(:final value) => value.nextAfter(now),
    Err() => null,
  };

  void _tick() {
    _now.value = DateTime.now();
    final next = _next.value;
    if (next == null) return;
    final left = next.at.difference(DateTime.now());
    if (left.isNegative) {
      _compute(); // prayer time reached: roll to the next one
      return;
    }
    _remaining.value = left;
  }

  @override
  void onClose() {
    _ticker?.cancel();
    unawaited(_inputsSub?.cancel());
    _lifecycle?.dispose();
    super.onClose();
  }
}
