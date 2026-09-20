import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api.dart';
import '../core/i18n.dart';

/// Vissoort kiezen in plaats van intypen — de app-kant van SoortKiezer op het web.
///
/// Waarom dit nodig was: de app stuurde alleen vrije tekst mee. Zo'n vangst hangt dan aan géén
/// soort, en verdwijnt dus uit de soortstatistieken, de records en de visstijl-dashboards. Op het
/// web was dat al opgelost (17-09-2026); in de app nog niet (20-09-2026).
///
/// Zelf iets intypen mag gewoon: wie een soort vangt die niet in de lijst staat wordt niet
/// tegengehouden. De server probeert die tekst daarna alsnog te herkennen.
class SoortKiezer extends StatefulWidget {
  const SoortKiezer({
    super.key,
    required this.controller,
    required this.onKies,
    this.label,
    this.isDense = false,
  });

  /// Het tekstveld zelf houdt de naam bij; zo blijft vrije tekst mogelijk.
  final TextEditingController controller;

  /// Gekozen soort (of null als het lid zelf iets typt dat niet in de lijst staat).
  final void Function(String naam, int? id) onKies;

  final String? label;
  final bool isDense;

  @override
  State<SoortKiezer> createState() => _SoortKiezerState();
}

class _SoortKiezerState extends State<SoortKiezer> {
  /// De soortenlijst verandert bijna nooit; één keer ophalen per sessie is genoeg.
  static List<Map>? _cache;
  static Future<void>? _bezig;

  List<Map> _lijst = _cache ?? const [];

  @override
  void initState() {
    super.initState();
    _haalLijst();
  }

  Future<void> _haalLijst() async {
    if (_cache != null) return;
    _bezig ??= () async {
      try {
        final r = await Api.get('/species');
        final lijst = r is List ? r : (r is Map ? (r['data'] ?? []) : []);
        _cache = [for (final s in lijst) if (s is Map) s];
      } catch (_) {
        // Geen lijst? Dan blijft intypen gewoon werken.
      }
    }();
    await _bezig;
    if (mounted && _cache != null) setState(() => _lijst = _cache!);
  }

  String _naam(Map s, String taal) {
    final v = s['name_$taal'];
    return (v is String && v.isNotEmpty) ? v : '${s['name_nl'] ?? ''}';
  }

  /// Zoeken door álle talen: wie "pike" typt vindt ook Snoek.
  List<Map> _treffers(String zoek, String taal) {
    final q = zoek.trim().toLowerCase();
    final uit = <Map>[];
    for (final s in _lijst) {
      if (q.isEmpty) {
        uit.add(s);
        continue;
      }
      final namen = [for (final t in const ['nl', 'en', 'de', 'fr', 'es', 'pl']) '${s['name_$t'] ?? ''}'];
      if (namen.any((n) => n.toLowerCase().contains(q))) uit.add(s);
    }
    uit.sort((a, b) => _naam(a, taal).toLowerCase().compareTo(_naam(b, taal).toLowerCase()));
    return uit.take(40).toList();
  }

  Future<void> _kiesUitLijst() async {
    final taal = Provider.of<I18n>(context, listen: false).locale;
    if (_lijst.isEmpty) await _haalLijst();
    if (!mounted || _lijst.isEmpty) return;
    final zoek = TextEditingController(text: widget.controller.text);
    final gekozen = await showModalBottomSheet<Map>(
      context: context,
      isScrollControlled: true,
      builder: (c) => StatefulBuilder(builder: (c, setBlad) {
        final rijen = _treffers(zoek.text, taal);
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom),
          child: DraggableScrollableSheet(
            initialChildSize: 0.75, minChildSize: 0.4, maxChildSize: 0.95, expand: false,
            builder: (_, scroll) => Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: TextField(
                  controller: zoek,
                  autofocus: true,
                  onChanged: (_) => setBlad(() {}),
                  decoration: InputDecoration(
                    isDense: true,
                    prefixIcon: const Icon(Icons.search, size: 18),
                    hintText: widget.label ?? context.tr('newcatch.species'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              Expanded(child: ListView.separated(
                controller: scroll,
                itemCount: rijen.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) => ListTile(
                  title: Text(_naam(rijen[i], taal)),
                  subtitle: taal == 'nl' ? null : Text('${rijen[i]['name_nl'] ?? ''}',
                      style: const TextStyle(fontSize: 12, color: Colors.black45)),
                  onTap: () => Navigator.pop(c, rijen[i]),
                ),
              )),
            ]),
          ),
        );
      }),
    );
    zoek.dispose();
    if (gekozen == null || !mounted) return;
    final naam = _naam(gekozen, taal);
    widget.controller.text = naam;
    widget.onKies(naam, (gekozen['id'] as num?)?.toInt());
  }

  @override
  Widget build(BuildContext context) => TextField(
        controller: widget.controller,
        // Zelf typen blijft gewoon mogelijk; dan hoort er geen soort-id bij.
        onChanged: (v) => widget.onKies(v, null),
        decoration: InputDecoration(
          isDense: widget.isDense,
          labelText: widget.label,
          suffixIcon: IconButton(
            icon: const Icon(Icons.arrow_drop_down),
            tooltip: widget.label,
            onPressed: _kiesUitLijst,
          ),
        ),
      );
}
