import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/analytics.dart';
import 'core/auth.dart';
import 'core/config.dart';
import 'core/realtime_service.dart';
import 'core/i18n.dart';
import 'core/theme.dart';
import 'core/push.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Config.loadVersion();
  // Edge-to-edge (Android 15+): app tekent tot achter de systeembalken, transparante balken
  // → geen verouderde systeembalk-API's meer + moderne weergave op nieuwe toestellen.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  try {
    await Firebase.initializeApp().timeout(const Duration(seconds: 10));
    FirebaseMessaging.onBackgroundMessage(firebaseBgHandler);
  } catch (_) {/* push (of een trage init) mag het opstarten nooit blokkeren */}
  runApp(const YessFishApp());
}

class YessFishApp extends StatelessWidget {
  const YessFishApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthState()..bootstrap()),
        ChangeNotifierProvider(create: (_) => RealtimeService()),
        ChangeNotifierProvider(create: (_) => I18n()..load()),
      ],
      child: Consumer<I18n>(builder: (_, i18n, __) => MaterialApp(
        title: 'YessFish',
        debugShowCheckedModeBanner: false,
        navigatorKey: Push.navKey,
        navigatorObservers: [Analytics.observer],
        theme: buildTheme(),
        locale: i18n.flutterLocale,
        supportedLocales: const [Locale('nl'), Locale('en'), Locale('de'), Locale('fr'), Locale('es'), Locale('pl')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const RootGate(),
      )),
    );
  }
}

class RootGate extends StatelessWidget {
  const RootGate({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    if (auth.loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (auth.user == null) { context.read<RealtimeService>().stop(); return const LoginScreen(); }
    return const HomeScreen();
  }
}
