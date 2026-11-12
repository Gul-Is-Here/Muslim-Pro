import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:get/get.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

typedef PrayerAlert = ({int id, String title, String body, DateTime at});

final class NotificationService extends GetxService {
  // Channel sound is immutable once created on a device: bump the suffix to change it.
  // shortcut: system default sound until res/raw/azan.mp3 exists; then add
  // RawResourceAndroidNotificationSound('azan') here + in details and use 'prayer_azan_v1'.
  static const _azanChannel = 'prayer_v1';
  static const _generalChannel = 'general_v1';
  static const _prayerPayload = 'prayer';

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
    await _android?.createNotificationChannel(
      AndroidNotificationChannel(_azanChannel, 'channel_prayer'.tr, importance: Importance.max),
    );
    await _android?.createNotificationChannel(
      AndroidNotificationChannel(_generalChannel, 'channel_general'.tr),
    );
  }

  /// Show the rationale first. Returns false when denied: offer "Open settings".
  Future<bool> requestPermission() async {
    await init();
    if (GetPlatform.isAndroid) {
      final granted = await _android?.requestNotificationsPermission() ?? false;
      if (granted && !(await _android?.canScheduleExactNotifications() ?? true)) {
        await _android?.requestExactAlarmsPermission(); // opens the system screen
      }
      return granted;
    }
    return await _ios?.requestPermissions(alert: true, badge: true, sound: true) ?? false;
  }

  /// Replaces every pending prayer alert with [alerts]; other notifications are untouched.
  Future<void> replacePrayerAlerts(List<PrayerAlert> alerts) async {
    await init();
    for (final p in await _plugin.pendingNotificationRequests()) {
      if (p.payload == _prayerPayload) await _plugin.cancel(id: p.id);
    }
    final exact = await _android?.canScheduleExactNotifications() ?? true;
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _azanChannel,
        'channel_prayer'.tr,
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.alarm,
      ),
      iOS: const DarwinNotificationDetails(), // add sound: 'azan.caf' once bundled
    );
    for (final a in alerts) {
      await _plugin.zonedSchedule(
        id: a.id,
        title: a.title,
        body: a.body,
        scheduledDate: tz.TZDateTime.from(a.at, tz.local),
        notificationDetails: details,
        androidScheduleMode: exact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        payload: _prayerPayload,
      );
    }
  }
}
