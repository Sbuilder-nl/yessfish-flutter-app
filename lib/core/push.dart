import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api.dart';
import 'notif_nav.dart';
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
  /// LET OP volgorde: permissie EERST — de Android-only lokale-notificatie-init gooit op
  /// iOS een fout, en die mag de permissievraag niet blokkeren (iOS-bug 1.0.20).
  static Future<void> init() async {
    if (_inited) return;
    _inited = true;
    try {
      await FirebaseMessaging.instance.requestPermission();
      // iOS: laat het systeem meldingen ook tonen als de app op de voorgrond staat.
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true, badge: true, sound: true,
      );

      if (Platform.isAndroid) {
        const InitializationSettings initSettings = InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        );
        await _local.initialize(
          settings: initSettings,
          // Tik op een voorgrond-melding → naar het doel (payload = "type|link").
          onDidReceiveNotificationResponse: (resp) {
            final parts = (resp.payload ?? '').split('|');
            _navigate(parts.length > 1 ? parts.sublist(1).join('|') : '', parts.isNotEmpty ? parts[0] : null);
          },
        );
        final AndroidFlutterLocalNotificationsPlugin? android =
            _local.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        await android?.createNotificationChannel(_messages);
        await android?.createNotificationChannel(_updates);
      }

      FirebaseMessaging.onMessage.listen(_showForeground);
      FirebaseMessaging.onMessageOpenedApp.listen(_openFromMessage);
      final RemoteMessage? initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) _openFromMessage(initial);
      FirebaseMessaging.instance.onTokenRefresh.listen(_send);
    } catch (_) {/* push mag de app nooit breken */}
  }

  /// Voorgrond: op Android toont FCM zelf niets, dus tonen we de melding lokaal op het
  /// juiste kanaal. Op iOS doet het systeem dit al (presentation options) → niets doen.
  static void _showForeground(RemoteMessage m) {
    if (!Platform.isAndroid) return;
    final RemoteNotification? n = m.notification;
    if (n == null) return;
    final bool isUpdate = m.data['channel'] == 'updates';
    final AndroidNotificationChannel ch = isUpdate ? _updates : _messages;
    _local.show(
      id: n.hashCode,
      title: n.title,
      body: n.body,
      payload: '${m.data['type'] ?? ''}|${m.data['link'] ?? ''}',   // voor tik-navigatie
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          ch.id,
          ch.name,
          channelDescription: ch.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_stat_yessfish',                                   // dobber-silhouet in de statusbalk
          color: const Color(0xFF1F8A70),                             // merk-tint (teal)
          largeIcon: const DrawableResourceAndroidBitmap('ic_notif_large'), // volle kleuren-dobber in de melding
          sound: isUpdate ? null : const RawResourceAndroidNotificationSound('yf_dubbel_mid'),
        ),
      ),
    );
  }

  static void _openFromMessage(RemoteMessage m) =>
      _navigate(m.data['link']?.toString(), m.data['type']?.toString());

  /// Navigeer naar het doel van een melding (post/gesprek/vrienden/kaart), of anders de meldingenlijst.
  static void _navigate(String? link, String? event) {
    final NavigatorState? nav = navKey.currentState;
    if (nav == null) return;
    final Widget? target = screenForLink(link ?? '', event: event);
    nav.push(MaterialPageRoute<void>(builder: (_) => target ?? const NotificationsScreen()));
  }

  /// Toestel-token bij de server registreren (na login of bij opstart als al ingelogd).
  static Future<void> registerToken() async {
    try {
      if (Api.token == null) return;
      // getToken() kan bij de eerste poging (net na opstart / trage Play Services) null
      // teruggeven → een paar keer opnieuw proberen zodat het toestel-token alsnog registreert.
      String? t;
      for (int i = 0; i < 4 && t == null; i++) {
        t = await FirebaseMessaging.instance.getToken();
        if (t == null) await Future.delayed(const Duration(seconds: 3));
      }
      if (t != null) await _send(t);
    } catch (_) {}
  }

  static Future<void> _send(String token) async {
    try {
      await Api.post('/device-tokens', {'token': token, 'platform': Platform.isIOS ? 'ios' : 'android'});
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
