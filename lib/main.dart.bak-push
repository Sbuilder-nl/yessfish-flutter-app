import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/auth.dart';
import 'core/realtime_service.dart';
import 'core/i18n.dart';
import 'core/theme.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() => runApp(const YessFishApp());

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
        theme: buildTheme(),
        locale: i18n.flutterLocale,
        supportedLocales: const [Locale('nl'), Locale('en'), Locale('de'), Locale('fr')],
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
