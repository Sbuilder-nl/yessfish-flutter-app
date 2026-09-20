import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/api.dart';
import '../core/config.dart';
import '../core/i18n.dart';
import '../core/gids_i18n.dart';
import 'organisatie_screen.dart';
import 'federatie_screen.dart';

/// Pagina op de website openen in de app-browser (partner worden, adverteren).
Future<void> openWebPagina(String pad) async {
  final lang = I18n.instance?.locale ?? 'nl';
  final url = Uri.parse('${Config.webOrigin}$pad${pad.contains('?') ? '&' : '?'}lang=$lang');
  try { await launchUrl(url, mode: LaunchMode.inAppBrowserView); } catch (_) { await launchUrl(url, mode: LaunchMode.externalApplication); }
}

/// Gids: verenigingen, winkels en jachthavens per land — dezelfde weg als op de website.
///
/// Bij verenigingen kom je niet meteen in een lijst van honderden namen. Je kiest eerst de
/// organisatie (Nederland) of de regio (andere landen), want dáár hangt je vergunning aan. Pas
/// daarna zie je de verenigingen, en via een vereniging haar wateren — en een water opent de kaart.
/// Dat is precies de volgorde van /verenigingen op de site (Richard 20-09-2026).
class GidsScreen extends StatefulWidget {
  final int startTab;
  const GidsScreen({super.key, this.startTab = 0});
  @override
  State<GidsScreen> createState() => _GidsScreenState();
}

class _GidsScreenState extends State<GidsScreen> with SingleTickerProviderStateMixin {
  static const _types = ['clubs', 'shops', 'marinas'];
  late final TabController _tab = TabController(length: 3, vsync: this, initialIndex: widget.startTab);
  String _land = 'NL';
  final _q = TextEditingController();

  @override
  void initState() {
    super.initState();
    const perTaal = {'nl': 'NL', 'de': 'DE', 'fr': 'FR', 'es': 'ES', 'pl': 'PL', 'en': 'GB'};
    _land = perTaal[I18n.instance?.locale] ?? 'NL';
    _tab.addListener(() { if (!_tab.indexIsChanging) setState(() {}); });
  }

  @override
  void dispose() { _q.dispose(); _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    context.watch<I18n>();
    return Scaffold(
      appBar: AppBar(
        title: Text(gt(context, 'title')),
        bottom: TabBar(controller: _tab, labelColor: Colors.white, unselectedLabelColor: Colors.white70, indicatorColor: AppColors.mint, tabs: [
          Tab(icon: const Icon(Icons.anchor, size: 18), text: gt(context, 'clubs')),
          Tab(icon: const Icon(Icons.storefront_outlined, size: 18), text: gt(context, 'shops')),
          Tab(icon: const Icon(Icons.sailing_outlined, size: 18), text: gt(context, 'marinas')),
        ]),
      ),
      body: TabBarView(controller: _tab, children: [for (final t in _types) _Lijst(key: ValueKey('$t-$_land'), type: t, land: _land, q: _q, onLand: (l) => setState(() => _land = l))]),
    );
  }
}

class _Lijst extends StatefulWidget {
  final String type; final String land; final TextEditingController q; final ValueChanged<String> onLand;
  const _Lijst({super.key, required this.type, required this.land, required this.q, required this.onLand});
  @override
  State<_Lijst> createState() => _LijstState();
}

class _LijstState extends State<_Lijst> with AutomaticKeepAliveClientMixin {
  List<dynamic>? _items;
  List<dynamic> _landen = [];
  List<dynamic>? _organisaties;   // Nederland: Sportvisunie, Fryslân, NHO, zelfstandig…
  List<dynamic>? _hoofd;          // andere landen: landelijke organisatie(s)
  List<dynamic> _regios = [];     // andere landen: deelstaten/regio's
  bool _fout = false;
  String _zoek = '';

  /// Welke organisatie het lid heeft aangetikt; leeg = nog bij de tegels.
  String? _gekozen;

  @override bool get wantKeepAlive => true;

  @override
  void initState() { super.initState(); _laad(); }

