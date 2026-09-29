import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api.dart';
import '../core/config.dart';
import '../core/i18n.dart';
import '../core/location.dart' as loc;
import '../screens/map_screen.dart';
import '../screens/organisatie_screen.dart';

/// "Wat geldt er bij mij?" (Richard 28-09-2026): één knop bovenaan de gids. Daarna meteen het water waar je
/// staat (of de wateren om je heen om uit te kiezen) met het vergunningslabel, en de vereniging en winkel in
/// de buurt. Een water aantikken opent het gewone waterblad op de kaart. Alle landen.
/// Zelfde opbouw en teksten als op het web (BijMij.tsx).
const Map<String, Map<String, String>> _t = {
  'knop': {'nl': 'Wat geldt er bij mij?', 'en': 'What applies where I am?', 'de': 'Was gilt hier bei mir?', 'fr': 'Qu’est-ce qui s’applique ici ?', 'es': '¿Qué vale donde estoy?', 'pl': 'Co obowiązuje tam, gdzie jestem?'},
  'knop_sub': {'nl': 'Het water waar je staat, welke vergunning je nodig hebt en de vereniging en winkel in de buurt.', 'en': 'The water where you are, which permit you need, and the club and shop nearby.', 'de': 'Das Gewässer, an dem du stehst, welche Erlaubnis du brauchst, und Verein und Laden in der Nähe.', 'fr': 'L’eau où vous êtes, le permis nécessaire, et l’association et le magasin à proximité.', 'es': 'El agua donde estás, qué permiso necesitas y el club y la tienda cercanos.', 'pl': 'Łowisko, przy którym jesteś, jakie zezwolenie jest potrzebne, oraz klub i sklep w pobliżu.'},
  'zoekt': {'nl': 'Je locatie bepalen…', 'en': 'Finding your location…', 'de': 'Standort wird bestimmt…', 'fr': 'Localisation…', 'es': 'Buscando tu ubicación…', 'pl': 'Ustalanie lokalizacji…'},
  'geen_locatie': {'nl': 'Je locatie is niet beschikbaar. Zet locatie aan, of zoek het water op de kaart.', 'en': 'Your location is not available. Turn on location, or search the water on the map.', 'de': 'Dein Standort ist nicht verfügbar. Schalte den Standort ein oder suche das Gewässer auf der Karte.', 'fr': 'Votre position n’est pas disponible. Activez la localisation ou cherchez l’eau sur la carte.', 'es': 'Tu ubicación no está disponible. Activa la ubicación o busca el agua en el mapa.', 'pl': 'Lokalizacja niedostępna. Włącz lokalizację albo wyszukaj łowisko na mapie.'},
  'hier': {'nl': 'Je staat hier:', 'en': 'You are here:', 'de': 'Du bist hier:', 'fr': 'Vous êtes ici :', 'es': 'Estás aquí:', 'pl': 'Jesteś tutaj:'},
  'hier_kort': {'nl': 'je staat hier', 'en': 'you are here', 'de': 'du bist hier', 'fr': 'vous êtes ici', 'es': 'estás aquí', 'pl': 'jesteś tutaj'},
  'kies': {'nl': 'Welk water bedoel je?', 'en': 'Which water do you mean?', 'de': 'Welches Gewässer meinst du?', 'fr': 'De quelle eau s’agit-il ?', 'es': '¿Qué agua quieres decir?', 'pl': 'Które łowisko masz na myśli?'},
  'regels': {'nl': 'Regels en vergunning', 'en': 'Rules and permit', 'de': 'Regeln und Erlaubnis', 'fr': 'Règles et permis', 'es': 'Normas y permiso', 'pl': 'Zasady i zezwolenie'},
  'geen_water': {'nl': 'Geen water in jouw buurt', 'en': 'No water near you', 'de': 'Kein Gewässer in deiner Nähe', 'fr': 'Aucune eau près de vous', 'es': 'No hay agua cerca de ti', 'pl': 'Brak łowiska w pobliżu'},
  'verder': {'nl': 'Dichtstbijzijnde water:', 'en': 'Nearest water:', 'de': 'Nächstes Gewässer:', 'fr': 'Eau la plus proche :', 'es': 'Agua más cercana:', 'pl': 'Najbliższe łowisko:'},
  'zoek': {'nl': 'Zoek een water op de kaart', 'en': 'Search a water on the map', 'de': 'Gewässer auf der Karte suchen', 'fr': 'Chercher une eau sur la carte', 'es': 'Buscar un agua en el mapa', 'pl': 'Szukaj łowiska na mapie'},
  'vereniging': {'nl': 'Vereniging in de buurt', 'en': 'Club nearby', 'de': 'Verein in der Nähe', 'fr': 'Association à proximité', 'es': 'Club cercano', 'pl': 'Klub w pobliżu'},
  'winkel': {'nl': 'Winkel in de buurt', 'en': 'Shop nearby', 'de': 'Laden in der Nähe', 'fr': 'Magasin à proximité', 'es': 'Tienda cercana', 'pl': 'Sklep w pobliżu'},
  'open': {'nl': 'nu open', 'en': 'open now', 'de': 'jetzt geöffnet', 'fr': 'ouvert', 'es': 'abierto', 'pl': 'otwarte'},
  'opnieuw': {'nl': 'Opnieuw zoeken', 'en': 'Search again', 'de': 'Erneut suchen', 'fr': 'Rechercher à nouveau', 'es': 'Buscar de nuevo', 'pl': 'Szukaj ponownie'},
  'landelijk': {'nl': 'VISpas geldig', 'en': 'VISpas valid', 'de': 'VISpas gültig', 'fr': 'VISpas valable', 'es': 'VISpas válido', 'pl': 'VISpas ważny'},
  'club': {'nl': 'Clubwater', 'en': 'Club water', 'de': 'Vereinsgewässer', 'fr': 'Eau de club', 'es': 'Agua de club', 'pl': 'Woda klubowa'},
  'fiskfergunning': {'nl': 'Fiskfergunning', 'en': 'Fiskfergunning', 'de': 'Fiskfergunning', 'fr': 'Fiskfergunning', 'es': 'Fiskfergunning', 'pl': 'Fiskfergunning'},
  'nho': {'nl': 'NHO Viskaart', 'en': 'NHO permit card', 'de': 'NHO-Karte', 'fr': 'Carte NHO', 'es': 'Tarjeta NHO', 'pl': 'Karta NHO'},
  'betaald': {'nl': 'Betaald water', 'en': 'Paid water', 'de': 'Bezahlgewässer', 'fr': 'Eau payante', 'es': 'Agua de pago', 'pl': 'Łowisko płatne'},
  'verboden': {'nl': 'Vissen verboden', 'en': 'No fishing', 'de': 'Angeln verboten', 'fr': 'Pêche interdite', 'es': 'Pesca prohibida', 'pl': 'Zakaz wędkowania'},
  'onbekend': {'nl': 'Vergunning: controleer', 'en': 'Permit: check', 'de': 'Erlaubnis: prüfen', 'fr': 'Permis : à vérifier', 'es': 'Permiso: comprobar', 'pl': 'Zezwolenie: sprawdź'},
};

