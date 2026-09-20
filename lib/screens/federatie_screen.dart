import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/api.dart';
import '../core/config.dart';
import '../core/i18n.dart';
import '../core/gids_i18n.dart';
import '../core/rondleiding.dart';
import 'organisatie_screen.dart';
import 'map_screen.dart';

/// Federatie-scherm: welke visorganisatie hoort bij een water en welke vergunning geldt daar.
///
/// Dit is de app-kant van `/federatie/<slug>` op het web (FederationView) en vertelt bewust
/// HETZELFDE verhaal: naam, vergunning, samenvatting, regels (ook die van de bovenliggende
/// organisatie), prijzen, officiële links en de bronnen met controledatum.
///
/// Het gaat hier over visregels. We tonen daarom uitsluitend wat de server teruggeeft; is een
/// blok leeg, dan laten we het weg in plaats van er "onbekend" van te maken. De bronnen en de
/// officiële site staan er altijd bij, zodat het lid het zelf kan nakijken.
class FederatieScreen extends StatefulWidget {
  const FederatieScreen({super.key, required this.slug, this.naam});

  final String slug;

  /// Al bekende naam (bv. uit het waterblad), zodat de titelbalk tijdens het laden niet leeg is.
  final String? naam;

  @override
  State<FederatieScreen> createState() => _FederatieScreenState();
}

class _FederatieScreenState extends State<FederatieScreen> {
  Map? _federatie;
  bool _laden = true;
  bool _fout = false;
  bool _nietGevonden = false;

  /// Zoeken en uitklappen in de twee lange lijsten onderaan: de wateren en de verenigingen.
  /// Die lijsten kunnen honderden regels lang zijn, dus we tonen er eerst een deel van.
  final _waterZoek = TextEditingController();
  final _clubZoek = TextEditingController();
  String _waterFilter = '';
  String _clubFilter = '';
  String? _openVerenigingHref;
  bool _alleEigenWateren = false;
  bool _alleVerenigingen = false;

  @override
  void initState() {
    super.initState();
    _haalOp();
  }

  @override
  void dispose() {
    _waterZoek.dispose();
    _clubZoek.dispose();
    super.dispose();
  }

