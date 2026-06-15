import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/auth.dart';
import 'core/theme.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() => runApp(const YessFishApp());

class YessFishApp extends StatelessWidget {
  const YessFishApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthState()..bootstrap(),
      child: MaterialApp(
        title: 'YessFish',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const RootGate(),
      ),
    );
  }
}

class RootGate extends StatelessWidget {
  const RootGate({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    if (auth.loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return auth.user == null ? const LoginScreen() : const HomeScreen();
  }
}