String _tr(BuildContext c, String k) {
  final l = Provider.of<I18n>(c, listen: false).locale;
  return _t[k]?[l] ?? _t[k]?['en'] ?? k;
}

/// De knop zelf, bovenaan de gidslijst.
class BijMijKnop extends StatelessWidget {
  const BijMijKnop({super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => showModalBottomSheet(
              context: context, isScrollControlled: true, showDragHandle: true, backgroundColor: Colors.white,
              builder: (_) => const _BijMijBlad(),
            ),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.teal.withValues(alpha: 0.35), width: 1.5)),
              child: Row(children: [
                const CircleAvatar(radius: 22, backgroundColor: AppColors.teal, child: Icon(Icons.my_location, color: Colors.white)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_tr(context, 'knop'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.navy)),
                  const SizedBox(height: 2),
                  Text(_tr(context, 'knop_sub'), style: const TextStyle(fontSize: 12, color: Colors.black54, height: 1.3)),
                ])),
                const Icon(Icons.chevron_right, color: Colors.black38),
              ]),
            ),
          ),
        ),
      );
}

class _BijMijBlad extends StatefulWidget {
  const _BijMijBlad();
  @override
  State<_BijMijBlad> createState() => _BijMijBladState();
}

class _BijMijBladState extends State<_BijMijBlad> {
  Map? _a;
  bool _zoekt = true;
  bool _geenLocatie = false;

