import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
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
import 'package:quran_pro/data/models/prayer_alert_settings.dart';
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
  NextPrayer? _lastNightIsha; // "previous" between midnight and Fajr
  final Rx<Duration> _remaining = Duration.zero.obs;
  final Rx<DateTime> _now =
      DateTime.now().obs; // ticks every second; drives all time-derived getters
  final Rxn<double> _qibla = Rxn<double>();
  late final Rx<PrayerAlertSettings> _alerts = _settings.prayerAlertSettings.obs;
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

  /// Last obligatory prayer whose time has passed; between midnight and Fajr, last night's Isha.
  NextPrayer? get previous {
    final today = _today;
    if (today == null) return null;
    var last = _lastNightIsha;
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
    final key = isRamadan ? 'iftar_in' : 'maghrib_in';
    return key.trParams({'time': Formatters.countdown(left)});
  }

  /// Qibla bearing from true north in degrees, or null without a location.
  double? get qiblaBearing => _qibla.value;

  String get qiblaDir {
    final b = _qibla.value;
    if (b == null) return '';
    const dirs = ['n', 'ne', 'e', 'se', 's', 'sw', 'w', 'nw'];
    return 'dir_${dirs[(b / 45).round() % 8]}'.tr;
  }

  String get qiblaLabel {
    final b = _qibla.value;
    if (b == null) return 'qibla_unknown'.tr;
    return 'qibla_bearing'.trParams({'deg': '${b.round()}', 'dir': qiblaDir});
  }

  bool get isRamadan => Hijri.fromGregorian(_now.value).month == 9;

  /// Footer of a prayer chip: "In 1h 42m" for the next prayer, else the time of day.
  String hintFor(Prayer p) {
    if (_next.value?.prayer == p) {
      final left = _remaining.value;
      return 'in_hm'.trParams({'h': '${left.inHours}', 'm': '${left.inMinutes % 60}'});
    }
    return p == Prayer.maghrib && isRamadan ? 'iftar'.tr : 'prayer_hint_${p.name}'.tr;
  }

  /// Fajr → Maghrib length, e.g. "13h 02m Total".
  String get fastLengthLabel {
    final fajr = _today?.times[Prayer.fajr];
    final maghrib = _today?.times[Prayer.maghrib];
    if (fajr == null || maghrib == null) return '';
    final d = maghrib.difference(fajr);
    return 'fast_total'.trParams({
      'h': '${d.inHours}',
      'm': (d.inMinutes % 60).toString().padLeft(2, '0'),
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
    _inputsSub = _settings.prayerInputsChanged.listen((_) {
      _alerts.value = _settings.prayerAlertSettings;
      _compute();
    });
    // Returning from system settings, or after a long background: refresh.
    _lifecycle = AppLifecycleListener(onResume: () => unawaited(load()));
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    unawaited(load());
  }

  /// Times come from the saved location straight away (calculated on the phone, no network);
  /// a fresh GPS fix and place lookup then run in the background, and only a real move
  /// recomputes (via prayerInputsChanged). Concurrent calls share one sync.
  Future<void> load() async {
    if (_settings.lastLocation != null) {
      _compute();
    } else if (_state.value is! Success) {
      _state.value = const Loading(); // first launch: nothing saved yet, wait for the fix
    }
    try {
      _access.value = await _sync.sync();
    } on Object catch (e, s) {
      AppLog.e(e, s); // keep showing times for the saved location
    }
    _compute(); // first fix, or permission state changed the empty-state prompt
  }

  /// No times yet because the first location fix is still coming in.
  bool get locating => _state.value is Idle || _state.value is Loading;

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

  // ---- Prayer times screen ----

  String get placeLabel => _settings.placeName ?? 'your_location'.tr;

  /// "4:48" and "PM" separately, so the period can be set smaller.
  ({String hm, String period}) timeParts(Prayer p) {
    final at = _today?.times[p];
    if (at == null) return (hm: '--:--', period: '');
    final locale = Get.locale?.languageCode;
    return (hm: DateFormat('h:mm', locale).format(at), period: DateFormat('a', locale).format(at));
  }

  bool get isDaytime {
    final rise = _today?.times[Prayer.sunrise];
    final set = _today?.times[Prayer.maghrib];
    return rise != null && set != null && _now.value.isAfter(rise) && _now.value.isBefore(set);
  }

  bool get remindersOn => _settings.prayerAlertsOn;

  /// Bell state for one prayer: the master switch and that prayer's own choice.
  bool alertOn(Prayer p) => _settings.prayerAlertsOn && _alerts.value.isOn(p);

  /// Flips one prayer's reminder. With reminders off overall, opens the settings screen instead,
  /// which also handles the notification permission.
  Future<void> toggleAlert(Prayer p) async {
    if (!_settings.prayerAlertsOn) return openNotificationSettings();
    final next = _alerts.value.withEnabled(p, on: !_alerts.value.isOn(p));
    _alerts.value = next;
    await _settings.setPrayerAlertSettings(next); // reschedules via prayerInputsChanged
  }

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
        _lastNightIsha = switch (_prayers.timesFor(
          DateTime(now.year, now.month, now.day - 1),
          loc,
          _settings.prayerSettings,
        )) {
          Ok(:final value) => (prayer: Prayer.isha, at: value.times[Prayer.isha]!),
          Err() => null,
        };
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
