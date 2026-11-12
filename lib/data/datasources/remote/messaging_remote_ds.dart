import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:quran_pro/data/models/push_message.dart';

/// Terminated/background: notification messages are displayed by the OS. Keep this handler
/// trivial; data-only messages would be handled here (it runs in its own isolate).
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {}

final class MessagingRemoteDataSource {
  MessagingRemoteDataSource([FirebaseMessaging? messaging])
    : _m = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _m;

  static void registerBackgroundHandler() =>
      FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

  Future<void> subscribe(String topic) => _m.subscribeToTopic(topic);
  Future<void> unsubscribe(String topic) => _m.unsubscribeFromTopic(topic);

  Stream<PushMessage> get foreground => FirebaseMessaging.onMessage.map(_toModel);
  Stream<PushMessage> get opened => FirebaseMessaging.onMessageOpenedApp.map(_toModel);

  Future<PushMessage?> initial() async {
    final m = await _m.getInitialMessage();
    return m == null ? null : _toModel(m);
  }

  PushMessage _toModel(RemoteMessage m) => PushMessage(
    title: m.notification?.title,
    body: m.notification?.body,
    route: m.data['route'] as String?,
  );
}