  Future<void> _haalOp() async {
    setState(() {
      _laden = true;
      _fout = false;
      _nietGevonden = false;
    });
    try {
      final r = await Api.get('/directory/federation/${Uri.encodeComponent(widget.slug)}');
      final data = (r is Map && r['data'] is Map) ? r['data'] as Map : null;
      if (!mounted) return;
      setState(() {
        _federatie = data;
        _nietGevonden = data == null;
        _laden = false;
      });
    } on ApiException catch (e) {
      // 404 = deze organisatie bestaat echt niet; al het andere is een storing en mag niet als
      // "niet gevonden" op het scherm komen (zelfde onderscheid als op het web).
      if (!mounted) return;
      setState(() {
        _nietGevonden = e.status == 404;
        _fout = e.status != 404;
        _laden = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _fout = true;
        _laden = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<I18n>(); // bij een taalwissel opnieuw opbouwen
    final taal = context.read<I18n>().locale;
    final bron = _federatie;
    final f = bron == null ? null : _inhoudInTaal(bron, taal, hernoem: const {'pass_name': 'pas'});
    final titel = _tekst(f?['name']).isNotEmpty
        ? _tekst(f!['name'])
        : (widget.naam ?? _t(context, _lSchermTitel));

    return Scaffold(
      appBar: AppBar(title: Text(titel)),
      body: _laden
          ? const Center(child: CircularProgressIndicator())
          : f == null
              ? _melding(context)
              : RefreshIndicator(onRefresh: _haalOp, child: _inhoud(context, f, taal)),
    );
  }

  /// Niets te tonen: niet gevonden of een storing (met een knop om het nog eens te proberen).
  Widget _melding(BuildContext c) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 48),
          Icon(_nietGevonden ? Icons.search_off : Icons.cloud_off, size: 40, color: Colors.black26),
          const SizedBox(height: 12),
          Text(
            _t(c, _nietGevonden ? _lNietGevonden : _lFout),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
          // Alleen bij een storing heeft het zin om het nog eens te proberen; een organisatie
          // die niet bestaat, verschijnt ook niet na een tweede poging.
          if (_fout) ...[
            const SizedBox(height: 16),
            Center(child: FilledButton(onPressed: _haalOp, child: Text(_t(c, _lOpnieuw)))),
          ],
        ],
      );

  Widget _inhoud(BuildContext c, Map f, String taal) {
    final pas = _tekst(f['pas']);
    final samenvatting = _tekst(f['summary']);
    final regels = _lijst(f['rules']);
    final geerfd = _lijst(f['inherited_rules']).map((g) => _inhoudInTaal(g as Map, taal)).toList();
    final prijzen = _lijst(f['prices']);
    final links = _lijst(f['links']);
    final bronnen = _lijst(f['sources']);
    final kinderen = _lijst(f['children']).map((k) => _inhoudInTaal(k as Map, taal)).toList();
    final pad = _lijst(f['path']).map((p) => _inhoudInTaal(p as Map, taal)).toList();
    final aantalVerenigingen = _lijst(f['clubs']).length;
    final gecontroleerd = _tekst(f['verified_at']);
    final site = links.isNotEmpty ? _tekst((links.first as Map)['url']) : '';

    return ListView(
      padding: const EdgeInsets.all(16) + EdgeInsets.only(bottom: 24 + MediaQuery.of(c).padding.bottom),
      children: [
        // Kruimelpad naar de bovenliggende organisatie (land → regio), net als op het web.
        if (pad.isNotEmpty)
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final p in pad)
                TextButton.icon(
                  onPressed: () => _openFederatie(_tekst(p['href']), _tekst(p['name'])),
                  icon: const Icon(Icons.arrow_upward, size: 15),
                  label: Text(_tekst(p['name'])),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.teal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
        Text(_tekst(f['name']), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.navy)),
        if (aantalVerenigingen > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _t(c, _lAantalVerenigingen).replaceAll('{n}', '$aantalVerenigingen'),
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ),

        // De vergunning is waar het lid voor komt: die staat vooraan en is het anker van de rondleiding.
        if (pas.isNotEmpty) ...[
          const SizedBox(height: 14),
          TourAnker(
            id: 'federatie-vergunning',
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(14)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.badge_outlined, size: 16, color: AppColors.teal),
                    const SizedBox(width: 6),
                    Text(_t(c, _lPas), style: const TextStyle(fontSize: 11, color: Colors.black54)),
                  ]),
                  const SizedBox(height: 4),
                  Text(pas, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy)),
                ],
              ),
            ),
          ),
        ],

        if (samenvatting.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(samenvatting, style: const TextStyle(fontSize: 15, height: 1.45)),
        ],

        // Beheerd door YessFish = uit openbare bronnen verzameld, dus zonder garantie. Die
        // waarschuwing hoort er altijd bij (zelfde tekst als op het web).
        if (f['managed_by'] == 'yessfish') ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              border: Border.all(color: const Color(0xFFFCD34D)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFD97706)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_t(c, _lGeenGarantieTitel),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF78350F))),
                  const SizedBox(height: 2),
                  Text(_t(c, _lGeenGarantie), style: const TextStyle(fontSize: 12, height: 1.35, color: Color(0xFF78350F))),
                ]),
              ),
            ]),
          ),
        ],

        if (links.isNotEmpty) ...[
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final l in links)
                if (_tekst((l as Map)['url']).isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () => _openLink(_tekst(l['url'])),
                    icon: const Icon(Icons.open_in_new, size: 15),
                    label: Text(
                      _tekst(l['label']).isNotEmpty ? _tekst(l['label']) : _t(c, _lOfficieleSite),
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.navy),
                  ),
            ],
          ),
        ],

        // Regels: alleen tonen als de server ze heeft. Geen regels verzinnen, geen lege huls.
        if (regels.isNotEmpty || geerfd.isNotEmpty) ...[
          const Divider(height: 32),
          _kopje(c, Icons.rule, _t(c, _lRegels)),
          const SizedBox(height: 8),
          for (final r in regels) _regel(r as Map),
          for (final g in geerfd) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () => _openFederatie(_tekst(g['href']), _tekst(g['from'])),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  _t(c, _lOokVan).replaceAll('{org}', _tekst(g['from'])),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.teal),
                ),
              ),
            ),
            for (final r in _lijst(g['rules'])) _regel(r as Map),
          ],
          const SizedBox(height: 8),
          Text(_t(c, _lRegelsExtra), style: const TextStyle(fontSize: 11, color: Colors.black38)),
        ],

        // Prijzen: alleen bedragen die de server bevestigd heeft. Niets erbij, niets afronden.
        if (prijzen.isNotEmpty) ...[
          const Divider(height: 32),
          _kopje(c, Icons.local_offer_outlined, _t(c, _lPrijzen)),
          const SizedBox(height: 4),
          for (final p in prijzen) _prijs(p as Map),
        ],

        if (site.isNotEmpty) ...[
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _openLink(site),
            icon: const Icon(Icons.open_in_new, size: 16),
            label: Text(_t(c, _lOfficieleSite)),
            style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
          ),
          const SizedBox(height: 6),
          Text(_t(c, _lMeerInfo), style: const TextStyle(fontSize: 11, color: Colors.black38)),
        ],

        if (kinderen.isNotEmpty) ...[
          const Divider(height: 32),
          _kopje(c, Icons.account_tree_outlined, _t(c, _lOnderliggend)),
          for (final k in kinderen)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_tekst(k['name'])),
              subtitle: _tekst(k['pas']).isEmpty ? null : Text(_tekst(k['pas']), style: const TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.chevron_right, color: Colors.black26),
              onTap: () => _openFederatie(_tekst(k['href']), _tekst(k['name'])),
            ),
        ],

        // ── Wateren ─────────────────────────────────────────────────────────────────────────
        // Waar mag je met deze pas vissen? Dat is de vraag waar een lid voor komt. Tikken op een
        // water opent het waterblad op de kaart, net als /kaart?w=<id> op het web.
        ..._waterenBlok(c, f),

        // ── Aangesloten verenigingen ────────────────────────────────────────────────────────
        ..._verenigingenBlok(c, f),

        // Bronvermelding + controledatum: hiermee kan het lid alles zelf natrekken.
        if (bronnen.isNotEmpty || gecontroleerd.isNotEmpty) ...[
          const Divider(height: 32),
          Text(_t(c, _lBronnen), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 4),
          for (final b in bronnen) _bron(b),
          if (gecontroleerd.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _t(c, _lGecontroleerd).replaceAll('{date}', _datum(gecontroleerd, taal)),
                style: const TextStyle(fontSize: 11, color: Colors.black38),
              ),
            ),
        ],
      ],
    );
  }

  Widget _kopje(BuildContext c, IconData icoon, String tekst) => Row(children: [
        Icon(icoon, size: 17, color: AppColors.teal),
        const SizedBox(width: 6),
        Text(tekst, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy)),
      ]);

  Widget _regel(Map r) {
    final titel = _tekst(r['title']);
    final tekst = _tekst(r['text']);
    if (titel.isEmpty && tekst.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (titel.isNotEmpty) Text(titel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        if (tekst.isNotEmpty) Text(tekst, style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.black87)),
      ]),
    );
  }

  Widget _prijs(Map p) {
    final label = _tekst(p['label']);
    final bedrag = _tekst(p['price']);
    if (label.isEmpty && bedrag.isEmpty) return const SizedBox.shrink();
    final bronUrl = _tekst(p['source_url']);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: Colors.black87))),
        if (bronUrl.isNotEmpty)
          InkWell(
            onTap: () => _openLink(bronUrl),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Icon(Icons.open_in_new, size: 13, color: AppColors.teal),
            ),
          ),
        // Muntteken vastplakken aan het bedrag, anders breekt "€ 40" over twee regels.
        Text(
          bedrag.replaceAllMapped(RegExp(r'(€|£|CHF|kr|Kč|zł) '), (m) => '${m[1]} '),
          textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.navy),
        ),
      ]),
    );
  }

  /// Een bron is een losse tekst of een {label, url}; beide komen voor in de gids.
  Widget _bron(dynamic b) {
    final label = b is Map ? _tekst(b['label']) : _tekst(b);
    final url = b is Map ? _tekst(b['url']) : '';
    if (label.isEmpty && url.isEmpty) return const SizedBox.shrink();
    final tekst = label.isNotEmpty ? label : url;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: InkWell(
        onTap: url.isEmpty ? null : () => _openLink(url),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('• ', style: TextStyle(fontSize: 11, color: Colors.black38)),
          Expanded(
            child: Text(
              tekst,
              style: TextStyle(fontSize: 11, color: url.isEmpty ? Colors.black45 : AppColors.teal),
            ),
          ),
          if (url.isNotEmpty) const Icon(Icons.open_in_new, size: 11, color: AppColors.teal),
        ]),
      ),
    );
  }

  /// Wateren van de organisatie zelf én van haar verenigingen, met dezelfde indeling als op het
  /// web: eerst de wateren van de organisatie, daarna per vereniging uitklapbaar.
  List<Widget> _waterenBlok(BuildContext c, Map f) {
    final eigen = _lijst(f['waters']);
    final perClub = _lijst(f['club_waters']);
    if (eigen.isEmpty && perClub.isEmpty) return const [];

    final zoek = _waterFilter.trim().toLowerCase();
    bool past(Map w, [String clubNaam = '']) => zoek.isEmpty ||
        _tekst(w['name']).toLowerCase().contains(zoek) ||
        clubNaam.toLowerCase().contains(zoek);

    final eigenLijst = eigen.where((w) => past(w as Map)).toList();
    final clubLijst = [
      for (final club in perClub)
        if (_lijst((club as Map)['waters']).where((w) => past(w as Map, _tekst(club['name']))).isNotEmpty)
          {...club, 'waters': _lijst(club['waters']).where((w) => past(w as Map, _tekst(club['name']))).toList()},
    ];
    final naam = _tekst(f['name']);
    final getoond = _alleEigenWateren ? eigenLijst : eigenLijst.take(25).toList();

    return [
      const Divider(height: 32),
      _kopje(c, Icons.water, gt(c, 'fw_title')),
      const SizedBox(height: 8),
      TextField(
        controller: _waterZoek,
        onChanged: (v) => setState(() => _waterFilter = v),
        decoration: InputDecoration(
          isDense: true,
          prefixIcon: const Icon(Icons.search, size: 18),
          hintText: gt(c, 'fw_search'),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      const SizedBox(height: 12),

      // Wateren van de organisatie zelf.
      Text('${gt(c, 'fw_org_title', {'org': naam})} (${eigenLijst.length})',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.navy)),
      Padding(padding: const EdgeInsets.only(top: 2, bottom: 4),
          child: Text(gt(c, 'fw_org_sub', {'org': naam}), style: const TextStyle(fontSize: 12.5, height: 1.35, color: Colors.black54))),
      if (eigenLijst.isEmpty)
        Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(gt(c, 'fw_none'), style: const TextStyle(fontSize: 13, color: Colors.black45)))
      else ...[
        for (final w in getoond) _waterRij(c, w as Map),
        if (!_alleEigenWateren && eigenLijst.length > 25)
          Align(alignment: Alignment.centerLeft, child: TextButton(
            onPressed: () => setState(() => _alleEigenWateren = true),
            child: Text(gt(c, 'club_waters', {'n': '${eigenLijst.length}'})),
          )),
      ],

      // Wateren per aangesloten vereniging.
      const SizedBox(height: 14),
      Text('${gt(c, 'fw_clubs_title')} (${clubLijst.length})',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.navy)),
      Padding(padding: const EdgeInsets.only(top: 2, bottom: 4),
          child: Text(gt(c, 'fw_clubs_sub'), style: const TextStyle(fontSize: 12.5, height: 1.35, color: Colors.black54))),
      if (clubLijst.isEmpty)
        Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(gt(c, 'fw_none'), style: const TextStyle(fontSize: 13, color: Colors.black45)))
      else
        for (final club in clubLijst) _clubMetWateren(c, club),
    ];
  }

  Widget _clubMetWateren(BuildContext c, Map club) {
    final href = _tekst(club['href']);
    final wateren = _lijst(club['waters']);
    final uit = _openVerenigingHref == href || _waterFilter.trim().isNotEmpty;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      InkWell(
        onTap: () => setState(() => _openVerenigingHref = uit && _waterFilter.trim().isEmpty ? null : href),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_tekst(club['name']), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
              if (_tekst(club['city']).isNotEmpty)
                Text(_tekst(club['city']), style: const TextStyle(fontSize: 11.5, color: Colors.black45)),
            ])),
            Text('${wateren.length}', style: const TextStyle(fontSize: 12, color: Colors.black45)),
            Icon(uit ? Icons.expand_less : Icons.expand_more, size: 20, color: Colors.black38),
          ]),
        ),
      ),
      if (uit) ...[
        for (final w in wateren) Padding(padding: const EdgeInsets.only(left: 10), child: _waterRij(c, w as Map)),
        if (href.isNotEmpty)
          Align(alignment: Alignment.centerLeft, child: TextButton(
            onPressed: () => _openVereniging(href, _tekst(club['name'])),
            style: TextButton.styleFrom(foregroundColor: AppColors.teal, padding: const EdgeInsets.symmetric(horizontal: 10)),
            child: Text(gt(c, 'fw_club_profile')),
          )),
      ],
      const Divider(height: 1),
    ]);
  }

  Widget _waterRij(BuildContext c, Map w) {
    final id = (w['id'] as num?)?.toInt();
    final soort = _tekst(w['permit_type']);
    return InkWell(
      onTap: id == null ? null : () => _openWater(id),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(children: [
          const Icon(Icons.place_outlined, size: 15, color: AppColors.teal),
          const SizedBox(width: 6),
          Expanded(child: Text(_tekst(w['name']), maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13.5, color: AppColors.navy))),
          if (w['marina'] == true) Padding(padding: const EdgeInsets.only(right: 6),
              child: Text('⛵ ${gt(c, 'wm_badge')}', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF0E7490)))),
          if (soort.isNotEmpty) Text(gt(c, 'pt_$soort'), style: const TextStyle(fontSize: 11, color: Colors.black38)),
          const Icon(Icons.chevron_right, size: 16, color: Colors.black26),
        ]),
      ),
    );
  }

  /// Alle aangesloten verenigingen, per provincie, met zoekveld — zoals het web ze toont.
  List<Widget> _verenigingenBlok(BuildContext c, Map f) {
    final alle = _lijst(f['clubs']);
    if (alle.isEmpty) return const [];
    final zoek = _clubFilter.trim().toLowerCase();
    final lijst = alle.where((v) =>
        zoek.isEmpty || '${(v as Map)['name']} ${v['city'] ?? ''}'.toLowerCase().contains(zoek)).toList();

    final groepen = <String, List>{};
    for (final v in lijst) {
      final p = _tekst((v as Map)['province']).isEmpty ? gt(c, 'prov_unknown') : _tekst(v['province']);
      groepen.putIfAbsent(p, () => []).add(v);
    }
    final provincies = groepen.keys.toList()
      ..sort((a, b) => a == gt(c, 'prov_unknown') ? 1 : b == gt(c, 'prov_unknown') ? -1 : a.compareTo(b));

    // Bij honderden verenigingen tonen we eerst de eerste provincies; anders bouwt het scherm
    // duizenden regels die niemand ziet.
    final tonen = _alleVerenigingen || zoek.isNotEmpty ? provincies : provincies.take(3).toList();

    return [
      const Divider(height: 32),
      _kopje(c, Icons.groups_outlined, '${gt(c, 'fed_clubs')} (${alle.length})'),
      const SizedBox(height: 8),
      TextField(
        controller: _clubZoek,
        onChanged: (v) => setState(() => _clubFilter = v),
        decoration: InputDecoration(
          isDense: true,
          prefixIcon: const Icon(Icons.search, size: 18),
          hintText: gt(c, 'search'),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      const SizedBox(height: 6),
      if (lijst.isEmpty)
        Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text(gt(c, 'dir_empty'), style: const TextStyle(fontSize: 13, color: Colors.black45))),
      for (final p in tonen) ...[
        Padding(padding: const EdgeInsets.fromLTRB(0, 12, 0, 2),
            child: Text('$p (${groepen[p]!.length})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54))),
        for (final v in groepen[p]!) _verenigingRij(c, v as Map),
      ],
      if (tonen.length < provincies.length)
        Align(alignment: Alignment.centerLeft, child: TextButton(
          onPressed: () => setState(() => _alleVerenigingen = true),
          child: Text(gt(c, 'org_count', {'n': '${lijst.length}'})),
        )),
    ];
  }

  Widget _verenigingRij(BuildContext c, Map v) {
    final n = (v['waters_count'] as num?)?.toInt() ?? 0;
    return InkWell(
      onTap: () => _openVereniging(_tekst(v['href']), _tekst(v['name'])),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_tekst(v['name']), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5)),
            if (_tekst(v['city']).isNotEmpty || n > 0)
              Text([
                if (_tekst(v['city']).isNotEmpty) _tekst(v['city']),
                if (n > 0) gt(c, 'club_waters', {'n': '$n'}),
              ].join(' · '), style: const TextStyle(fontSize: 11.5, color: Colors.black45)),
          ])),
          const Icon(Icons.chevron_right, size: 18, color: Colors.black26),
        ]),
      ),
    );
  }

  /// Een aangesloten vereniging openen (gidsvermelding of eigen profiel).
  void _openVereniging(String href, String naam) {
    if (href.isEmpty) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => OrganisatieScreen(href: href, naam: naam.isEmpty ? null : naam),
    ));
  }

  /// Een water openen op de kaart — precies zoals `/kaart?w=<id>` op het web.
  void _openWater(int id) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => MapScreen(focusWaterId: id)));
  }

  /// Onderliggende/bovenliggende organisatie openen; het pad uit de API is `/federatie/<slug>`.
  void _openFederatie(String href, String naam) {
    final slug = href.split('/').where((d) => d.isNotEmpty).lastOrNull ?? '';
    if (slug.isEmpty || slug == widget.slug) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FederatieScreen(slug: slug, naam: naam.isEmpty ? null : naam)),
    );
  }

  /// Officiële pagina openen in de app-browser; lukt dat niet, dan in de gewone browser.
  Future<void> _openLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) return;
    try {
      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    } catch (_) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }
  }
}

