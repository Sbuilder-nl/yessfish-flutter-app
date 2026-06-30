import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/auth.dart';
import '../core/config.dart';
import '../core/realtime_service.dart';
import '../core/i18n.dart';
import 'feed_screen.dart';
import 'catches_screen.dart';
import 'bite_screen.dart';
import 'clubs_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/update_check.dart';
import '../core/api.dart';
import '../core/disciplines_i18n.dart';
import 'disciplines_screen.dart';
import '../widgets/yf_logo.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _i = 0;
  final _screens = const [FeedScreen(), CatchesScreen(), BiteScreen(), ClubsScreen(), ProfileScreen()];

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthState>();
    if (auth.user != null) context.read<RealtimeService>().start(auth.user!.id);
    WidgetsBinding.instance.addPostFrameCallback((_) { _checkUpdate(); _maybePromptDisciplines(); });
  }

  // Bestaande én nieuwe accounts: als er nog geen visstijlen gekozen zijn,
  // bied de keuze actief aan zodat de dashboards verschijnen.
  Future<void> _maybePromptDisciplines() async {
    try {
      final r = await Api.get('/profile/disciplines');
      final list = (r is Map ? r['disciplines'] : null) as List?;
      if (list == null || list.isNotEmpty || !mounted) return;
      showDialog(context: context, builder: (ctx) => AlertDialog(
        title: Text(dui(ctx, 'title')),
        content: Text(dui(ctx, 'prompt')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(dui(ctx, 'later'))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
            onPressed: () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => const DisciplinesScreen())); },
            child: Text(dui(ctx, 'choose')),
          ),
        ],
      ));
    } catch (_) {}
  }

  Future<void> _checkUpdate() async {
    final u = await checkForUpdate();
    if (u == null || !mounted) return;
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Update beschikbaar'),
      content: Text('Versie ${u.versionName} staat klaar.${u.notes.isNotEmpty ? "\n\n${u.notes}" : ""}'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Later')),
        FilledButton(onPressed: () { Navigator.pop(ctx); launchUrl(Uri.parse(u.url), mode: LaunchMode.externalApplication); }, child: const Text('Downloaden')),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const YfLogo(size: 30, light: true),
        actions: [
          Consumer<RealtimeService>(builder: (_, rt, __) => Stack(alignment: Alignment.center, children: [
            IconButton(icon: const Icon(Icons.notifications_outlined),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()))),
            if (rt.unread > 0) Positioned(top: 8, right: 8, child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Color(0xFFFF5A5A), shape: BoxShape.circle),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(rt.unread > 9 ? '9+' : '${rt.unread}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)))),
          ])),
        ],
      ),
      body: IndexedStack(index: _i, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _i,
        onDestinationSelected: (v) => setState(() => _i = v),
        backgroundColor: Colors.white,
        indicatorColor: AppColors.teal.withValues(alpha: 0.15),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.dynamic_feed_outlined), selectedIcon: const Icon(Icons.dynamic_feed), label: context.tr('nav.feed')),
          NavigationDestination(icon: const Icon(Icons.set_meal_outlined), selectedIcon: const Icon(Icons.set_meal), label: context.tr('nav.catches')),
          NavigationDestination(icon: const Icon(Icons.water_outlined), selectedIcon: const Icon(Icons.water), label: context.tr('nav.bite')),
          NavigationDestination(icon: const Icon(Icons.groups_outlined), selectedIcon: const Icon(Icons.groups), label: context.tr('nav.clubs')),
          NavigationDestination(icon: const Icon(Icons.person_outline), selectedIcon: const Icon(Icons.person), label: context.tr('nav.profile')),
        ],
      ),
    );
  }
}
