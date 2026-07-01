import 'package:firebase_analytics/firebase_analytics.dart';

/// Dunne wrapper om Firebase Analytics → stroomt door naar GA4 (Android-datastream).
/// Logt nooit een crash bij falen (best-effort).
class Analytics {
  static final FirebaseAnalytics instance = FirebaseAnalytics.instance;
  static final FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: instance);

  /// Gebruik van een functie/actie (bv. 'catch_created', 'spot_created').
  static void log(String name, [Map<String, Object>? params]) {
    try { instance.logEvent(name: name, parameters: params); } catch (_) {}
  }

  /// Welk scherm/onderdeel wordt bekeken (bv. de hoofd-tabs).
  static void screen(String name) {
    try { instance.logScreenView(screenName: name); } catch (_) {}
  }
}