// ── Eigen labels in zes talen ────────────────────────────────────────────────────────────────
// Alleen ONZE teksten staan hier; de inhoud van de server (vergunningsnaam, regels, prijzen)
// vertalen we nooit zelf — die komt al vertaald mee in `translations` of is bewust in de
// oorspronkelijke taal (bv. "Fischereischein").

String _t(BuildContext c, Map<String, String> m) {
  final taal = c.read<I18n>().locale;
  return m[taal] ?? m['en'] ?? m['nl'] ?? '';
}

const _lSchermTitel = {'nl': 'Federatie', 'en': 'Federation', 'de': 'Verband', 'fr': 'Fédération', 'es': 'Federación', 'pl': 'Federacja'};
const _lPas = {'nl': 'Pas', 'en': 'Pass', 'de': 'Pass', 'fr': 'Carte', 'es': 'Pase', 'pl': 'Karta'};
const _lAantalVerenigingen = {'nl': '{n} verenigingen', 'en': '{n} clubs', 'de': '{n} Vereine', 'fr': '{n} associations', 'es': '{n} clubes', 'pl': '{n} kół'};
const _lRegels = {'nl': 'Regels die hier gelden', 'en': 'Rules that apply here', 'de': 'Regeln, die hier gelten', 'fr': 'Règles applicables ici', 'es': 'Normas que se aplican aquí', 'pl': 'Zasady, które tu obowiązują'};
const _lRegelsExtra = {
  'nl': 'Verenigingsregels komen bovenop de algemene regels en kunnen strenger zijn.',
  'en': 'Club rules come on top of the general rules and can be stricter.',
  'de': 'Vereinsregeln gelten zusätzlich zu den allgemeinen Regeln und können strenger sein.',
  'fr': 'Les règles de l’association s’ajoutent aux règles générales et peuvent être plus strictes.',
  'es': 'Las normas del club se suman a las normas generales y pueden ser más estrictas.',
  'pl': 'Zasady koła obowiązują dodatkowo do zasad ogólnych i mogą być surowsze.',
};
const _lOokVan = {
  'nl': 'Geldt ook: regels van {org}',
  'en': 'Also applies: rules of {org}',
  'de': 'Gilt auch: Regeln von {org}',
  'fr': 'S’applique aussi : règles de {org}',
  'es': 'También se aplica: normas de {org}',
  'pl': 'Obowiązują też: zasady {org}',
};
const _lPrijzen = {'nl': 'Pas en prijzen', 'en': 'Pass and prices', 'de': 'Pass und Preise', 'fr': 'Carte et prix', 'es': 'Pase y precios', 'pl': 'Karta i ceny'};
const _lOfficieleSite = {'nl': 'Officiële site', 'en': 'Official website', 'de': 'Offizielle Website', 'fr': 'Site officiel', 'es': 'Web oficial', 'pl': 'Oficjalna strona'};
const _lMeerInfo = {
  'nl': 'Meer info en actuele regels vind je op de officiële site.',
  'en': 'More info and current rules on the official website.',
  'de': 'Mehr Infos und aktuelle Regeln auf der offiziellen Website.',
  'fr': 'Plus d’infos et règles actuelles sur le site officiel.',
  'es': 'Más información y normas actuales en la web oficial.',
  'pl': 'Więcej informacji i aktualne zasady na oficjalnej stronie.',
};
const _lOnderliggend = {'nl': 'Onderliggende organisaties', 'en': 'Sub-organisations', 'de': 'Untergeordnete Organisationen', 'fr': 'Organisations rattachées', 'es': 'Organizaciones dependientes', 'pl': 'Organizacje podrzędne'};
const _lBronnen = {'nl': 'Bronnen', 'en': 'Sources', 'de': 'Quellen', 'fr': 'Sources', 'es': 'Fuentes', 'pl': 'Źródła'};
const _lGecontroleerd = {'nl': 'Gecontroleerd op {date}', 'en': 'Checked on {date}', 'de': 'Geprüft am {date}', 'fr': 'Vérifié le {date}', 'es': 'Comprobado el {date}', 'pl': 'Sprawdzono {date}'};
const _lGeenGarantieTitel = {
  'nl': 'Beheerd door YessFish — geen garantie',
  'en': 'Managed by YessFish — no guarantee',
  'de': 'Von YessFish gepflegt — ohne Gewähr',
  'fr': 'Géré par YessFish — sans garantie',
  'es': 'Gestionado por YessFish — sin garantía',
  'pl': 'Zarządzane przez YessFish — bez gwarancji',
};
const _lGeenGarantie = {
  'nl': 'Deze pagina wordt (nog) niet door de organisatie zelf bijgehouden. YessFish heeft de gegevens zorgvuldig verzameld uit openbare bronnen, maar we kunnen niet garanderen dat alles klopt of actueel is. Controleer regels en prijzen altijd bij de organisatie zelf voordat je gaat vissen.',
  'en': 'This page is not (yet) maintained by the organisation itself. YessFish carefully collected the information from public sources, but we cannot guarantee that everything is correct or up to date. Always check rules and prices with the organisation before you go fishing.',
  'de': 'Diese Seite wird (noch) nicht von der Organisation selbst gepflegt. YessFish hat die Angaben sorgfältig aus öffentlichen Quellen gesammelt, kann aber nicht garantieren, dass alles stimmt oder aktuell ist. Prüfe Regeln und Preise immer bei der Organisation, bevor du angeln gehst.',
  'fr': 'Cette page n’est pas (encore) tenue à jour par l’organisation elle-même. YessFish a soigneusement rassemblé les informations à partir de sources publiques, mais nous ne pouvons pas garantir qu’elles sont exactes ou à jour. Vérifiez toujours les règles et les prix auprès de l’organisation avant d’aller pêcher.',
  'es': 'Esta página no la mantiene (todavía) la propia organización. YessFish ha reunido los datos con cuidado a partir de fuentes públicas, pero no podemos garantizar que todo sea correcto o esté actualizado. Comprueba siempre las normas y los precios con la organización antes de ir a pescar.',
  'pl': 'Ta strona nie jest (jeszcze) prowadzona przez samą organizację. YessFish starannie zebrał dane z publicznych źródeł, ale nie możemy zagwarantować, że wszystko jest poprawne i aktualne. Zawsze sprawdzaj zasady i ceny w organizacji, zanim pójdziesz na ryby.',
};
const _lNietGevonden = {
  'nl': 'Deze organisatie staat niet in de gids.',
  'en': 'This organisation is not in the directory.',
  'de': 'Diese Organisation steht nicht im Verzeichnis.',
  'fr': 'Cette organisation ne figure pas dans l’annuaire.',
  'es': 'Esta organización no está en la guía.',
  'pl': 'Tej organizacji nie ma w katalogu.',
};
const _lFout = {
  'nl': 'Er ging iets mis. Probeer het opnieuw.',
  'en': 'Something went wrong. Please try again.',
  'de': 'Etwas ist schiefgelaufen. Bitte versuche es erneut.',
  'fr': 'Une erreur est survenue. Réessayez.',
  'es': 'Algo ha salido mal. Inténtalo de nuevo.',
  'pl': 'Coś poszło nie tak. Spróbuj ponownie.',
};
const _lOpnieuw = {'nl': 'Opnieuw proberen', 'en': 'Try again', 'de': 'Erneut versuchen', 'fr': 'Réessayer', 'es': 'Reintentar', 'pl': 'Spróbuj ponownie'};

