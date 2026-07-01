import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api.dart';
import '../screens/notifications_screen.dart';

/// Achtergrond-handler MOET top-level + @pragma zijn (draait in een aparte isolate).
/// Bij een notification-payload toont Android de melding zelf op het 'messages'-kanaal
/// (met geluid yf_dubbel_mid), dus hier hoeft niets te gebeuren.
@pragma('vm:entry-point')
Future<void> firebaseBgHandler(RemoteMessage message) async {}

/// Push-meldingen (FCM): kanalen met beetmelder-geluid, voorgrond tonen, tik-navigatie,
/// en toestel-token registreren bij de server. Push mag de app NOOIT laten crashen → alles best-effort.
class Push {
  static final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();
  static final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();
  static bool _inited = false;

  static final AndroidNotificationChannel _messages = const AndroidNotificationChannel(
    'messages',
    'Meldingen',
    description: 'Berichten, vriendverzoeken, likes en reacties',
    importance: Importance.high,
    sound: RawResourceAndroidNotificationSound('yf_dubbel_mid'),
    playSound: true,
  );
  static final AndroidNotificationChannel _updates = const AndroidNotificationChannel(
    'updates',
    'YessFish-nieuws',
    description: 'Aankondigingen van YessFish',
    importance: Importance.defaultImportance,
  );

  /// Eenmalig: kanalen aanmaken (met geluid), notificatie-permissie vragen, listeners zetten.
  static Future<void> init() async {
    if (_inited) return;
    _inited = true;
    try {
      const InitializationSettings initSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      );
      await _local.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (_) => _openNotifications(),
      );
      final AndroidFlutterLocalNotificationsPlugin? android =
          _local.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(_messages);
      await android?.createNotificationChannel(_updates);

      await FirebaseMessaging.instance.requestPermission();

      FirebaseMessaging.onMessage.listen(_showForeground);
      FirebaseMessaging.onMessageOpenedApp.listen((_) => _openNotifications());
      final RemoteMessage? initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) _openNotifications();
      FirebaseMessaging.instance.onTokenRefresh.listen(_send);
    } catch (_) {/* push mag de app nooit breken */}
  }

  /// Voorgrond: FCM toont zelf niets, dus tonen we de melding lokaal op het juiste kanaal.
  static void _showForeground(RemoteMessage m) {
    final RemoteNotification? n = m.notification;
    if (n == null) return;
    final bool isUpdate = m.data['channel'] == 'updates';
    final AndroidNotificationChannel ch = isUpdate ? _updates : _messages;
    _local.show(
      id: n.hashCode,
      title: n.title,
      body: n.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          ch.id,
          ch.name,
          channelDescription: ch.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          sound: isUpdate ? null : const RawResourceAndroidNotificationSound('yf_dubbel_mid'),
        ),
      ),
    );
  }

  static void _openNotifications() {
    final NavigatorState? nav = navKey.currentState;
    if (nav == null) return;
    nav.push(MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()));
  }

  /// Toestel-token bij de server registreren (na login of bij opstart als al ingelogd).
  static Future<void> registerToken() async {
    try {
      if (Api.token == null) return;
      final String? t = await FirebaseMessaging.instance.getToken();
      if (t != null) await _send(t);
    } catch (_) {}
  }

  static Future<void> _send(String token) async {
    try {
      await Api.post('/device-tokens', {'token': token, 'platform': 'android'});
    } catch (_) {}
  }

  /// Bij uitloggen: token weghalen zodat dit toestel geen pushes meer krijgt.
  static Future<void> unregisterToken() async {
    try {
      final String? t = await FirebaseMessaging.instance.getToken();
      if (t != null) await Api.delete('/device-tokens', {'token': t});
    } catch (_) {}
  }
}
