import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/api.dart';
import '../core/config.dart';
import '../core/i18n.dart';

/// Uitrusting bij een vangst — de app-kant van het gear-blok op de vangstpagina van de site.
///
/// De uitrustingskast zat al in de app, maar je kon hem aan geen enkele vangst hangen; dat kon
/// alleen op het web. Daardoor bleef "waarmee heb ik die vis gevangen?" onbeantwoord zodra je de
/// vangst op je telefoon invoerde (20-09-2026).
///
/// Wat hier kan: een complete set in één keer koppelen, een los item uit de catalogus zoeken, zelf
/// iets toevoegen als het er niet in staat, en loskoppelen. Precies zoals op het web.
class UitrustingBijVangst extends StatefulWidget {
  const UitrustingBijVangst({super.key, required this.vangstId, required this.vanMij});
  final int vangstId;
  final bool vanMij;

  @override
  State<UitrustingBijVangst> createState() => _UitrustingBijVangstState();
}

class _UitrustingBijVangstState extends State<UitrustingBijVangst> {
  List _gear = [];
  List _sets = [];
  bool _geladen = false;
  bool _bezig = false;

  @override
  void initState() {
    super.initState();
    _laad();
  }

  Future<void> _laad() async {
    try {
      final r = await Api.get('/catches/${widget.vangstId}/gear');
      if (mounted) setState(() { _gear = (r is Map ? r['gear'] : null) ?? []; _geladen = true; });
    } catch (_) {
      if (mounted) setState(() => _geladen = true);
    }
    if (!widget.vanMij) return;
    try {
      final r = await Api.get('/gear-sets');
      if (mounted) setState(() => _sets = (r is Map ? r['sets'] : null) ?? []);
    } catch (_) {}
  }