  Future<void> _laad() async {
    setState(() { _fout = false; _items = null; });
    try {
      final r = await Future.wait([
        Api.get('/directory/${widget.type}/countries'),
        Api.get('/directory/${widget.type}?country=${widget.land}'),
      ]);
      if (!mounted) return;
      final lijst = r[1];
      setState(() {
        _landen = (r[0] is Map ? r[0]['data'] : []) ?? [];
        _items = (lijst is Map ? lijst['data'] : []) ?? [];
        _organisaties = lijst is Map && lijst['organisations'] is List ? lijst['organisations'] as List : null;
        _hoofd = lijst is Map && lijst['roots'] is List ? lijst['roots'] as List : null;
        _regios = lijst is Map && lijst['regions'] is List ? lijst['regions'] as List : [];
        _gekozen = null;
      });
    } catch (_) { if (mounted) setState(() => _fout = true); }
  }

  String _landNaam(String code) {
    const n = {'NL': '🇳🇱 Nederland', 'BE': '🇧🇪 België', 'DE': '🇩🇪 Deutschland', 'FR': '🇫🇷 France', 'GB': '🇬🇧 United Kingdom', 'IE': '🇮🇪 Ireland', 'ES': '🇪🇸 España', 'PL': '🇵🇱 Polska', 'AT': '🇦🇹 Österreich', 'CH': '🇨🇭 Schweiz', 'CZ': '🇨🇿 Česko', 'IT': '🇮🇹 Italia', 'DK': '🇩🇰 Danmark', 'LU': '🇱🇺 Luxembourg', 'SE': '🇸🇪 Sverige', 'NO': '🇳🇴 Norge', 'FI': '🇫🇮 Suomi', 'PT': '🇵🇹 Portugal'};
    return n[code] ?? code;
  }

  /// Vertaalde velden van de server overnemen, net als `trContent` op het web.
  Map _inTaal(Map o, String taal) {
    if (taal == 'nl') return o;
    final t = o['translations'];
    if (t is! Map || t[taal] is! Map) return o;
    final uit = Map.of(o);
    (t[taal] as Map).forEach((k, v) { if (v != null && v is! Map && v is! List && '$v'.isNotEmpty) uit[k] = v; });
    return uit;
  }

  String _tekst(dynamic v) => v == null ? '' : '$v';

  /// Vaste Nederlandse organisatieteksten uit het woordenboek; namen van federaties blijven eigennamen.
  String _orgTekst(BuildContext c, String soort, String sleutel, String terugval) {
    final v = gt(c, '${soort}_$sleutel');
    return v == '${soort}_$sleutel' ? terugval : v;
  }