  @override
  void initState() { super.initState(); _zoek(); }

  Future<void> _zoek() async {
    setState(() { _zoekt = true; _geenLocatie = false; _a = null; });
    try {
      final p = await loc.currentLocation();
      if (!p.isReal) { if (mounted) setState(() { _zoekt = false; _geenLocatie = true; }); return; }
      final r = await Api.get('/nearby?lat=${p.lat.toStringAsFixed(5)}&lng=${p.lng.toStringAsFixed(5)}');
      if (mounted) setState(() { _a = r is Map ? r : null; _zoekt = false; _geenLocatie = _a == null; });
    } catch (_) {
      if (mounted) setState(() { _zoekt = false; _geenLocatie = true; });
    }
  }

  String _afstand(num km) {
    final l = Provider.of<I18n>(context, listen: false).locale;
    if (km < 1) return '${((km * 1000) / 10).round() * 10} m';
    final s = km.toStringAsFixed(1);
    return '${l == 'en' ? s : s.replaceAll('.', ',')} km';
  }

  int? _id(dynamic v) => v is num ? v.toInt() : int.tryParse('$v');

  void _openWater(dynamic id) {
    final i = _id(id);
    if (i == null) return;
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => MapScreen(focusWaterId: i)));
  }

  void _openKaart() {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => const MapScreen()));
  }

  void _openPlek(Map p) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => OrganisatieScreen(href: '${p['href']}', naam: '${p['name']}')));
  }

  Widget _label(Map w) {
    final pt = (w['permit_type'] ?? '').toString();
    final k = (w['is_paid'] == true && pt.isEmpty) ? 'betaald' : pt;
    final pas = (w['pas'] ?? '').toString();
    Color rand, tekst, vlak;
    String woord;
    if (k.isEmpty && pas.isNotEmpty) {
      rand = const Color(0xFF7DD3FC); tekst = const Color(0xFF075985); vlak = const Color(0xFFF0F9FF); woord = pas;
    } else {
      // regio = de pas van het land/de regio (buiten NL): toon die pasnaam, groen.
      woord = (k == 'regio' && pas.isNotEmpty) ? pas : _tr(context, k.isEmpty ? 'onbekend' : k);
      if (k == 'landelijk' || k == 'regio') { rand = const Color(0xFF6EE7B7); tekst = const Color(0xFF047857); vlak = const Color(0xFFECFDF5); }
      else if (k == 'verboden') { rand = const Color(0xFFFCA5A5); tekst = const Color(0xFFB91C1C); vlak = const Color(0xFFFEF2F2); }
      else if (['club', 'fiskfergunning', 'nho', 'betaald'].contains(k)) { rand = const Color(0xFFFDBA74); tekst = const Color(0xFFC2410C); vlak = const Color(0xFFFFF7ED); }
      else { rand = const Color(0xFFCBD5E1); tekst = const Color(0xFF475569); vlak = const Color(0xFFF1F5F9); }
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: vlak, border: Border.all(color: rand), borderRadius: BorderRadius.circular(20)),
      child: Text(woord, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: tekst)),
    );
  }

  Widget _kop(String k, IconData i) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 4),
        child: Row(children: [
          Icon(i, size: 15, color: Colors.black45), const SizedBox(width: 6),
          Text(_tr(context, k).toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black45, letterSpacing: 0.5)),
        ]),
      );

  Widget _zoekLink() => TextButton.icon(
        onPressed: _openKaart, icon: const Icon(Icons.search, size: 18),
        label: Text(_tr(context, 'zoek')), style: TextButton.styleFrom(foregroundColor: AppColors.teal, padding: EdgeInsets.zero),
      );

  @override
  Widget build(BuildContext context) {
    final a = _a;
    final wateren = (a?['wateren'] is List) ? List<Map>.from(a!['wateren']) : <Map>[];
    final direct = a?['open_direct'] == null ? null : wateren.where((w) => _id(w['id']) == _id(a!['open_direct'])).firstOrNull;
    final ver = (a?['verenigingen'] is List) ? List<Map>.from(a!['verenigingen']) : <Map>[];
    final win = (a?['winkels'] is List) ? List<Map>.from(a!['winkels']) : <Map>[];
    final verder = a?['verder'] is Map ? a!['verder'] as Map : null;

    return DraggableScrollableSheet(
      expand: false, initialChildSize: 0.75, minChildSize: 0.4, maxChildSize: 0.95,
      builder: (_, sc) => ListView(controller: sc, padding: EdgeInsets.fromLTRB(16, 0, 16, 24 + MediaQuery.of(context).padding.bottom + 16), children: [
        Row(children: [
          const Icon(Icons.my_location, color: AppColors.teal, size: 20), const SizedBox(width: 8),
          Expanded(child: Text(_tr(context, 'knop'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.navy))),
          if (!_zoekt) TextButton(onPressed: _zoek, child: Text(_tr(context, 'opnieuw'))),
        ]),
        const SizedBox(height: 8),
        if (_zoekt) Row(children: [
          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)), const SizedBox(width: 10),
          Text(_tr(context, 'zoekt'), style: const TextStyle(color: Colors.black54)),
        ]),
        if (_geenLocatie) ...[
          Text(_tr(context, 'geen_locatie'), style: const TextStyle(color: Colors.black87, height: 1.35)),
          _zoekLink(),
        ],
        if (a != null) ...[
          if (direct != null)
            InkWell(
              onTap: () => _openWater(direct['id']),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.teal.withValues(alpha: 0.06), border: Border.all(color: AppColors.teal, width: 2), borderRadius: BorderRadius.circular(12)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_tr(context, 'hier').toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black45, letterSpacing: 0.5)),
                  const SizedBox(height: 2),
                  Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                    Text('${direct['name']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.navy)),
                    _label(direct),
                  ]),
                  const SizedBox(height: 6),
                  Row(children: [
                    Text(_tr(context, 'regels'), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.teal)),
                    const Icon(Icons.chevron_right, size: 18, color: AppColors.teal),
                  ]),
                ]),
              ),
            )
          else if (wateren.isNotEmpty) ...[
            Text(_tr(context, 'kies'), style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black87)),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(12)),
              child: Column(children: [
                for (var i = 0; i < wateren.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  ListTile(
                    dense: true,
                    title: Text('${wateren[i]['name']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                    subtitle: Padding(padding: const EdgeInsets.only(top: 3), child: Wrap(spacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                      Text(wateren[i]['hier'] == true ? _tr(context, 'hier_kort') : _afstand(wateren[i]['km'] as num? ?? 0), style: const TextStyle(fontSize: 12, color: Colors.black54)),
                      _label(wateren[i]),
                    ])),
                    trailing: const Icon(Icons.chevron_right, color: Colors.black38),
                    onTap: () => _openWater(wateren[i]['id']),
                  ),
                ],
              ]),
            ),
          ] else Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_tr(context, 'geen_water'), style: const TextStyle(fontWeight: FontWeight.w700)),
              if (verder != null) InkWell(
                onTap: () => _openWater(verder['id']),
                child: Padding(padding: const EdgeInsets.only(top: 4), child: Text('${_tr(context, 'verder')} ${verder['name']} · ${_afstand(verder['km'] as num? ?? 0)}', style: const TextStyle(color: Colors.black87))),
              ),
              _zoekLink(),
            ]),
          ),
          if (ver.isNotEmpty) ...[_kop('vereniging', Icons.groups_outlined), for (final p in ver) _plekRij(p)],
          if (win.isNotEmpty) ...[_kop('winkel', Icons.storefront_outlined), for (final p in win) _plekRij(p)],
        ],
      ]),
    );
  }

  Widget _plekRij(Map p) => InkWell(
        onTap: () => _openPlek(p),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(children: [
            Expanded(child: Text.rich(TextSpan(children: [
              TextSpan(text: '${p['name']}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              TextSpan(text: '${(p['city'] ?? '') != '' ? ' · ${p['city']}' : ''}${p['open_now'] == true ? ' · ${_tr(context, 'open')}' : ''}',
                  style: const TextStyle(fontSize: 13, color: Colors.black54)),
            ]))),
            Text(_afstand(p['km'] as num? ?? 0), style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ]),
        ),
      );
}