  Future<void> _koppelSet(int setId) async {
    setState(() => _bezig = true);
    try {
      await Api.post('/catches/${widget.vangstId}/gear-set/$setId');
      final r = await Api.get('/catches/${widget.vangstId}/gear');
      if (mounted) setState(() => _gear = (r is Map ? r['gear'] : null) ?? []);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _bezig = false);
    }
  }

  Future<void> _koppel(Map<String, dynamic> body) async {
    setState(() => _bezig = true);
    try {
      final r = await Api.post('/catches/${widget.vangstId}/gear', body);
      if (mounted) setState(() => _gear = (r is Map ? r['gear'] : null) ?? _gear);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _bezig = false);
    }
  }

  Future<void> _ontkoppel(int productId) async {
    try {
      final r = await Api.delete('/catches/${widget.vangstId}/gear/$productId');
      if (mounted) setState(() => _gear = (r is Map ? r['gear'] : null) ?? _gear);
    } catch (_) {}
  }

  String _t(Map<String, String> m) {
    final l = Provider.of<I18n>(context, listen: false).locale;
    return m[l] ?? m['en'] ?? '';
  }

  String _soortNaam(String c) => _t(_soorten[c]?['l'] as Map<String, String>? ?? const {'en': 'Other'});
  String _soortIcoon(String c) => (_soorten[c]?['e'] as String?) ?? '📦';

  @override
  Widget build(BuildContext context) {
    if (!_geladen) return const SizedBox.shrink();
    // Niet van jou en er hangt niets aan? Dan is dit blok alleen ruis.
    if (!widget.vanMij && _gear.isEmpty) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 22),
      Row(children: [
        const Icon(Icons.handyman_outlined, size: 17, color: AppColors.teal),
        const SizedBox(width: 6),
        Text(_t(_lTitel), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy)),
      ]),
      const SizedBox(height: 8),
      if (_gear.isEmpty)
        Text(_t(_lLeeg), style: const TextStyle(fontSize: 13, color: Colors.black45))
      else
        Wrap(spacing: 8, runSpacing: 8, children: [for (final g in _gear) _spelden(g as Map)]),
      if (widget.vanMij && _sets.isNotEmpty) ...[
        const SizedBox(height: 10),
        Text(_t(_lSetKoppelen), style: const TextStyle(fontSize: 12, color: Colors.black45)),
        const SizedBox(height: 4),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final st in _sets)
            OutlinedButton(
              onPressed: _bezig ? null : () => _koppelSet(((st as Map)['id'] as num).toInt()),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.teal, visualDensity: VisualDensity.compact),
              child: Text('🎒 ${(st as Map)['name'] ?? ''}'),
            ),
        ]),
      ],
      if (widget.vanMij) ...[
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _bezig ? null : _zoekBlad,
          icon: const Icon(Icons.add, size: 18),
          label: Text(_t(_lToevoegen)),
        ),
      ],
    ]);
  }

  Widget _spelden(Map g) {
    final merk = '${g['brand'] ?? ''}';
    final koop = '${g['affiliate_url'] ?? ''}';
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 5, 6, 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(_soortIcoon('${g['category']}'), style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 190),
          child: Text([if (merk.isNotEmpty) merk, '${g['name'] ?? ''}'].join(' '),
              overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
        ),
        if ('${g['status']}' == 'submitted') Padding(padding: const EdgeInsets.only(left: 6),
          child: Text(_t(_lWacht), style: const TextStyle(fontSize: 10, color: Color(0xFFB45309)))),
        if (koop.isNotEmpty) Padding(padding: const EdgeInsets.only(left: 6), child: InkWell(
          onTap: () => launchUrl(Uri.parse(koop), mode: LaunchMode.externalApplication),
          child: Text(_t(_lKopen), style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.teal)))),
        if (widget.vanMij) InkWell(
          onTap: () => _ontkoppel(((g['id'] as num?) ?? 0).toInt()),
          child: const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.close, size: 15, color: Colors.black26))),
      ]),
    );
  }

  /// Zoeken in de catalogus, met de mogelijkheid het zelf toe te voegen.
  void _zoekBlad() {
    final zoek = TextEditingController();
    final naam = TextEditingController();
    final merk = TextEditingController();
    var soort = 'lure';
    var zelf = false;
    List gevonden = [];
    var zoeken = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (c) => StatefulBuilder(builder: (c, setBlad) {
        Future<void> zoekNu(String q) async {
          if (q.trim().length < 2) { setBlad(() => gevonden = []); return; }
          setBlad(() => zoeken = true);
          try {
            final r = await Api.get('/catalog/search?q=${Uri.encodeComponent(q.trim())}');
            gevonden = (r is Map ? r['products'] : null) ?? [];
          } catch (_) {
            gevonden = [];
          }
          setBlad(() => zoeken = false);
        }

        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom),
          child: DraggableScrollableSheet(
            initialChildSize: 0.8, minChildSize: 0.4, maxChildSize: 0.95, expand: false,
            builder: (_, scroll) => ListView(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              children: [
                Text(_t(_lToevoegen), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.navy)),
                const SizedBox(height: 10),
                if (!zelf) ...[
                  TextField(
                    controller: zoek,
                    autofocus: true,
                    onChanged: zoekNu,
                    decoration: InputDecoration(
                      isDense: true,
                      prefixIcon: const Icon(Icons.search, size: 18),
                      hintText: _t(_lZoek),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  if (zoeken) const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
                  for (final p in gevonden)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Text(_soortIcoon('${(p as Map)['category']}'), style: const TextStyle(fontSize: 18)),
                      title: Text([if ('${p['brand'] ?? ''}'.isNotEmpty) '${p['brand']}', '${p['name'] ?? ''}'].join(' ')),
                      subtitle: Text(_soortNaam('${p['category']}'), style: const TextStyle(fontSize: 12)),
                      onTap: () { Navigator.pop(c); _koppel({'product_id': (p['id'] as num).toInt()}); },
                    ),
                  const SizedBox(height: 6),
                  TextButton(onPressed: () => setBlad(() => zelf = true), child: Text(_t(_lNietGevonden))),
                ] else ...[
                  TextField(controller: naam, autofocus: true, decoration: InputDecoration(
                    isDense: true, labelText: _t(_lNaam), border: const OutlineInputBorder())),
                  const SizedBox(height: 10),
                  TextField(controller: merk, decoration: InputDecoration(
                    isDense: true, labelText: _t(_lMerk), border: const OutlineInputBorder())),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: soort,
                    decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                    items: [for (final k in _soorten.keys) DropdownMenuItem(value: k, child: Text('${_soortIcoon(k)}  ${_soortNaam(k)}'))],
                    onChanged: (v) => setBlad(() => soort = v ?? 'other'),
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: () {
                      if (naam.text.trim().isEmpty) return;
                      Navigator.pop(c);
                      _koppel({
                        'name': naam.text.trim(),
                        'category': soort,
                        if (merk.text.trim().isNotEmpty) 'brand': merk.text.trim(),
                      });
                    },
                    style: FilledButton.styleFrom(backgroundColor: AppColors.teal, minimumSize: const Size.fromHeight(44)),
                    child: Text(_t(_lOpslaan)),
                  ),
                ],
              ],
            ),
          ),
        );
      }),
    ).whenComplete(() { zoek.dispose(); naam.dispose(); merk.dispose(); });
  }
}

