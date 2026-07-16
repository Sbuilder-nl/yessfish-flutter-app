import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../core/app_config.dart';
import 'disciplines_screen.dart';
import '../widgets/yf_logo.dart';
import 'package:quick_actions/quick_actions.dart';
import 'quick_catch_screen.dart';
import 'quick_spot_screen.dart';
import 'drafts_screen.dart';
import 'package:home_widget/home_widget.dart';
import '../core/home_widget_service.dart';
import 'catch_detail_screen.dart';
import 'albums_screen.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) { _checkUpdate(); AppConfig.load(); _maybePromptDisciplines(); context.read<AuthState>().refresh(); _initQuickActions(); _initHomeWidget(); });
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
      title: Text(_qt(const {'nl': 'Update beschikbaar', 'en': 'Update available', 'de': 'Update verfügbar', 'fr': 'Mise à jour disponible', 'es': 'Actualización disponible', 'pl': 'Dostępna aktualizacja'})),
      content: Text(_qt(const {'nl': 'Er staat een nieuwe versie klaar in de Google Play Store.', 'en': 'A new version is available in the Google Play Store.', 'de': 'Eine neue Version ist im Google Play Store verfügbar.', 'fr': 'Une nouvelle version est disponible sur le Google Play Store.', 'es': 'Hay una nueva versión en Google Play Store.', 'pl': 'Nowa wersja jest dostępna w Google Play.'})),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(_qt(const {'nl': 'Later', 'en': 'Later', 'de': 'Später', 'fr': 'Plus tard', 'es': 'Más tarde', 'pl': 'Później'}))),
        FilledButton(onPressed: () { Navigator.pop(ctx); launchUrl(Uri.parse(u.url), mode: LaunchMode.externalApplication); }, child: Text(_qt(const {'nl': 'Bijwerken', 'en': 'Update', 'de': 'Aktualisieren', 'fr': 'Mettre à jour', 'es': 'Actualizar', 'pl': 'Aktualizuj'}))),
      ],
    ));
  }

  final QuickActions _qa = const QuickActions();
  String _qt(Map<String, String> m) { final l = context.read<I18n>().locale; return m[l] ?? m['en'] ?? m['nl'] ?? ''; }

  void _initQuickActions() {
    final l = context.read<I18n>().locale;
    final catchT = {'nl': 'Snelvangst', 'en': 'Quick catch', 'de': 'Schnellfang', 'fr': 'Prise rapide', 'es': 'Captura rapida', 'pl': 'Szybki polow'}[l] ?? 'Quick catch';
    final spotT = {'nl': 'Nieuwe stek', 'en': 'New spot', 'de': 'Neue Stelle', 'fr': 'Nouveau spot', 'es': 'Nuevo spot', 'pl': 'Nowe miejsce'}[l] ?? 'New spot';
    _qa.initialize((type) {
      if (!mounted) return;
      if (type == 'action_catch') { _openQuickCatch(); }
      else if (type == 'action_spot') { _openQuickSpot(); }
    });
    _qa.setShortcutItems(<ShortcutItem>[
      ShortcutItem(type: 'action_catch', localizedTitle: catchT),
      ShortcutItem(type: 'action_spot', localizedTitle: spotT),
    ]);
  }

  void _initHomeWidget() {
    YfHomeWidget.refresh(context.read<I18n>().locale);
    HomeWidget.initiallyLaunchedFromHomeWidget().then(_onWidgetUri);
    HomeWidget.widgetClicked.listen(_onWidgetUri);
    // Warm: eigen kanaal vanuit MainActivity (betrouwbaarder dan widgetClicked).
    const MethodChannel('nl.sbuilder.yessfish/widget').setMethodCallHandler((call) async {
      if (call.method == 'route' && call.arguments is String) { _onWidgetUri(Uri.tryParse(call.arguments as String)); }
    });
  }

  void _onWidgetUri(Uri? uri) {
    if (uri == null || !mounted) return;
    if (uri.host == 'catch') { _openQuickCatch(); }
    else if (uri.host == 'spot') { _openQuickSpot(); }
    else if (uri.host == 'view' && uri.pathSegments.isNotEmpty) {
      final id = int.tryParse(uri.pathSegments.first);
      if (id != null) { Navigator.push(context, MaterialPageRoute(builder: (_) => CatchDetailScreen(catchId: id))); }
    }
    else if (uri.host == 'feed') { setState(() { _i = 0; _visited.add(0); }); }
    else if (uri.host == 'map') { setState(() { _i = 3; _visited.add(3); }); }
    else if (uri.host == 'album') { Navigator.push(context, MaterialPageRoute(builder: (_) => const AlbumsScreen())); }
  }

  Future<void> _openQuickCatch() async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const QuickCatchScreen())); }
  Future<void> _openQuickSpot() async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const QuickSpotScreen())); }

  void _openDrafts() { Navigator.push(context, MaterialPageRoute(builder: (_) => const DraftsScreen())); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _i == 3 ? null : AppBar(
        title: const YfLogo(size: 30, light: true),
        actions: [
          IconButton(
            tooltip: _qt(const {'nl': 'Snelvangst', 'en': 'Quick catch', 'de': 'Schnellfang', 'fr': 'Prise rapide', 'es': 'Captura rapida', 'pl': 'Szybki polow'}),
            icon: const Icon(Icons.set_meal, color: AppColors.mint),
            onPressed: _openQuickCatch,
          ),
          IconButton(
            tooltip: _qt(const {'nl': 'Nieuwe stek', 'en': 'New spot', 'de': 'Neue Stelle', 'fr': 'Nouveau spot', 'es': 'Nuevo spot', 'pl': 'Nowe miejsce'}),
            icon: const Icon(Icons.phishing, color: AppColors.mint),
            onPressed: _openQuickSpot,
          ),
          IconButton(
            tooltip: _qt(const {'nl': 'Concepten', 'en': 'Drafts', 'de': 'Entwurfe', 'fr': 'Brouillons', 'es': 'Borradores', 'pl': 'Szkice'}),
            icon: const Icon(Icons.pending_actions, color: AppColors.mint),
            onPressed: _openDrafts,
          ),
          Consumer<RealtimeService>(builder: (_, rt, __) => Stack(alignment: Alignment.center, children: [
            IconButton(icon: const Icon(Icons.notifications_outlined, color: AppColors.mint),
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
