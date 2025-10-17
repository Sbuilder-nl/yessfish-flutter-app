import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/services/update_checker_service.dart';
import 'core/widgets/update_dialog.dart';

void main() {
  runApp(
    const ProviderScope(
      child: YessFishApp(),
    ),
  );
}

class YessFishApp extends StatefulWidget {
  const YessFishApp({super.key});

  @override
  State<YessFishApp> createState() => _YessFishAppState();
}

class _YessFishAppState extends State<YessFishApp> {
  final UpdateCheckerService _updateChecker = UpdateCheckerService();

  @override
  void initState() {
    super.initState();
    // Check for updates after app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates();
    });
  }

  Future<void> _checkForUpdates() async {
    try {
      final updateInfo = await _updateChecker.checkForUpdates();

      if (updateInfo != null && mounted) {
        // Show update dialog
        final context = appRouter.routerDelegate.navigatorKey.currentContext;
        if (context != null) {
          UpdateDialog.show(context, updateInfo, _updateChecker);
        }
      }
    } catch (e) {
      print('Update check error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'YessFish',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}