// ── Teksten, zes talen (gelijk aan het web; Spaans en Pools stonden daar nog niet in) ──────────
const Map<String, Map<String, Object>> _soorten = {
  'rod': {'e': '🎣', 'l': {'nl': 'Hengel', 'en': 'Rod', 'de': 'Rute', 'fr': 'Canne', 'es': 'Caña', 'pl': 'Wędka'}},
  'reel': {'e': '🎡', 'l': {'nl': 'Molen', 'en': 'Reel', 'de': 'Rolle', 'fr': 'Moulinet', 'es': 'Carrete', 'pl': 'Kołowrotek'}},
  'line': {'e': '🧵', 'l': {'nl': 'Lijn', 'en': 'Line', 'de': 'Schnur', 'fr': 'Fil', 'es': 'Línea', 'pl': 'Żyłka'}},
  'hook': {'e': '🪝', 'l': {'nl': 'Haak', 'en': 'Hook', 'de': 'Haken', 'fr': 'Hameçon', 'es': 'Anzuelo', 'pl': 'Haczyk'}},
  'leader': {'e': '🪢', 'l': {'nl': 'Onderlijn', 'en': 'Leader', 'de': 'Vorfach', 'fr': 'Bas de ligne', 'es': 'Bajo de línea', 'pl': 'Przypon'}},
  'lure': {'e': '🐟', 'l': {'nl': 'Kunstaas', 'en': 'Lure', 'de': 'Kunstköder', 'fr': 'Leurre', 'es': 'Señuelo', 'pl': 'Przynęta sztuczna'}},
  'bait': {'e': '🪱', 'l': {'nl': 'Aas', 'en': 'Bait', 'de': 'Köder', 'fr': 'Appât', 'es': 'Cebo', 'pl': 'Przynęta'}},
  'terminal': {'e': '⚙️', 'l': {'nl': 'Klein materiaal', 'en': 'Terminal', 'de': 'Kleinteile', 'fr': 'Terminal', 'es': 'Material pequeño', 'pl': 'Drobny sprzęt'}},
  'other': {'e': '📦', 'l': {'nl': 'Overig', 'en': 'Other', 'de': 'Sonstige', 'fr': 'Autre', 'es': 'Otros', 'pl': 'Inne'}},
};

const _lTitel = {'nl': 'Uitrusting', 'en': 'Gear', 'de': 'Ausrüstung', 'fr': 'Équipement', 'es': 'Equipo', 'pl': 'Sprzęt'};
const _lLeeg = {'nl': 'Nog geen uitrusting gekoppeld.', 'en': 'No gear linked yet.', 'de': 'Noch keine Ausrüstung verknüpft.', 'fr': 'Aucun matériel associé.', 'es': 'Aún no hay equipo asociado.', 'pl': 'Nie podpięto jeszcze sprzętu.'};
const _lToevoegen = {'nl': 'Uitrusting koppelen', 'en': 'Link gear', 'de': 'Ausrüstung verknüpfen', 'fr': 'Associer du matériel', 'es': 'Asociar equipo', 'pl': 'Podepnij sprzęt'};
const _lSetKoppelen = {'nl': 'Uitrusting koppelen:', 'en': 'Attach setup:', 'de': 'Ausrüstung verknüpfen:', 'fr': 'Associer un équipement :', 'es': 'Asociar equipo:', 'pl': 'Podepnij zestaw:'};
const _lZoek = {'nl': 'Zoek merk of product…', 'en': 'Search brand or product…', 'de': 'Marke oder Produkt suchen…', 'fr': 'Chercher marque ou produit…', 'es': 'Busca marca o producto…', 'pl': 'Szukaj marki lub produktu…'};
const _lNietGevonden = {'nl': 'Niet gevonden? Zelf toevoegen', 'en': 'Not found? Add it yourself', 'de': 'Nicht gefunden? Selbst hinzufügen', 'fr': 'Introuvable ? Ajoute-le', 'es': '¿No lo encuentras? Añádelo tú', 'pl': 'Nie znalazłeś? Dodaj sam'};
const _lNaam = {'nl': 'Productnaam', 'en': 'Product name', 'de': 'Produktname', 'fr': 'Nom du produit', 'es': 'Nombre del producto', 'pl': 'Nazwa produktu'};
const _lMerk = {'nl': 'Merk (optioneel)', 'en': 'Brand (optional)', 'de': 'Marke (optional)', 'fr': 'Marque (option)', 'es': 'Marca (opcional)', 'pl': 'Marka (opcjonalnie)'};
const _lOpslaan = {'nl': 'Toevoegen', 'en': 'Add', 'de': 'Hinzufügen', 'fr': 'Ajouter', 'es': 'Añadir', 'pl': 'Dodaj'};
const _lKopen = {'nl': 'Kopen', 'en': 'Buy', 'de': 'Kaufen', 'fr': 'Acheter', 'es': 'Comprar', 'pl': 'Kup'};
const _lWacht = {'nl': 'wacht op goedkeuring', 'en': 'awaiting approval', 'de': 'wartet auf Freigabe', 'fr': 'en attente', 'es': 'pendiente', 'pl': 'czeka na zatwierdzenie'};