  void _open(String href, String? naam) {
    if (href.isEmpty) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => OrganisatieScreen(href: href, naam: naam)));
  }

  void _openFederatie(String href, String? naam) {
    if (href.isEmpty) return;
    final delen = Uri.tryParse(href)?.pathSegments.where((d) => d.isNotEmpty).toList() ?? [];
    if (delen.length > 1 && delen.first == 'federatie') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => FederatieScreen(slug: delen[1], naam: naam)));
    } else {
      _open(href, naam);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final taal = Provider.of<I18n>(context, listen: false).locale;
    final zoek = _zoek.trim().toLowerCase();
    final items = (_items ?? []).where((i) => zoek.isEmpty || '${i['name']} ${i['region'] ?? ''}'.toLowerCase().contains(zoek)).toList();
    final landen = [..._landen];
    if (!landen.any((l) => l['code'] == widget.land)) landen.add({'code': widget.land, 'count': 0});

    return Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(12, 10, 12, 4), child: Row(children: [
        DropdownButton<String>(
          value: widget.land, underline: const SizedBox.shrink(),
          items: [for (final l in landen) DropdownMenuItem(value: '${l['code']}', child: Text('${_landNaam('${l['code']}')} (${l['count']})'))],
          onChanged: (v) { if (v != null) widget.onLand(v); },
        ),
        const SizedBox(width: 10),
        Expanded(child: TextField(
          controller: widget.q, onChanged: (v) => setState(() => _zoek = v.trim()),
          decoration: InputDecoration(isDense: true, prefixIcon: const Icon(Icons.search, size: 18), hintText: gt(context, 'search'), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
        )),
      ])),
      Expanded(child: _fout
          ? Center(child: TextButton(onPressed: _laad, child: Text(gt(context, 'error'))))
          : _items == null
              ? Center(child: Text(gt(context, 'loading')))
              : RefreshIndicator(onRefresh: _laad, child: _body(context, taal, items, zoek))),
    ]);
  }

  Widget _body(BuildContext c, String taal, List items, String zoek) {
    // Verenigingen in Nederland: eerst de organisatie kiezen (die bepaalt je pas).
    if (widget.type == 'clubs' && _organisaties != null) return _organisatieWeg(c, items, zoek);
    // Verenigingen in een ander land: landelijke organisatie + regio's, want daar zit de vergunning.
    if (widget.type == 'clubs' && _hoofd != null) return _landWeg(c, taal, items, zoek);
    return _rijenLijst(c, items);
  }

  // ── Nederland ───────────────────────────────────────────────────────────────────────────────
  Widget _organisatieWeg(BuildContext c, List items, String zoek) {
    final koepels = items.where((i) => i['kind'] != 'club').toList();
    final orgs = [..._organisaties!];

    // Nog niets gekozen en niet gezocht: de tegels.
    if (_gekozen == null && zoek.isEmpty) {
      final tegels = [
        for (final o in orgs) if (((o['count'] as num?)?.toInt() ?? 0) > 0) o,
        if (koepels.isNotEmpty) {'key': 'koepels', 'naam': gt(c, 'org_federations'), 'pas': '', 'uitleg': '', 'count': koepels.length},
      ];
      return ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        children: [
          Text(gt(c, 'org_choose'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.navy)),
          const SizedBox(height: 4),
          Text(gt(c, 'org_choose_sub'), style: const TextStyle(fontSize: 13.5, height: 1.4, color: Colors.black54)),
          const SizedBox(height: 12),
          for (final o in tegels) _orgTegel(c, o as Map),
        ],
      );
    }

    final gekozen = _gekozen;
    final lijst = zoek.isNotEmpty && gekozen == null
        ? items
        : gekozen == 'koepels'
            ? koepels
            : items.where((i) => i['organisation'] == gekozen).toList();
    final gekozenOrg = gekozen == null ? null : orgs.cast<Map?>().firstWhere((o) => o?['key'] == gekozen, orElse: () => null);

    // Per provincie groeperen, net als op het web — anders is het één muur van namen.
    final groepen = <String, List>{};
    for (final i in lijst) {
      final k = (gekozen == 'koepels' || gekozen == null) ? '' : _tekst(i['province']).isEmpty ? gt(c, 'prov_unknown') : _tekst(i['province']);
      groepen.putIfAbsent(k, () => []).add(i);
    }
    final sleutels = groepen.keys.toList()
      ..sort((a, b) => a == gt(c, 'prov_unknown') ? 1 : b == gt(c, 'prov_unknown') ? -1 : a.compareTo(b));

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      children: [
        if (gekozen != null)
          Align(alignment: Alignment.centerLeft, child: TextButton.icon(
            onPressed: () => setState(() => _gekozen = null),
            icon: const Icon(Icons.arrow_back, size: 16),
            label: Text(gt(c, 'org_back')),
            style: TextButton.styleFrom(foregroundColor: AppColors.teal, padding: EdgeInsets.zero),
          )),
        if (gekozenOrg != null) _orgKop(c, gekozenOrg),
        if (zoek.isNotEmpty && gekozen == null)
          Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(gt(c, 'org_search_all'),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54))),
        if (lijst.isEmpty) Padding(padding: const EdgeInsets.all(32), child: Center(child: Text(gt(c, 'dir_empty'), textAlign: TextAlign.center))),
        for (final p in sleutels) ...[
          if (p.isNotEmpty) Padding(padding: const EdgeInsets.fromLTRB(2, 14, 0, 4),
              child: Text('$p (${groepen[p]!.length})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54))),
          for (final i in groepen[p]!) _rij(c, i as Map),
        ],
      ],
    );
  }

  Widget _orgTegel(BuildContext c, Map o) {
    final sleutel = _tekst(o['key']);
    final naam = _orgTekst(c, 'org_naam', sleutel, _tekst(o['naam']));
    final pas = _orgTekst(c, 'org_pas', sleutel, _tekst(o['pas']));
    final uitleg = _orgTekst(c, 'org_uitleg', sleutel, _tekst(o['uitleg']));
    final href = _tekst(o['href']);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => setState(() => _gekozen = sleutel),
        child: IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(width: 6, color: _orgKleur(sleutel)),
          Expanded(child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(naam, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy))),
                Text(gt(c, 'org_count', {'n': '${(o['count'] as num?)?.toInt() ?? 0}'}), style: const TextStyle(fontSize: 12, color: Colors.black45)),
              ]),
              if (pas.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: _speld(gt(c, 'org_pass', {'pas': pas}))),
              if (uitleg.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8),
                  child: Text(uitleg, style: const TextStyle(fontSize: 13, height: 1.35, color: Colors.black54))),
              if (href.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: InkWell(
                onTap: () => _openFederatie(href, naam),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(gt(c, 'fed_profile_link'), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.teal)),
                  const Icon(Icons.chevron_right, size: 16, color: AppColors.teal),
                ]),
              )),
            ]),
          )),
        ])),
      ),
    );
  }

  Widget _orgKop(BuildContext c, Map o) {
    final sleutel = _tekst(o['key']);
    final naam = _orgTekst(c, 'org_naam', sleutel, _tekst(o['naam']));
    final pas = _orgTekst(c, 'org_pas', sleutel, _tekst(o['pas']));
    final uitleg = _orgTekst(c, 'org_uitleg', sleutel, _tekst(o['uitleg']));
    final href = _tekst(o['href']);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(width: 6, color: _orgKleur(sleutel)),
        Expanded(child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(naam, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.navy)),
            if (pas.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4),
                child: Text(gt(c, 'org_member_gives', {'pas': pas}), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
            if (uitleg.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4),
                child: Text(uitleg, style: const TextStyle(fontSize: 13, height: 1.35, color: Colors.black54))),
            if (href.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: InkWell(
              onTap: () => _openFederatie(href, naam),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(gt(c, 'fed_profile_link'), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.teal)),
                const Icon(Icons.chevron_right, size: 16, color: AppColors.teal),
              ]),
            )),
          ]),
        )),
      ])),
    );
  }

  // ── Andere landen ───────────────────────────────────────────────────────────────────────────
  Widget _landWeg(BuildContext c, String taal, List items, String zoek) {
    final hoofd = _hoofd!.map((r) => _inTaal(r as Map, taal)).toList();
    final naamPerSleutel = {for (final r in hoofd) _tekst(r['key']): _tekst(r['naam'])};
    final regios = _regios
        .map((r) => _inTaal(r as Map, taal))
        .where((r) => zoek.isEmpty || '${r['naam']} ${r['pas'] ?? ''}'.toLowerCase().contains(zoek))
        .toList();
    final clubs = items.where((i) => i['kind'] == 'club').toList();
    final landNaam = _landNaam(widget.land).replaceAll(RegExp(r'^\S+\s'), '');

    // Regio's groeperen onder hun landelijke organisatie als er meer dan één is (bv. VK).
    final groepen = <String, List>{};
    for (final r in regios) {
      final k = hoofd.length > 1 ? (naamPerSleutel[_tekst(r['parent'])] ?? _tekst(r['parent_name'])) : '';
      groepen.putIfAbsent(k, () => []).add(r);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      children: [
        Text(gt(c, 'land_how', {'land': landNaam}), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.navy)),
        const SizedBox(height: 4),
        Text(gt(c, 'land_how_sub'), style: const TextStyle(fontSize: 13.5, height: 1.4, color: Colors.black54)),
        const SizedBox(height: 10),
        for (final r in hoofd) _gebiedTegel(c, r, groot: true),
        if (_regios.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text('${gt(c, 'land_regions')} (${_regios.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy)),
          const SizedBox(height: 4),
          Text(gt(c, 'land_regions_sub'), style: const TextStyle(fontSize: 13.5, height: 1.4, color: Colors.black54)),
          const SizedBox(height: 10),
          if (regios.isEmpty) Padding(padding: const EdgeInsets.all(24), child: Center(child: Text(gt(c, 'dir_empty')))),
          for (final g in groepen.keys) ...[
            if (g.isNotEmpty) Padding(padding: const EdgeInsets.fromLTRB(2, 8, 0, 4),
                child: Text('$g (${groepen[g]!.length})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54))),
            for (final r in groepen[g]!) _gebiedTegel(c, r as Map),
          ],
        ],
        const SizedBox(height: 18),
        Text('${gt(c, 'land_clubs')} (${clubs.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy)),
        const SizedBox(height: 6),
        if (clubs.isEmpty)
          Padding(padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(gt(c, 'land_clubs_empty'), style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.black54)))
        else
          for (final i in clubs) _rij(c, i as Map),
      ],
    );
  }

  Widget _gebiedTegel(BuildContext c, Map r, {bool groot = false}) {
    final naam = _tekst(r['naam']);
    final pas = _tekst(r['pas']);
    final uitleg = _tekst(r['uitleg']);
    final aantal = (r['count'] as num?)?.toInt() ?? 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openFederatie(_tekst(r['href']), naam),
        child: IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(width: 6, color: groot ? AppColors.navy : AppColors.teal),
          Expanded(child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(naam, style: TextStyle(fontSize: groot ? 17 : 15, fontWeight: FontWeight.bold, color: AppColors.navy)),
              Padding(padding: const EdgeInsets.only(top: 6), child: Wrap(spacing: 6, runSpacing: 6, children: [
                if (pas.isNotEmpty) _speld(gt(c, 'org_pass', {'pas': pas})),
                if (aantal > 0) _speld(gt(c, 'org_count', {'n': '$aantal'})),
                if (r['has_prices'] == true) _speld(gt(c, 'fed_prices_known'), groen: true),
              ])),
              if (uitleg.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(uitleg,
                  maxLines: groot ? 6 : 3, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, height: 1.35, color: Colors.black54))),
              Padding(padding: const EdgeInsets.only(top: 8), child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(gt(c, 'fed_profile_link'), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.teal)),
                const Icon(Icons.chevron_right, size: 16, color: AppColors.teal),
              ])),
            ]),
          )),
        ])),
      ),
    );
  }

  // ── Gedeeld ─────────────────────────────────────────────────────────────────────────────────
  Widget _rijenLijst(BuildContext c, List items) {
    if (items.isEmpty) {
      return ListView(children: [Padding(padding: const EdgeInsets.all(32), child: Center(child: Text(gt(c, 'empty'), textAlign: TextAlign.center)))]);
    }
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) => _rij(c, items[i] as Map, kaal: true),
    );
  }

  Widget _rij(BuildContext c, Map it, {bool kaal = false}) {
    final zelf = it['managed_by'] == 'self';
    final n = (it['waters_count'] as num?)?.toInt() ?? 0;
    final icoon = widget.type == 'clubs'
        ? (it['kind'] == 'club' ? Icons.groups_outlined : Icons.account_balance_outlined)
        : widget.type == 'shops' ? Icons.storefront_outlined : Icons.sailing_outlined;
    final tegel = ListTile(
      contentPadding: kaal ? null : const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      leading: CircleAvatar(
        backgroundColor: AppColors.teal.withValues(alpha: 0.1),
        child: it['logo'] != null
            ? ClipOval(child: Image.network('${it['logo']}', width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(icoon, color: AppColors.teal)))
            : Icon(icoon, color: AppColors.teal),
      ),
      title: Text('${it['name']}', maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text([
        if (_tekst(it['region']).isNotEmpty) _tekst(it['region']),
        if (n > 0) gt(c, 'club_waters', {'n': '$n'}),
        zelf ? gt(c, 'managed_self') : gt(c, 'managed_yf'),
      ].join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.chevron_right),
      // In de app openen, niet in een browser: een gidspagina op de site is voor leden en een
      // browser komt daar op een inlogmuur uit.
      onTap: it['href'] != null ? () => _open('${it['href']}', it['name']?.toString()) : null,
    );
    if (kaal) return tegel;
    return Card(margin: const EdgeInsets.only(bottom: 6), child: tegel);
  }

  Widget _speld(String tekst, {bool groen = false}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: groen ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(tekst, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: groen ? const Color(0xFF047857) : const Color(0xFF334155))),
      );

  Color _orgKleur(String sleutel) => const {
        'sportvisunie': Color(0xFF2F7FB8),
        'fryslan': Color(0xFFD85C26),
        'nho': Color(0xFFD4A017),
        'zelfstandig': Color(0xFF6B7280),
        'nieuw': Color(0xFF1F8A70),
        'koepels': Color(0xFF0A3D62),
      }[sleutel] ?? AppColors.teal;
}
