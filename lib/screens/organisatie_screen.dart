import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/api.dart';
import '../core/config.dart';
import '../core/i18n.dart';
import '../core/rondleiding.dart';
import 'federatie_screen.dart';
import 'map_screen.dart';

/// Organisatiescherm: een vereniging, winkel, jachthaven of betaalwater IN de app.
///
/// Dit is de app-kant van de gidspagina's op het web (ClubListingView, PartnerProfileView,
/// MarinaListingView) en vertelt bewust HETZELFDE verhaal: wie het is, welke pas je nodig hebt,
/// welke regels er gelden, welke wateren erbij horen en waar de gegevens vandaan komen.
/// De gids opende zo'n pagina eerst in de browser, maar die is sinds 19-09-2026 voor leden en
/// kwam buiten de app dus uit op een "dit is voor leden"-pagina.
///
/// Het gaat hier over vergunningen en regels. We tonen daarom uitsluitend wat de server
/// teruggeeft; ontbreekt een blok, dan laten we het weg in plaats van er "onbekend" van te maken.
/// Bron en controledatum blijven zichtbaar, zodat het lid alles zelf kan natrekken.
class OrganisatieScreen extends StatefulWidget {
  const OrganisatieScreen({super.key, required this.href, this.naam});

  /// De link zoals de gidslijst hem geeft, bv. '/verenigingen/d32-het-baarsje-blokzijl-blokzijl'.
  final String href;

  /// Al bekende naam, zodat de titelbalk tijdens het laden niet leeg is.
  final String? naam;

  @override
  State<OrganisatieScreen> createState() => _OrganisatieScreenState();
}

/// Waar we de gegevens ophalen en wat voor soort pagina het wordt.
class _Adres {
  const _Adres(this.pad, this.soort);
  final String pad;

  /// 'entry' (gids-vermelding), 'club' (lijst-vereniging), 'marina' of 'partner'.
  final String soort;
}

class _OrganisatieScreenState extends State<OrganisatieScreen> {
  Map? _gegevens;
  String _soort = '';
  bool _laden = true;
  bool _fout = false;
  bool _nietGevonden = false;
  bool _alleEigenWateren = false;
  bool _alleOrgWateren = false;

  @override
  void initState() {
    super.initState();
    _haalOp();
  }

