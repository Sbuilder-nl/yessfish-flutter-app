import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/auth.dart';
import '../core/config.dart';
import '../core/realtime_service.dart';
import '../core/i18n.dart';
import 'feed_screen.dart';
import 'catches_screen.dart';
import 'bite_screen.dart';
import 'map_screen.dart';
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
  final Set<int> _visited = {0};

  Widget _pageFor(int idx) {
    switch (idx) {
      case 0: return const FeedScreen();
      case 1: return const CatchesScreen();
      case 2: return const BiteScreen();
      case 3: return const MapScreen();
      default: return const ProfileScreen();
    }
  }

  bool _resendBusy = false;
  Future<void> _resendVerify() async {
    setState(() => _resendBusy = true);
    final m = ScaffoldMessenger.of(context);
    final sent = context.tr('verify.sent');
    try { await Api.post('/auth/email/resend', {}); m.showSnackBar(SnackBar(content: Text(sent))); }
    catch (e) { m.showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : sent))); }
    finally { if (mounted) setState(() => _resendBusy = false); }
  }

  Widget _verifyBanner() {
    final u = context.watch<AuthState>().user;
    if (u == null || u.emailVerified) return const SizedBox.shrink();
    return Material(color: const Color(0xFFFFF4D6), child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      child: Row(children: [
        const Icon(Icons.mark_email_unread_outlined, size: 18, color: Color(0xFFB26A00)),
        const SizedBox(width: 8),
        Expanded(child: Text(context.tr('verify.banner'), style: const TextStyle(fontSize: 12.5, color: Color(0xFF7A4E00)))),
        _resendBusy
          ? const Padding(padding: EdgeInsets.all(10), child: SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)))
          : TextButton(onPressed: _resendVerify, child: Text(context.tr('verify.resend'))),
      ]),
    ));
  }

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthState>();
    if (auth.user != null) context.read<RealtimeService>().start(auth.user!.id);
    WidgetsBinding.instance.addPostFrameCallback((_) { _checkUpdate(); _maybePromptDisciplines(); context.read<AuthState>().refresh(); });
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
      appBar: _i == 3 ? null : AppBar(
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
      body: Column(children: [
        _verifyBanner(),
        Expanded(child: IndexedStack(index: _i, children: List.generate(5, (idx) => _visited.contains(idx) ? _pageFor(idx) : const SizedBox.shrink()))),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _i,
        onDestinationSelected: (v) => setState(() { _i = v; _visited.add(v); }),
        backgroundColor: Colors.white,
        indicatorColor: AppColors.teal.withValues(alpha: 0.15),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.dynamic_feed_outlined), selectedIcon: const Icon(Icons.dynamic_feed), label: context.tr('nav.feed')),
          NavigationDestination(icon: const Icon(Icons.set_meal_outlined), selectedIcon: const Icon(Icons.set_meal), label: context.tr('nav.catches')),
          NavigationDestination(icon: const Icon(Icons.water_outlined), selectedIcon: const Icon(Icons.water), label: context.tr('nav.bite')),
          NavigationDestination(icon: const Icon(Icons.map_outlined), selectedIcon: const Icon(Icons.map), label: context.tr('nav.map')),
          NavigationDestination(icon: const Icon(Icons.grid_view_outlined), selectedIcon: const Icon(Icons.grid_view), label: context.tr('nav.menu')),
        ],
      ),
    );
  }
}