// ── Hulpjes ─────────────────────────────────────────────────────────────────────────────────

String _tekst(dynamic v) => v == null ? '' : v.toString().trim();

List _lijst(dynamic v) => v is List ? v : const [];

/// Inhoud van de server in de taal van het lid, precies zoals `trContent()` op het web:
/// Nederlands is de brontaal, andere talen staan onder `translations[taal]`. Lege of
/// ontbrekende vertalingen laten de Nederlandse tekst staan — nooit zelf vertalen.
Map _inhoudInTaal(Map bron, String taal, {Map<String, String> hernoem = const {}}) {
  if (taal == 'nl') return bron;
  final alle = bron['translations'];
  if (alle is! Map) return bron;
  final vertaald = alle[taal];
  if (vertaald is! Map) return bron;
  final uit = Map<String, dynamic>.from(bron);
  vertaald.forEach((sleutel, waarde) {
    if (waarde == null || waarde == '') return;
    final naam = hernoem['$sleutel'] ?? '$sleutel';
    final huidig = uit[naam];
    if (waarde is List && huidig is List) {
      // Lijsten (regels, prijzen, bronnen) lopen per positie gelijk; per veld overschrijven,
      // zodat een niet-vertaalde url of bedrag gewoon blijft staan.
      uit[naam] = List.generate(huidig.length, (i) {
        final oud = huidig[i];
        final nieuw = i < waarde.length ? waarde[i] : null;
        if (oud is Map && nieuw is Map) {
          final samen = Map<String, dynamic>.from(oud);
          nieuw.forEach((k, v) {
            if (v != null && v != '') samen['$k'] = v;
          });
          return samen;
        }
        if (oud is String && nieuw is String) return nieuw;
        return oud;
      });
    } else if (waarde is! List && waarde is! Map) {
      uit[naam] = waarde;
    }
  });
  return uit;
}

/// '2026-09-14' → 14-09-2026 (nl), 14/09/2026 (en/fr/es), 14.09.2026 (de/pl). Lukt het parsen
/// niet, dan tonen we de datum precies zoals de server hem gaf.
String _datum(String ruw, String taal) {
  final d = DateTime.tryParse(ruw);
  if (d == null) return ruw;
  const scheiding = {'nl': '-', 'de': '.', 'pl': '.', 'en': '/', 'fr': '/', 'es': '/'};
  final s = scheiding[taal] ?? '-';
  return '${d.day.toString().padLeft(2, '0')}$s${d.month.toString().padLeft(2, '0')}$s${d.year}';
}
