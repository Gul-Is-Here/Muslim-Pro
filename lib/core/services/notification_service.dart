import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:quran_pro/data/models/prayer_alert_settings.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

typedef PrayerAlert = ({int id, String title, String body, DateTime at, AzanSound sound});

final class NotificationService extends GetxService {
  static const _generalChannel = 'general_v1';
  static const _prayerPayload = 'prayer';
  static const _testId = 1; // prayer alert ids are day*10+prayer, far above this

  /// Android fixes a channel's sound once the channel exists on a device, so every sound has its
  /// own channel: changing a prayer's sound moves its alerts to another channel instead of
  /// editing one. Bump a suffix only when that clip's audio file itself changes.
  static String _channelId(AzanSound s) =>
      s == AzanSound.system ? 'prayer_v1' : 'prayer_${s.name}_v1';

  final _plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _initialized;

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  IOSFlutterLocalNotificationsPlugin? get _ios =>
      _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

  /// Idempotent. Call after the first frame so channel names are translated.
  Future<void> init() => _initialized ??= _init();

  Future<void> _init() async {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation((await FlutterTimezone.getLocalTimezone()).identifier));
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@drawable/ic_notification'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false, // asked later, after the rationale
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    for (final s in AzanSound.values) {
      await _android?.createNotificationChannel(
        AndroidNotificationChannel(
          _channelId(s),
          _channelName(s),
          importance: Importance.max,
          sound: _androidSound(s),
        ),
      );
    }
    await _android?.createNotificationChannel(
      AndroidNotificationChannel(_generalChannel, 'channel_general'.tr),
    );
  }

  /// Notifications can currently be shown (permission granted and not blocked in Settings).
  Future<bool> notificationsAllowed() async {
    await init();
    if (GetPlatform.isAndroid) return await _android?.areNotificationsEnabled() ?? false;
    return (await _ios?.checkPermissions())?.isEnabled ?? false;
  }

  /// Show the rationale first. Returns false when denied: offer [openAppSettings].
  /// Only the notification permission: exact alarms are a separate, optional grant.
  Future<bool> requestPermission() async {
    await init();
    if (GetPlatform.isAndroid) return await _android?.requestNotificationsPermission() ?? false;
    return await _ios?.requestPermissions(alert: true, badge: true, sound: true) ?? false;
  }

  /// Android 12+: without this, alerts are scheduled inexactly and can arrive minutes late.
  Future<bool> exactAlarmsAllowed() async {
    await init();
    return await _android?.canScheduleExactNotifications() ?? true;
  }

  /// Opens the system "Alarms & reminders" screen (Android only).
  Future<void> requestExactAlarms() async {
    await _android?.requestExactAlarmsPermission();
  }

  /// The app's page in system Settings, where notifications can be re-enabled after a denial.
  // shortcut: reuses geolocator's app-settings link (already a dependency); it opens the app page,
  // not the notification sub-page. Add app_settings if a deeper link is wanted.
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  /// Replaces every pending prayer alert with [alerts]; other notifications are untouched.
  Future<void> replacePrayerAlerts(List<PrayerAlert> alerts) async {
    await init();
    for (final p in await _plugin.pendingNotificationRequests()) {
      if (p.payload == _prayerPayload) await _plugin.cancel(id: p.id);
    }
    final mode = await exactAlarmsAllowed()
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
    for (final a in alerts) {
      await _plugin.zonedSchedule(
        id: a.id,
        title: a.title,
        body: a.body,
        scheduledDate: tz.TZDateTime.from(a.at, tz.local),
        notificationDetails: _prayerDetails(a.sound),
        androidScheduleMode: mode,
        payload: _prayerPayload,
      );
    }
  }

  /// Shows an alert now with [sound], exactly as a prayer reminder would sound on this device.
  Future<void> showTestAlert(AzanSound sound, {required String title, required String body}) async {
    await init();
    await _plugin.show(
      id: _testId,
      title: title,
      body: body,
      notificationDetails: _prayerDetails(sound),
    );
  }

  String _channelName(AzanSound s) => 'channel_prayer_sound'.trParams({'sound': s.labelKey.tr});

  AndroidNotificationSound? _androidSound(AzanSound s) =>
      s.isBundled ? RawResourceAndroidNotificationSound(s.resource) : null;

  NotificationDetails _prayerDetails(AzanSound s) => NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId(s),
      _channelName(s),
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
      sound: _androidSound(s), // used only before Android 8; afterwards the channel decides
    ),
    // iOS plays bundled sounds under 30 s; otherwise (or for null) the default sound.
    iOS: DarwinNotificationDetails(sound: s.isBundled ? '${s.resource}.caf' : null),
  );
}
