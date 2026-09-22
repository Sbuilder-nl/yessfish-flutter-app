import 'dart:async';
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
import 'sterren_screen.dart';
import 'wedstrijd_screen.dart';
import 'gids_screen.dart';
import 'settings_screen.dart';
import 'friends_screen.dart';
import 'messages_screen.dart';
import 'albums_screen.dart';
import 'tackle_screen.dart';
import 'licenses_screen.dart';
import 'mijn_data_screen.dart';
import 'species_screen.dart';
import 'weather_screen.dart';
import 'identify_screen.dart';
import 'vis_ai_screen.dart';
import 'discipline_dashboards_screen.dart';
import 'vistijl_tools_screen.dart';
import 'schone_stek_screen.dart';
import 'clubs_screen.dart';
import 'tournaments_screen.dart';
import 'leaderboard_screen.dart';
import 'toplist_screen.dart';
import 'parental_screen.dart';
import 'new_catch_screen.dart';
import '../widgets/hulp_knop.dart';
import '../widgets/yf_logo.dart';
import 'package:quick_actions/quick_actions.dart';
import 'quick_catch_screen.dart';
import 'quick_spot_screen.dart';
import 'drafts_screen.dart';
import 'package:home_widget/home_widget.dart';
import '../core/home_widget_service.dart';
import 'catch_detail_screen.dart';
import '../widgets/streak_card.dart';
import '../core/rondleiding.dart';
import '../widgets/rondleiding_overlay.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _i = 0;
  final Set<int> _visited = {0};
  final GlobalKey<FeedScreenState> _feedKey = GlobalKey<FeedScreenState>();

  /// De rondleiding moet zelf naar het juiste tabblad kunnen springen: een stap over de kaart
  /// heeft geen zin als het lid nog in de feed staat. Daarom geeft dit scherm die schakelaar
  /// door zodra het opent (Richard 19-09-2026).
  void _naarTab(int tab) {
    if (!mounted || tab < 0 || tab > 4) return;
    setState(() { _i = tab; _visited.add(tab); });
  }

  Widget _pageFor(int idx) {
    switch (idx) {
      case 0: return FeedScreen(key: _feedKey);
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
    Rondleiding.gaNaarTab = _naarTab;
    Rondleiding.naarScherm = _rondleidingNaarScherm;
    WidgetsBinding.instance.addPostFrameCallback((_) { _checkUpdate(); AppConfig.load(); context.read<AuthState>().refresh(); _initQuickActions(); _initHomeWidget(); _startVragen(); });

    // Fotostand: de rondleiding zelf starten zodra het beginscherm staat. Anders moet er voor
    // elke taal met de hand door het menu naar de Handleiding getikt worden, en dat is zes keer
    // dezelfde kans op een misser. Alleen actief in een build met --dart-define=TOUR_SHOTS=true.
    if (const bool.fromEnvironment('TOUR_SHOTS')) {
      Future.delayed(const Duration(seconds: 6), () {
        if (mounted) Rondleiding.start(context);
      });
    }
  }

  /// Welk los scherm de rondleiding kan openen. De sleutel staat bij de stap (`scherm:`).
  ///
  /// Zonder dit kon de rondleiding alleen tussen de vijf tabbladen springen, en bleef alles achter
  /// een menutegel onverteld — bijna de helft van het verhaal dat de site wél vertelt.
  static final Map<String, Widget Function()> _rondleidingSchermen = {
    'sterren': () => const SterrenScreen(),
    'wedstrijd': () => const WedstrijdScreen(),
    'gids': () => const GidsScreen(),
    'instellingen': () => const SettingsScreen(),
    'vismaten': () => const FriendsScreen(),
    'berichten': () => const MessagesScreen(),
    'meldingen': () => const NotificationsScreen(),
    'albums': () => const AlbumsScreen(),
    'uitrusting': () => const TackleScreen(),
    'documenten': () => const LicensesScreen(),
    'mijndata': () => const MijnDataScreen(),
    'soorten': () => const SpeciesScreen(),
    'weer': () => const WeatherScreen(),
    'herkennen': () => const IdentifyScreen(),
    'visai': () => const VisAiScreen(),
    'stijlen': () => const DisciplineDashboardsScreen(),
    'stijlen-kiezen': () => const DisciplinesScreen(),
    'stijl-tools': () => const VistijlToolsScreen(),
    'schone-stek': () => const SchoneStekScreen(),
    'clubs': () => const ClubsScreen(),
    'toernooien': () => const TournamentsScreen(),
    'ranglijst': () => const LeaderboardScreen(),
    'toplijst': () => const ToplistScreen(),
    'ouder': () => const ParentalScreen(),
    'nieuwe-vangst': () => const NewCatchScreen(),
  };

  /// Open (of sluit) een scherm voor de rondleiding. null = terug naar de tabbladen.
  Future<void> _rondleidingNaarScherm(String? sleutel) async {
    if (!mounted) return;
    final nav = Navigator.of(context);
    // Eerst terug naar het hoofdscherm, zodat schermen niet op elkaar stapelen.
    nav.popUntil((r) => r.isFirst);
    if (sleutel == null) return;
    final bouwer = _rondleidingSchermen[sleutel];
    if (bouwer == null) return;
    // NIET await'en op de push: die belofte komt pas terug als het scherm weer dichtgaat, dus
    // de rondleiding bleef er voorgoed op wachten. Met 24 schermstappen liepen die hangende
    // wachtjes op tot de rondleiding op de Dobbers-stap stil bleef staan (gemeten 21-09-2026).
    // We wachten alleen even tot het scherm is opgebouwd, zodat de knop er staat.
    unawaited(nav.push(MaterialPageRoute(builder: (_) => bouwer())));
    await Future<void>.delayed(const Duration(milliseconds: 350));
  }

  @override
  void dispose() {
    if (Rondleiding.gaNaarTab == _naarTab) Rondleiding.gaNaarTab = null;
    if (Rondleiding.naarScherm == _rondleidingNaarScherm) Rondleiding.naarScherm = null;
    super.dispose();
  }

  /// Nieuw lid dat de rondleiding nog nooit heeft gezien: één keer aanbieden.
  ///
  /// De server bepaalt dat (`suggest`), niet de telefoon. Zo klopt het ook als iemand zich op de
  /// site aanmeldde en daarna de app installeert, en werkt een reset echt (Richard 19-09-2026).
  Future<void> _rondleidingAanbieden() async {
    final stand = await Rondleiding.stand();
    if (!mounted || stand == null || stand['suggest'] != true) return;
    final ja = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      scrollable: true,
      title: Text(_qt(const {'nl': 'Zal ik je rondleiden?', 'en': 'Shall I show you around?', 'de': 'Soll ich dir alles zeigen?', 'fr': 'Je te fais visiter ?', 'es': '¿Te doy una vuelta?', 'pl': 'Oprowadzić cię?'})),
      content: Text(_qt(const {
        'nl': 'We lopen samen door de app: waar je vangsten meldt, hoe de viskaart werkt en wat er allemaal in zit. Duurt een paar minuten en je kunt altijd stoppen.',
        'en': 'We will walk through the app together: where you log catches, how the map works and what else is in there. Takes a few minutes and you can stop any time.',
        'de': 'Wir gehen zusammen durch die App: wo du Fänge meldest, wie die Karte funktioniert und was noch drin steckt. Dauert ein paar Minuten, Abbrechen jederzeit.',
        'fr': 'On parcourt l’app ensemble : où déclarer tes prises, comment marche la carte et tout le reste. Quelques minutes, tu peux arrêter quand tu veux.',
        'es': 'Recorremos la app juntos: dónde registrar capturas, cómo funciona el mapa y qué más hay. Unos minutos y puedes parar cuando quieras.',
        'pl': 'Przejdziemy przez aplikację razem: gdzie zgłaszasz połowy, jak działa mapa i co jeszcze tu jest. Kilka minut, możesz przerwać.',
      })),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false),
          child: Text(_qt(const {'nl': 'Liever later', 'en': 'Maybe later', 'de': 'Lieber später', 'fr': 'Plus tard', 'es': 'Más tarde', 'pl': 'Może później'}))),
        FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
          onPressed: () => Navigator.pop(c, true),
          child: Text(_qt(const {'nl': 'Neem me mee', 'en': 'Show me', 'de': 'Zeig es mir', 'fr': 'Montre-moi', 'es': 'Enséñame', 'pl': 'Pokaż mi'}))),
      ],
    ));
    if (!mounted) return;
    if (ja == true) {
      Rondleiding.start(context);
    } else {
      Rondleiding.overslaan();
    }
  }

  /// Openingsvragen netjes achter elkaar in plaats van tegelijk.
  ///
  /// Anders staan de visstijlen-vraag en de rondleiding-uitnodiging over elkaar heen — op de
  /// emulator gezien en precies waar Richard op het web ook over viel: twee vensters tegelijk
  /// (19-09-2026).
  Future<void> _startVragen() async {
    await _maybePromptDisciplines();
    if (!mounted) return;
    await _rondleidingAanbieden();
  }

  // Bestaande én nieuwe accounts: als er nog geen visstijlen gekozen zijn,
  // bied de keuze actief aan zodat de dashboards verschijnen.
  Future<void> _maybePromptDisciplines() async {
    try {
      final r = await Api.get('/profile/disciplines');
      final list = (r is Map ? r['disciplines'] : null) as List?;
      if (list == null || list.isNotEmpty || !mounted) return;
      await showDialog(context: context, builder: (ctx) => AlertDialog(
        scrollable: true,
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
      scrollable: true,
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
          // Vraagteken: uitleg over het scherm waar je nu bent, net als op de site.
          TourAnker(id: 'hulp-knop', child: HulpKnop(hoofdstuk: const ['feed', 'vangst', 'weer', 'kaart', 'start'][_i])),
          TourAnker(id: 'vangst-snel', child: IconButton(
            tooltip: _qt(const {'nl': 'Snelvangst', 'en': 'Quick catch', 'de': 'Schnellfang', 'fr': 'Prise rapide', 'es': 'Captura rapida', 'pl': 'Szybki polow'}),
            icon: const Icon(Icons.set_meal, color: AppColors.mint),
            onPressed: _openQuickCatch,
          )),
          IconButton(
            tooltip: _qt(const {'nl': 'Nieuwe stek', 'en': 'New spot', 'de': 'Neue Stelle', 'fr': 'Nouveau spot', 'es': 'Nuevo spot', 'pl': 'Nowe miejsce'}),
            icon: const Icon(Icons.phishing, color: AppColors.mint),
            onPressed: _openQuickSpot,
          ),
          TourAnker(id: 'vangst-concepten', child: IconButton(
            tooltip: _qt(const {'nl': 'Concepten', 'en': 'Drafts', 'de': 'Entwurfe', 'fr': 'Brouillons', 'es': 'Borradores', 'pl': 'Szkice'}),
            icon: const Icon(Icons.pending_actions, color: AppColors.mint),
            onPressed: _openDrafts,
          )),
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
        Offstage(offstage: !(_i == 0 || _i == 2), child: TourAnker(id: 'reeks-balk', child: StreakBanner(onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const SterrenScreen())); StreakData.load(force: true); }))),
        Expanded(child: IndexedStack(index: _i, children: List.generate(5, (idx) => _visited.contains(idx) ? _pageFor(idx) : const SizedBox.shrink()))),
      ]),
      bottomNavigationBar: TourAnker(id: 'nav-balk', child: NavigationBar(
        selectedIndex: _i,
        onDestinationSelected: (v) {
          // terug naar (of nogmaals op) de feed-tab → altijd bovenaan beginnen
          if (v == 0) WidgetsBinding.instance.addPostFrameCallback((_) => _feedKey.currentState?.scrollNaarTop());
          setState(() { _i = v; _visited.add(v); });
          StreakData.verversStraks(); StreakData.verversStraks(const Duration(seconds: 8));   // bijtkans/water bekeken → reeks-balk bijwerken
        },
        backgroundColor: Colors.white,
        indicatorColor: AppColors.teal.withValues(alpha: 0.15),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.dynamic_feed_outlined), selectedIcon: const Icon(Icons.dynamic_feed), label: context.tr('nav.feed')),
          NavigationDestination(icon: const Icon(Icons.set_meal_outlined), selectedIcon: const Icon(Icons.set_meal), label: context.tr('nav.catches')),
          NavigationDestination(icon: const Icon(Icons.water_outlined), selectedIcon: const Icon(Icons.water), label: context.tr('nav.bite')),
          NavigationDestination(icon: const Icon(Icons.map_outlined), selectedIcon: const Icon(Icons.map), label: context.tr('nav.map')),
          NavigationDestination(icon: const Icon(Icons.grid_view_outlined), selectedIcon: const Icon(Icons.grid_view), label: context.tr('nav.menu')),
        ],
      )),
    );
  }
}