  Future<void> _haalOp() async {
    setState(() {
      _laden = true;
      _fout = false;
      _nietGevonden = false;
    });
    var href = widget.href;
    try {
      // De server stuurt door zodra een vermelding is overgenomen of samengevoegd; die
      // doorverwijzing volgen we net als het web, met een grens tegen een kringetje.
      for (var stap = 0; stap < 4; stap++) {
        final ander = _anderScherm(href);
        if (ander != null) {
          if (!mounted) return;
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ander));
          return;
        }
        final adres = _adresVan(href);
        if (adres == null) {
          if (!mounted) return;
          setState(() {
            _nietGevonden = true;
            _laden = false;
          });
          return;
        }
        final r = await Api.get(adres.pad);
        final data = (r is Map && r['data'] is Map) ? r['data'] as Map : null;
        if (data == null) {
          if (!mounted) return;
          setState(() {
            _nietGevonden = true;
            _laden = false;
          });
          return;
        }
        final door = _tekst(data['redirect']);
        if (door.isNotEmpty) {
          href = door;
          continue;
        }
        if (!mounted) return;
        setState(() {
          _gegevens = data;
          _soort = adres.soort;
          _laden = false;
        });
        return;
      }
      if (!mounted) return;
      setState(() {
        _fout = true;
        _laden = false;
      });
    } on ApiException catch (e) {
      // 404 = staat niet in de gids; al het andere is een storing en mag niet als
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

  /// Links die een eigen scherm hebben: de federatiepagina en het waterblad op de kaart.
  /// Zo komt een betaalwater dat al op de kaart staat niet op een doodlopende pagina uit.
  Widget? _anderScherm(String href) {
    final uri = Uri.tryParse(href.trim());
    if (uri == null) return null;
    final delen = uri.pathSegments.where((d) => d.isNotEmpty).toList();
    if (delen.isEmpty) return null;
    if (delen.first == 'federatie' && delen.length > 1) {
      return FederatieScreen(slug: delen[1], naam: widget.naam);
    }
    if (delen.first == 'kaart') {
      final id = int.tryParse('${uri.queryParameters['w']}');
      if (id != null) return MapScreen(focusWaterId: id);
    }
    return null;
  }

  /// Het juiste endpoint bij een gidslink, precies zoals de webpagina kiest.
  _Adres? _adresVan(String href) {
    final uri = Uri.tryParse(href.trim());
    if (uri == null) return null;
    final delen = uri.pathSegments.where((d) => d.isNotEmpty).toList();
    if (delen.length < 2) return null;
    final soort = delen.first.toLowerCase();
    final sleutel = delen[1];
    switch (soort) {
      case 'verenigingen':
        // 'd32-...' is een gids-vermelding, '12-...' een vereniging uit de oude lijst.
        final gids = sleutel.startsWith('d');
        final nummer = _getal(gids ? sleutel.substring(1) : sleutel);
        if (nummer == null) return null;
        return gids ? _Adres('/directory/entry/$nummer', 'entry') : _Adres('/directory/clubs/$nummer', 'club');
      case 'jachthaven':
        // 'w123-...' is een jachthaven uit de kaartgegevens; alles anders is een eigen profiel.
        final nummer = _getal(sleutel.startsWith('w') ? sleutel.substring(1) : sleutel);
        if (nummer != null && (sleutel.startsWith('w') || sleutel == '$nummer')) {
          return _Adres('/directory/marina/$nummer', 'marina');
        }
        return _Adres('/partners/profile/${Uri.encodeComponent(sleutel)}', 'partner');
      case 'vereniging':
      case 'winkel':
      case 'betaalwater':
        return _Adres('/partners/profile/${Uri.encodeComponent(sleutel)}', 'partner');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    context.watch<I18n>(); // bij een taalwissel opnieuw opbouwen
    final taal = context.read<I18n>().locale;
    final bron = _gegevens;
    final titel = _tekst(bron?['name']).isNotEmpty
        ? _tekst(bron!['name'])
        : (widget.naam ?? _t(context, _lTitel));

    return Scaffold(
      appBar: AppBar(title: Text(titel)),
      body: _laden
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _haalOp,
              child: bron == null ? _melding(context) : _inhoud(context, bron, taal),
            ),
    );
  }

  /// Niets te tonen: staat niet in de gids, of een storing met een knop om het nog eens te proberen.
  Widget _melding(BuildContext c) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
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
          // Een organisatie die niet bestaat verschijnt ook niet na een tweede poging.
          if (_fout) ...[
            const SizedBox(height: 16),
            Center(child: FilledButton(onPressed: _haalOp, child: Text(_t(c, _lOpnieuw)))),
          ],
        ],
      );

  Widget _inhoud(BuildContext c, Map bron, String taal) {
    final naam = _tekst(bron['name']);
    final logo = _tekst(bron['logo']);
    final plaats = _tekst(bron['region']).isNotEmpty ? _tekst(bron['region']) : _tekst(bron['city']);
    final provincie = _tekst(bron['province']);
    final land = _tekst(bron['country']).toUpperCase();
    final omschrijving = _tekst(bron['description']);
    final organisatie = bron['organisation'] is Map
        ? _inhoudInTaal(bron['organisation'] as Map, taal, hernoem: const {'pass_name': 'pas', 'summary': 'uitleg'})
        : null;
    final opmerking = _opmerkingInTaal(bron, taal);
    final website = _tekst(bron['website']);
    final lidWorden = _tekst(bron['join_url']);
    final links = _lijst(bron['links']);
    final eigenRegels = _lijst(bron['rules']);
    final orgRegels = organisatie == null ? const [] : _lijst(organisatie['rules']);
    final wateren = _lijst(bron['waters']);
    final orgWateren = bron['org_waters'] is Map
        ? _inhoudInTaal(bron['org_waters'] as Map, taal, hernoem: const {'pass_name': 'pas'})
        : null;
    final orgWaterLijst = orgWateren == null ? const [] : _lijst(orgWateren['waters']);
    final gedeeld = _lijst(bron['shared_with']);
    final vissen = bron['fishing'] is Map ? bron['fishing'] as Map : null;
    final adres = _adresTekst(bron);
    final telefoon = _tekst(bron['phone']);
    final email = _tekst(bron['email']);
    final beheerder = _tekst(bron['operator']);
    final ligplaatsen = _tekst(bron['capacity']);
    final tijden = bron['opening_hours'];
    final tijdenTekst = tijden is String ? _tekst(tijden) : '';
    final tijdenPerDag = tijden is Map ? tijden : null;
    final tijdenNoot = _tekst(bron['opening_note']);
    final nuOpen = bron['open_now'];
    final bronNaam = _tekst(bron['source']);
    final bronUrl = _tekst(bron['source_url']);
    final gecontroleerd = organisatie == null ? '' : _tekst(organisatie['verified_at']);
    final lat = _getal6(bron['latitude']);
    final lng = _getal6(bron['longitude']);
    final eigenId = _id(bron['id']);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16) + EdgeInsets.only(bottom: 24 + MediaQuery.of(c).padding.bottom),
      children: [
        // ── Kop: wie is dit en waar zit het ──
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _merkteken(logo, _icoon(bron)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(naam, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: AppColors.navy)),
              const SizedBox(height: 4),
              Text(
                [_soortLabel(c, bron), [plaats, provincie, land].where((d) => d.isNotEmpty).join(' · ')]
                    .where((d) => d.isNotEmpty)
                    .join(' · '),
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ]),
          ),
        ]),

        if (omschrijving.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(omschrijving, style: const TextStyle(fontSize: 15, height: 1.45)),
        ],

        // ── Welke pas je nodig hebt: daar komt het lid voor, dus vooraan ──
        if (organisatie != null) ...[
          const SizedBox(height: 14),
          TourAnker(
            id: 'organisatie-pas',
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(14)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.badge_outlined, size: 16, color: AppColors.teal),
                  const SizedBox(width: 6),
                  Text(_t(c, _lOrganisatie), style: const TextStyle(fontSize: 11, color: Colors.black54)),
                ]),
                const SizedBox(height: 4),
                Text(_tekst(organisatie['name']),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy)),
                if (_tekst(organisatie['pas']).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      _t(c, _lPasGeeft).replaceAll('{pas}', _tekst(organisatie['pas'])),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                  ),
                if (_tekst(organisatie['uitleg']).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(_tekst(organisatie['uitleg']),
                        style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.black54)),
                  ),
                if (opmerking.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(opmerking, style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.black87)),
                  ),
                if (_tekst(organisatie['href']).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: InkWell(
                      onTap: () => _openHref(_tekst(organisatie['href']), _tekst(organisatie['name'])),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(_t(c, _lNaarOrganisatie),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.teal)),
                      ),
                    ),
                  ),
              ]),
            ),
          ),
        ] else if (opmerking.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(opmerking, style: const TextStyle(fontSize: 14, height: 1.4)),
        ],

        // ── Knoppen: vergunning/lid worden, website en de eigen links van de partner ──
        if (lidWorden.isNotEmpty || website.isNotEmpty || links.isNotEmpty || (lat != null && lng != null)) ...[
          const SizedBox(height: 14),
          Wrap(spacing: 8, runSpacing: 8, children: [
            if (lidWorden.isNotEmpty)
              FilledButton.icon(
                onPressed: () => _openLink(lidWorden),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: Text(_t(c, _lLidWorden)),
                style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
              ),
            for (final l in links)
              if (l is Map && _tekst(l['url']).isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () => _openLink(_tekst(l['url'])),
                  icon: const Icon(Icons.open_in_new, size: 15),
                  label: Text(
                    _tekst(l['label']).isNotEmpty ? _tekst(l['label']) : _t(c, _lWebsite),
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.navy),
                ),
            if (website.isNotEmpty)
              OutlinedButton.icon(
                onPressed: () => _openLink(website),
                icon: const Icon(Icons.public, size: 15),
                label: Text(_kaleUrl(website), overflow: TextOverflow.ellipsis),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.navy),
              ),
            if (lat != null && lng != null)
              OutlinedButton.icon(
                onPressed: () => _openKaart(lat: lat, lng: lng, waterId: _soort == 'marina' ? eigenId : null),
                icon: const Icon(Icons.map_outlined, size: 15),
                label: Text(_t(c, _lOpDeKaart)),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.navy),
              ),
          ]),
        ],

        // ── Contact ──
        if (adres.isNotEmpty || telefoon.isNotEmpty || email.isNotEmpty || beheerder.isNotEmpty || ligplaatsen.isNotEmpty) ...[
          const Divider(height: 32),
          _kopje(c, Icons.place_outlined, _t(c, _lContact)),
          const SizedBox(height: 6),
          if (adres.isNotEmpty) _gegeven(Icons.place_outlined, adres),
          if (beheerder.isNotEmpty) _gegeven(Icons.info_outline, '${_t(c, _lBeheerder)}: $beheerder'),
          if (ligplaatsen.isNotEmpty)
            _gegeven(Icons.sailing_outlined, _t(c, _lLigplaatsen).replaceAll('{n}', ligplaatsen)),
          if (telefoon.isNotEmpty)
            _gegeven(Icons.phone_outlined, telefoon, onTap: () => _openUri(Uri.parse('tel:${telefoon.replaceAll(' ', '')}'))),
          if (email.isNotEmpty)
            _gegeven(Icons.mail_outline, email, onTap: () => _openUri(Uri.parse('mailto:$email'))),
        ],

        // ── Openingstijden ──
        if (tijdenPerDag != null || tijdenTekst.isNotEmpty) ...[
          const Divider(height: 32),
          Row(children: [
            Expanded(child: _kopje(c, Icons.schedule, _t(c, _lOpeningstijden))),
            if (nuOpen is bool)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: nuOpen ? const Color(0xFFD1FAE5) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _t(c, nuOpen ? _lNuOpen : _lNuGesloten),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: nuOpen ? const Color(0xFF047857) : Colors.black54,
                  ),
                ),
              ),
          ]),
          const SizedBox(height: 6),
          if (tijdenPerDag != null) _tijdenTabel(c, tijdenPerDag),
          if (tijdenTekst.isNotEmpty) Text(tijdenTekst, style: const TextStyle(fontSize: 13)),
          if (tijdenNoot.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(tijdenNoot, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ),
        ],

        // ── Regels: alleen wat de server geeft. Geen regel erbij verzinnen. ──
        if (orgRegels.isNotEmpty || eigenRegels.isNotEmpty) ...[
          const Divider(height: 32),
          _kopje(c, Icons.rule, _t(c, _lRegels)),
          const SizedBox(height: 8),
          if (orgRegels.isNotEmpty) ...[
            Text(
              _t(c, _lRegelsVan).replaceAll('{org}', _tekst(organisatie?['name'])),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 6),
            for (final r in orgRegels) _regel(r),
          ],
          if (eigenRegels.isNotEmpty) ...[
            if (orgRegels.isNotEmpty) const SizedBox(height: 10),
            Text(_t(c, _lEigenRegels),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
            const SizedBox(height: 6),
            for (final r in eigenRegels) _regel(r),
          ],
          const SizedBox(height: 8),
          Text(_t(c, _lRegelsExtra), style: const TextStyle(fontSize: 11, color: Colors.black38)),
        ],

        // ── Wateren van de organisatie zelf ──
        if (wateren.isNotEmpty) ...[
          const Divider(height: 32),
          _kopje(c, Icons.water, '${_t(c, _lWateren)} (${wateren.length})'),
          const SizedBox(height: 4),
          for (final w in (_alleEigenWateren ? wateren : wateren.take(25)))
            if (w is Map) _waterRij(c, w),
          if (!_alleEigenWateren && wateren.length > 25)
            TextButton(
              onPressed: () => setState(() => _alleEigenWateren = true),
              child: Text(_t(c, _lToonAlles).replaceAll('{n}', '${wateren.length}')),
            ),
        ],

        // ── Wateren van de koepelorganisatie in de buurt (hoofdsysteem, bv. VISpas-wateren) ──
        if (orgWateren != null && orgWaterLijst.isNotEmpty) ...[
          const Divider(height: 32),
          _kopje(c, Icons.account_balance_outlined,
              '${_tekst(orgWateren['name'])} (${orgWaterLijst.length})'),
          if (_tekst(orgWateren['pas']).isNotEmpty || _getal6(orgWateren['radius_km']) != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _t(c, _lOrgWateren)
                    .replaceAll('{pas}', _tekst(orgWateren['pas']))
                    .replaceAll('{km}', '${orgWateren['radius_km'] ?? ''}'),
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
          const SizedBox(height: 4),
          for (final w in (_alleOrgWateren ? orgWaterLijst : orgWaterLijst.take(25)))
            if (w is Map) _waterRij(c, w, afstand: true),
          if (!_alleOrgWateren && orgWaterLijst.length > 25)
            TextButton(
              onPressed: () => setState(() => _alleOrgWateren = true),
              child: Text(_t(c, _lToonAlles).replaceAll('{n}', '${orgWaterLijst.length}')),
            ),
        ],

        // ── Jachthaven die óók viswater is: wie heeft hier het visrecht ──
        if (vissen != null && _lijst(vissen['by']).isNotEmpty) ...[
          const Divider(height: 32),
          _kopje(c, Icons.phishing, _t(c, _lOokViswater)),
          const SizedBox(height: 6),
          for (final b in _lijst(vissen['by']))
            if (b is Map)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(_tekst(b['name']), style: const TextStyle(fontSize: 14)),
                subtitle: _tekst(b['source']).isEmpty
                    ? null
                    : Text('${_t(c, _lBronnen)}: ${_tekst(b['source'])}',
                        style: const TextStyle(fontSize: 11, color: Colors.black45)),
                trailing: _tekst(b['href']).isEmpty ? null : const Icon(Icons.chevron_right, color: Colors.black26),
                onTap: _tekst(b['href']).isEmpty ? null : () => _openHref(_tekst(b['href']), _tekst(b['name'])),
              ),
        ],

        // ── Wateren die met anderen gedeeld worden ──
        if (gedeeld.isNotEmpty) ...[
          const Divider(height: 32),
          _kopje(c, Icons.handshake_outlined, _t(c, _lSamen)),
          const SizedBox(height: 4),
          for (final s in gedeeld)
            if (s is Map)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(_tekst(s['name']), style: const TextStyle(fontSize: 14)),
                subtitle: s['count'] == null
                    ? null
                    : Text(_t(c, _lSamenAantal).replaceAll('{n}', '${s['count']}'),
                        style: const TextStyle(fontSize: 11, color: Colors.black45)),
                trailing: const Icon(Icons.chevron_right, color: Colors.black26),
                onTap: () => _openHref(_tekst(s['href']), _tekst(s['name'])),
              ),
        ],

        // ── Bron en controledatum: hiermee kan het lid alles zelf nakijken ──
        if (bronNaam.isNotEmpty || bronUrl.isNotEmpty || gecontroleerd.isNotEmpty) ...[
          const Divider(height: 32),
          Text(_t(c, _lBronnen), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 4),
          if (bronNaam.isNotEmpty || bronUrl.isNotEmpty)
            InkWell(
              onTap: bronUrl.isEmpty ? null : () => _openLink(bronUrl),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('• ', style: TextStyle(fontSize: 11, color: Colors.black38)),
                  Expanded(
                    child: Text(
                      bronNaam.isNotEmpty ? bronNaam : _kaleUrl(bronUrl),
                      style: TextStyle(fontSize: 11, color: bronUrl.isEmpty ? Colors.black45 : AppColors.teal),
                    ),
                  ),
                  if (bronUrl.isNotEmpty) const Icon(Icons.open_in_new, size: 11, color: AppColors.teal),
                ]),
              ),
            ),
          if (gecontroleerd.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                _t(c, _lGecontroleerd).replaceAll('{date}', _datum(gecontroleerd, taal)),
                style: const TextStyle(fontSize: 11, color: Colors.black38),
              ),
            ),
        ],

        // ── Beheerd door YessFish = uit openbare bronnen verzameld, dus zonder garantie ──
        if (bron['managed_by'] == 'yessfish') ...[
          const SizedBox(height: 18),
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

        if (bron['claim_pending'] == true) ...[
          const SizedBox(height: 10),
          Text(_t(c, _lClaimLoopt), style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      ],
    );
  }

  // ── Onderdelen ────────────────────────────────────────────────────────────────────────────

  Widget _kopje(BuildContext c, IconData icoon, String tekst) => Row(children: [
        Icon(icoon, size: 17, color: AppColors.teal),
        const SizedBox(width: 6),
        Expanded(child: Text(tekst, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy))),
      ]);

  /// Logo van de partner, of het icoon dat bij dit soort pagina hoort.
  Widget _merkteken(String logo, IconData icoon) {
    final vlak = Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(16)),
      child: Icon(icoon, size: 26, color: AppColors.navy),
    );
    if (logo.isEmpty) return vlak;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        logo,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => vlak,
      ),
    );
  }

  Widget _gegeven(IconData icoon, String tekst, {VoidCallback? onTap}) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icoon, size: 15, color: Colors.black38),
            const SizedBox(width: 8),
            Expanded(
              child: Text(tekst,
                  style: TextStyle(fontSize: 13.5, color: onTap == null ? Colors.black87 : AppColors.teal)),
            ),
          ]),
        ),
      );

  /// Een regel is {title, text} (organisatie) of een losse zin (eigen regels van de partner).
  Widget _regel(dynamic r) {
    final titel = r is Map ? _tekst(r['title']) : '';
    final tekst = r is Map ? _tekst(r['text']) : _tekst(r);
    if (titel.isEmpty && tekst.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (titel.isNotEmpty) Text(titel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        if (tekst.isNotEmpty) Text(tekst, style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.black87)),
      ]),
    );
  }

  Widget _waterRij(BuildContext c, Map w, {bool afstand = false}) {
    final naam = _tekst(w['name']);
    if (naam.isEmpty) return const SizedBox.shrink();
    final id = _id(w['id']);
    final vergunning = _vergunning(c, _tekst(w['permit_type']));
    final km = w['distance_km'];
    return InkWell(
      onTap: id == null ? null : () => _openKaart(waterId: id),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
        child: Row(children: [
          Expanded(child: Text(naam, style: const TextStyle(fontSize: 13.5), overflow: TextOverflow.ellipsis)),
          if (w['marina'] == true)
            const Padding(
              padding: EdgeInsets.only(left: 6),
              child: Icon(Icons.sailing_outlined, size: 14, color: Color(0xFF0E7490)),
            ),
          if (afstand && km is num)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text('$km km', style: const TextStyle(fontSize: 11, color: Colors.black38)),
            ),
          if (vergunning.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(vergunning, style: const TextStyle(fontSize: 11, color: Colors.black45)),
            ),
        ]),
      ),
    );
  }

  Widget _tijdenTabel(BuildContext c, Map tijden) => Column(
        children: [
          for (final dag in _dagen)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(children: [
                SizedBox(width: 92, child: Text(_t(c, _lDag[dag]!), style: const TextStyle(fontSize: 13, color: Colors.black54))),
                Expanded(
                  child: Text(
                    _tijdvakken(tijden[dag]).isEmpty ? _t(c, _lGesloten) : _tijdvakken(tijden[dag]),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 13,
                      color: _tijdvakken(tijden[dag]).isEmpty ? Colors.black38 : Colors.black87,
                    ),
                  ),
                ),
              ]),
            ),
        ],
      );

  // ── Navigeren en openen ───────────────────────────────────────────────────────────────────

  /// Een link uit de gids in de app openen: federatie, waterblad of een andere organisatie.
  void _openHref(String href, String naam) {
    if (href.isEmpty || href == widget.href) return;
    final ander = _anderScherm(href);
    if (ander != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ander));
      return;
    }
    if (_adresVan(href) == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OrganisatieScreen(href: href, naam: naam.isEmpty ? null : naam)),
    );
  }

  void _openKaart({double? lat, double? lng, int? waterId}) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MapScreen(focusLat: lat, focusLng: lng, focusWaterId: waterId)),
      );

  /// Officiële pagina in de app-browser; lukt dat niet, dan in de gewone browser.
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

  /// Bellen of mailen gaat naar de app die dat afhandelt, niet naar een browser.
  Future<void> _openUri(Uri uri) async {
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  // ── Kleine hulpjes die de gegevens uitlezen ───────────────────────────────────────────────

  String _adresTekst(Map bron) {
    final klaar = _tekst(bron['address']);
    if (klaar.isNotEmpty) return klaar;
    final straat = _tekst(bron['street']);
    final plaats = [_tekst(bron['postcode']), _tekst(bron['city'])].where((d) => d.isNotEmpty).join(' ');
    return [straat, plaats].where((d) => d.isNotEmpty).join(', ');
  }

  /// Opmerking bij een gids-vermelding; de server levert de vertalingen mee.
  String _opmerkingInTaal(Map bron, String taal) {
    final vertaald = bron['note_translations'];
    if (vertaald is Map && _tekst(vertaald[taal]).isNotEmpty) return _tekst(vertaald[taal]);
    return _tekst(bron['note']);
  }

  IconData _icoon(Map bron) {
    final type = _tekst(bron['type']);
    if (type == 'shop') return Icons.storefront_outlined;
    if (type == 'marina' || _soort == 'marina') return Icons.sailing_outlined;
    if (type == 'betaalwater') return Icons.water_outlined;
    final kind = _tekst(bron['kind']);
    if (kind == 'federation') return Icons.account_balance_outlined;
    if (kind == 'authority') return Icons.gavel_outlined;
    return Icons.groups_outlined;
  }

  String _soortLabel(BuildContext c, Map bron) {
    final type = _tekst(bron['type']);
    if (type.isNotEmpty && _lSoort[type] != null) return _t(c, _lSoort[type]!);
    if (_soort == 'marina') return _t(c, _lSoort['marina']!);
    final kind = _tekst(bron['kind']);
    return _t(c, _lSoort[kind] ?? _lSoort['club']!);
  }

  /// Korte omschrijving van het vergunningtype, met dezelfde woorden als op het web.
  String _vergunning(BuildContext c, String type) {
    final m = _lVergunning[type];
    return m == null ? '' : _t(c, m);
  }
}

// ── Eigen labels in zes talen ────────────────────────────────────────────────────────────────
// Alleen ONZE teksten staan hier. De inhoud van de server (naam van de pas, regels, eigennamen)
// vertalen we nooit zelf: die komt vertaald mee in `translations` of blijft bewust zoals hij is.

String _t(BuildContext c, Map<String, String> m) {
  final taal = c.read<I18n>().locale;
  return m[taal] ?? m['en'] ?? m['nl'] ?? '';
}

const _lTitel = {'nl': 'Gids', 'en': 'Directory', 'de': 'Verzeichnis', 'fr': 'Annuaire', 'es': 'Guía', 'pl': 'Katalog'};
const _lOrganisatie = {'nl': 'Organisatie', 'en': 'Organisation', 'de': 'Organisation', 'fr': 'Organisation', 'es': 'Organización', 'pl': 'Organizacja'};
const _lPasGeeft = {
  'nl': 'Lid worden geeft je de {pas}',
  'en': 'Becoming a member gives you the {pas}',
  'de': 'Eine Mitgliedschaft gibt dir den {pas}',
  'fr': 'Devenir membre vous donne la {pas}',
  'es': 'Hacerte socio te da el {pas}',
  'pl': 'Członkostwo daje ci {pas}',
};
const _lNaarOrganisatie = {
  'nl': 'Naar de organisatie →',
  'en': 'To the organisation →',
  'de': 'Zur Organisation →',
  'fr': 'Vers l’organisation →',
  'es': 'Ir a la organización →',
  'pl': 'Do organizacji →',
};
const _lLidWorden = {
  'nl': 'Vergunning / lid worden',
  'en': 'Permit / become a member',
  'de': 'Erlaubnis / Mitglied werden',
  'fr': 'Carte de pêche / adhésion',
  'es': 'Permiso / hazte socio',
  'pl': 'Zezwolenie / zostań członkiem',
};
const _lWebsite = {'nl': 'Website', 'en': 'Website', 'de': 'Website', 'fr': 'Site web', 'es': 'Sitio web', 'pl': 'Strona'};
const _lOpDeKaart = {'nl': 'Op de kaart', 'en': 'On the map', 'de': 'Auf der Karte', 'fr': 'Sur la carte', 'es': 'En el mapa', 'pl': 'Na mapie'};
const _lContact = {'nl': 'Contact', 'en': 'Contact', 'de': 'Kontakt', 'fr': 'Contact', 'es': 'Contacto', 'pl': 'Kontakt'};
const _lBeheerder = {'nl': 'Beheerder', 'en': 'Operator', 'de': 'Betreiber', 'fr': 'Gestionnaire', 'es': 'Gestor', 'pl': 'Operator'};
const _lLigplaatsen = {
  'nl': '{n} ligplaatsen',
  'en': '{n} berths',
  'de': '{n} Liegeplätze',
  'fr': '{n} places',
  'es': '{n} amarres',
  'pl': '{n} miejsc postojowych',
};
const _lOpeningstijden = {'nl': 'Openingstijden', 'en': 'Opening hours', 'de': 'Öffnungszeiten', 'fr': 'Horaires', 'es': 'Horario', 'pl': 'Godziny otwarcia'};
const _lNuOpen = {'nl': 'Nu open', 'en': 'Open now', 'de': 'Jetzt geöffnet', 'fr': 'Ouvert', 'es': 'Abierto ahora', 'pl': 'Teraz otwarte'};
const _lNuGesloten = {'nl': 'Nu gesloten', 'en': 'Closed now', 'de': 'Jetzt geschlossen', 'fr': 'Fermé', 'es': 'Cerrado ahora', 'pl': 'Teraz zamknięte'};
const _lGesloten = {'nl': 'Gesloten', 'en': 'Closed', 'de': 'Geschlossen', 'fr': 'Fermé', 'es': 'Cerrado', 'pl': 'Zamknięte'};
const _lDag = {
  'mon': {'nl': 'Maandag', 'en': 'Monday', 'de': 'Montag', 'fr': 'Lundi', 'es': 'Lunes', 'pl': 'Poniedziałek'},
  'tue': {'nl': 'Dinsdag', 'en': 'Tuesday', 'de': 'Dienstag', 'fr': 'Mardi', 'es': 'Martes', 'pl': 'Wtorek'},
  'wed': {'nl': 'Woensdag', 'en': 'Wednesday', 'de': 'Mittwoch', 'fr': 'Mercredi', 'es': 'Miércoles', 'pl': 'Środa'},
  'thu': {'nl': 'Donderdag', 'en': 'Thursday', 'de': 'Donnerstag', 'fr': 'Jeudi', 'es': 'Jueves', 'pl': 'Czwartek'},
  'fri': {'nl': 'Vrijdag', 'en': 'Friday', 'de': 'Freitag', 'fr': 'Vendredi', 'es': 'Viernes', 'pl': 'Piątek'},
  'sat': {'nl': 'Zaterdag', 'en': 'Saturday', 'de': 'Samstag', 'fr': 'Samedi', 'es': 'Sábado', 'pl': 'Sobota'},
  'sun': {'nl': 'Zondag', 'en': 'Sunday', 'de': 'Sonntag', 'fr': 'Dimanche', 'es': 'Domingo', 'pl': 'Niedziela'},
};
const _dagen = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
const _lRegels = {'nl': 'Regels die hier gelden', 'en': 'Rules that apply here', 'de': 'Regeln, die hier gelten', 'fr': 'Règles applicables ici', 'es': 'Normas que se aplican aquí', 'pl': 'Zasady, które tu obowiązują'};
const _lRegelsVan = {
  'nl': 'Regels van {org}',
  'en': 'Rules of {org}',
  'de': 'Regeln von {org}',
  'fr': 'Règles de {org}',
  'es': 'Normas de {org}',
  'pl': 'Zasady {org}',
};
const _lEigenRegels = {
  'nl': 'Eigen regels',
  'en': 'Own rules',
  'de': 'Eigene Regeln',
  'fr': 'Règles propres',
  'es': 'Normas propias',
  'pl': 'Własne zasady',
};
const _lRegelsExtra = {
  'nl': 'Verenigingsregels komen bovenop de algemene regels en kunnen strenger zijn.',
  'en': 'Club rules come on top of the general rules and can be stricter.',
  'de': 'Vereinsregeln gelten zusätzlich zu den allgemeinen Regeln und können strenger sein.',
  'fr': 'Les règles de l’association s’ajoutent aux règles générales et peuvent être plus strictes.',
  'es': 'Las normas del club se suman a las normas generales y pueden ser más estrictas.',
  'pl': 'Zasady koła obowiązują dodatkowo do zasad ogólnych i mogą być surowsze.',
};
const _lWateren = {'nl': 'Wateren', 'en': 'Waters', 'de': 'Gewässer', 'fr': 'Eaux', 'es': 'Aguas', 'pl': 'Wody'};
// De afstand achter elk water is de afstand tot DEZE vereniging, niet tot waar jij staat.
// Zonder dat erbij las het als "zo ver is het voor mij" en klopte het niet (Richard 23-09-2026).
const _lOrgWateren = {
  'nl': 'Hier mag je ook vissen met de {pas}. Binnen {km} km van deze vereniging; de afstand staat achter elk water.',
  'en': 'You may also fish here with the {pas}. Within {km} km of this club; the distance is shown after each water.',
  'de': 'Hier darfst du auch mit dem {pas} angeln. Im Umkreis von {km} km um diesen Verein; die Entfernung steht hinter jedem Gewässer.',
  'fr': 'Vous pouvez aussi pêcher ici avec la {pas}. Dans un rayon de {km} km autour de cette association ; la distance figure après chaque plan d’eau.',
  'es': 'Aquí también puedes pescar con el {pas}. A menos de {km} km de este club; la distancia aparece tras cada agua.',
  'pl': 'Tutaj też możesz łowić z {pas}. W promieniu {km} km od tego koła; odległość podana jest przy każdej wodzie.',
};
const _lToonAlles = {
  'nl': 'Alle {n} tonen',
  'en': 'Show all {n}',
  'de': 'Alle {n} anzeigen',
  'fr': 'Afficher les {n}',
  'es': 'Mostrar los {n}',
  'pl': 'Pokaż wszystkie ({n})',
};
const _lOokViswater = {
  'nl': 'Ook viswater',
  'en': 'Also fishing water',
  'de': 'Auch Angelgewässer',
  'fr': 'Aussi eau de pêche',
  'es': 'También agua de pesca',
  'pl': 'Także łowisko',
};
const _lSamen = {
  'nl': 'Wateren samen met',
  'en': 'Waters shared with',
  'de': 'Gewässer gemeinsam mit',
  'fr': 'Eaux partagées avec',
  'es': 'Aguas compartidas con',
  'pl': 'Wody wspólne z',
};
const _lSamenAantal = {
  'nl': '{n} gezamenlijke wateren',
  'en': '{n} shared waters',
  'de': '{n} gemeinsame Gewässer',
  'fr': '{n} eaux en commun',
  'es': '{n} aguas compartidas',
  'pl': '{n} wspólnych wód',
};
const _lBronnen = {'nl': 'Bron', 'en': 'Source', 'de': 'Quelle', 'fr': 'Source', 'es': 'Fuente', 'pl': 'Źródło'};
const _lGecontroleerd = {'nl': 'Gecontroleerd op {date}', 'en': 'Checked on {date}', 'de': 'Geprüft am {date}', 'fr': 'Vérifié le {date}', 'es': 'Comprobado el {date}', 'pl': 'Sprawdzono {date}'};
const _lClaimLoopt = {
  'nl': 'Er loopt een aanvraag om deze pagina zelf te beheren.',
  'en': 'A request to manage this page is being reviewed.',
  'de': 'Ein Antrag zur eigenen Verwaltung dieser Seite läuft.',
  'fr': 'Une demande de gestion de cette page est en cours.',
  'es': 'Hay una solicitud en curso para gestionar esta página.',
  'pl': 'Trwa wniosek o samodzielne prowadzenie tej strony.',
};
const _lSoort = {
  'club': {'nl': 'Vereniging', 'en': 'Club', 'de': 'Verein', 'fr': 'Association', 'es': 'Club', 'pl': 'Koło'},
  'shop': {'nl': 'Hengelsportwinkel', 'en': 'Tackle shop', 'de': 'Angelladen', 'fr': 'Magasin de pêche', 'es': 'Tienda de pesca', 'pl': 'Sklep wędkarski'},
  'marina': {'nl': 'Jachthaven', 'en': 'Marina', 'de': 'Yachthafen', 'fr': 'Port de plaisance', 'es': 'Puerto deportivo', 'pl': 'Przystań'},
  'betaalwater': {'nl': 'Betaalwater', 'en': 'Paid water', 'de': 'Bezahlgewässer', 'fr': 'Plan d’eau payant', 'es': 'Agua de pago', 'pl': 'Łowisko płatne'},
  'federation': {'nl': 'Koepelorganisatie', 'en': 'Federation', 'de': 'Verband', 'fr': 'Fédération', 'es': 'Federación', 'pl': 'Federacja'},
  'authority': {'nl': 'Vergunning-instantie', 'en': 'Permit authority', 'de': 'Erlaubnisbehörde', 'fr': 'Autorité de délivrance', 'es': 'Autoridad de permisos', 'pl': 'Organ wydający zezwolenia'},
};
const _lVergunning = {
  'club': {'nl': 'Verenigingsvergunning', 'en': 'Club permit', 'de': 'Vereinserlaubnis', 'fr': 'Carte de l’association', 'es': 'Permiso del club', 'pl': 'Zezwolenie koła'},
  'landelijk': {'nl': 'VISpas (landelijk)', 'en': 'VISpas (national)', 'de': 'VISpas (landesweit)', 'fr': 'VISpas (national)', 'es': 'VISpas (nacional)', 'pl': 'VISpas (krajowe)'},
  'betaald': {'nl': 'Betaald water / dagkaart', 'en': 'Paid water / day ticket', 'de': 'Bezahlgewässer / Tageskarte', 'fr': 'Plan d’eau payant / carte journalière', 'es': 'Agua de pago / pase diario', 'pl': 'Łowisko płatne / karta dzienna'},
  'vrij': {'nl': 'Vrij vissen', 'en': 'Free fishing', 'de': 'Frei angeln', 'fr': 'Pêche libre', 'es': 'Pesca libre', 'pl': 'Wędkowanie wolne'},
  'verboden': {'nl': 'Vissen verboden', 'en': 'Fishing prohibited', 'de': 'Angeln verboten', 'fr': 'Pêche interdite', 'es': 'Pesca prohibida', 'pl': 'Wędkowanie zabronione'},
  'onduidelijk': {'nl': 'Onduidelijk', 'en': 'Unclear', 'de': 'Unklar', 'fr': 'Pas clair', 'es': 'No está claro', 'pl': 'Niejasne'},
};
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
  'nl': 'Dit staat niet in de gids.',
  'en': 'This is not in the directory.',
  'de': 'Das steht nicht im Verzeichnis.',
  'fr': 'Cela ne figure pas dans l’annuaire.',
  'es': 'Esto no está en la guía.',
  'pl': 'Tego nie ma w katalogu.',
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

int? _id(dynamic v) => v is num ? v.toInt() : int.tryParse('$v');

double? _getal6(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v');

/// Het eerste getal vooraan een sleutel: 'd32-het-baarsje' → 32.
int? _getal(String s) {
  final m = RegExp(r'^\d+').firstMatch(s);
  return m == null ? null : int.tryParse(m.group(0)!);
}

/// '09:00'–'17:00', meerdere tijdvakken achter elkaar. Lege dag = lege tekst.
String _tijdvakken(dynamic dag) {
  if (dag is! List) return '';
  final delen = <String>[];
  for (final vak in dag) {
    if (vak is List && vak.length == 2) delen.add('${_tekst(vak[0])}–${_tekst(vak[1])}');
  }
  return delen.join(', ');
}

/// 'https://www.vereniging.nl/leden' → 'vereniging.nl'
String _kaleUrl(String url) {
  final uri = Uri.tryParse(url);
  final host = uri?.host ?? '';
  if (host.isEmpty) return url;
  return host.startsWith('www.') ? host.substring(4) : host;
}

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
      // Lijsten (regels) lopen per positie gelijk; per veld overschrijven, zodat een
      // niet-vertaald onderdeel gewoon blijft staan.
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
