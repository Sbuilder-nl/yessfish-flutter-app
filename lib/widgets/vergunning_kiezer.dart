import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api.dart';
import '../core/config.dart';
import '../core/i18n.dart';

/// Grijs NL-water: het lid kiest welke vergunning hier geldt (Richard 28-09-2026: "kiezen tussen welke pas
/// je nodig hebt: VISpas, Fiskfergunning of een andere vereniging"). VISpas / Fiskfergunning / NHO Viskaart:
/// 3 gelijke meldingen = automatisch dat label. Clubwater (met vereniging uit de gids), dagkaart en verboden:
/// een moderator kijkt ernaar. Zelfde keuzes en teksten als op het web (PermitKiezer.tsx).
/// 29-09-2026 (Richard): buiten Nederland kiest het lid de pas van dát land of die regio (bijv. de Waalse
/// visvergunning), nooit de VISpas. Die pasnaam komt uit permit_pass van het water.
class VergunningKiezer extends StatefulWidget {
  final int waterId;
  final String? voorkeur;
  final void Function(String permitType)? onApplied;
  final bool isNL;
  final String? regioPas;
  const VergunningKiezer({super.key, required this.waterId, this.voorkeur, this.onApplied, this.isNL = true, this.regioPas});
  @override
  State<VergunningKiezer> createState() => _VergunningKiezerState();
}

const _keuzesNL = ['vispas', 'fiskfergunning', 'nho', 'club', 'betaald', 'verboden'];
const Map<String, Map<String, String>> _t = {
  'vraag': {'nl': 'Weet jij welke vergunning hier geldt?', 'en': 'Do you know which permit applies here?', 'de': 'Weißt du, welche Erlaubnis hier gilt?', 'fr': 'Savez-vous quel permis s’applique ici ?', 'es': '¿Sabes qué permiso vale aquí?', 'pl': 'Wiesz, jakie zezwolenie tu obowiązuje?'},
  'uitleg': {'nl': 'Kies de pas die je hier nodig hebt. Bij 3 gelijke meldingen krijgt het water dit label; clubwater, dagkaart en verboden bekijkt een moderator.', 'en': 'Choose the pass you need here. After 3 matching reports the water gets this label; club water, day ticket and no fishing are checked by a moderator.', 'de': 'Wähle den Pass, den du hier brauchst. Nach 3 gleichen Meldungen bekommt das Gewässer dieses Etikett; Vereinsgewässer, Tageskarte und Angelverbot prüft ein Moderator.', 'fr': 'Choisissez le permis nécessaire ici. Après 3 signalements identiques, l’eau reçoit cette étiquette ; eau de club, carte journalière et interdiction sont vérifiées par un modérateur.', 'es': 'Elige el permiso que necesitas aquí. Con 3 avisos iguales el agua recibe esta etiqueta; agua de club, permiso diario y prohibido los revisa un moderador.', 'pl': 'Wybierz zezwolenie, którego tu potrzebujesz. Po 3 takich samych zgłoszeniach woda dostanie tę etykietę; wody klubowe, kartę dzienną i zakaz sprawdza moderator.'},
  'vispas': {'nl': 'VISpas', 'en': 'VISpas', 'de': 'VISpas', 'fr': 'VISpas', 'es': 'VISpas', 'pl': 'VISpas'},
  'fiskfergunning': {'nl': 'Fiskfergunning (Friesland)', 'en': 'Fiskfergunning (Friesland)', 'de': 'Fiskfergunning (Friesland)', 'fr': 'Fiskfergunning (Frise)', 'es': 'Fiskfergunning (Frisia)', 'pl': 'Fiskfergunning (Fryzja)'},
  'nho': {'nl': 'NHO Viskaart', 'en': 'NHO permit card', 'de': 'NHO-Karte', 'fr': 'Carte NHO', 'es': 'Tarjeta NHO', 'pl': 'Karta NHO'},
  'club': {'nl': 'Clubwater (vereniging)', 'en': 'Club water (club)', 'de': 'Vereinsgewässer (Verein)', 'fr': 'Eau de club (association)', 'es': 'Agua de club (asociación)', 'pl': 'Woda klubowa (klub)'},
  'betaald': {'nl': 'Dagkaart / betaald water', 'en': 'Day ticket / paid water', 'de': 'Tageskarte / Bezahlgewässer', 'fr': 'Carte journalière / eau payante', 'es': 'Permiso diario / agua de pago', 'pl': 'Karta dzienna / łowisko płatne'},
  'verboden': {'nl': 'Vissen verboden', 'en': 'No fishing', 'de': 'Angeln verboten', 'fr': 'Pêche interdite', 'es': 'Pesca prohibida', 'pl': 'Zakaz wędkowania'},
  'zoek': {'nl': 'Zoek je vereniging (naam of plaats)', 'en': 'Search your club (name or town)', 'de': 'Suche deinen Verein (Name oder Ort)', 'fr': 'Cherchez votre association (nom ou ville)', 'es': 'Busca tu asociación (nombre o ciudad)', 'pl': 'Szukaj klubu (nazwa lub miejscowość)'},
  'dichtbij': {'nl': 'Verenigingen in de buurt', 'en': 'Clubs nearby', 'de': 'Vereine in der Nähe', 'fr': 'Associations à proximité', 'es': 'Asociaciones cercanas', 'pl': 'Kluby w pobliżu'},
  'geen': {'nl': 'Geen vereniging gevonden.', 'en': 'No club found.', 'de': 'Kein Verein gefunden.', 'fr': 'Aucune association trouvée.', 'es': 'No se encontró ninguna asociación.', 'pl': 'Nie znaleziono klubu.'},
  'stuur': {'nl': 'Melding versturen', 'en': 'Send report', 'de': 'Meldung senden', 'fr': 'Envoyer le signalement', 'es': 'Enviar aviso', 'pl': 'Wyślij zgłoszenie'},
  'wijzig': {'nl': 'Andere keuze', 'en': 'Change', 'de': 'Ändern', 'fr': 'Modifier', 'es': 'Cambiar', 'pl': 'Zmień'},
};
const Map<String, String> _label = {'vispas': 'landelijk', 'fiskfergunning': 'fiskfergunning', 'nho': 'nho', 'regiopas': 'regio', 'club': 'club', 'betaald': 'betaald', 'verboden': 'verboden'};

class _VergunningKiezerState extends State<VergunningKiezer> {
  String? _keuze;
  String _q = '';
  List<Map> _clubs = [];
  Map? _club;
  bool _bezig = false;
  String? _melding;
  Timer? _zoekTimer;

  @override
  void initState() { super.initState(); _keuze = widget.voorkeur; }
  @override
  void dispose() { _zoekTimer?.cancel(); super.dispose(); }

  // Buiten NL: geen Nederlandse passen; wel de pas van dit land/deze regio als die bekend is.
  List<String> get _keuzes => widget.isNL ? _keuzesNL
      : [if ((widget.regioPas ?? '').trim().isNotEmpty) 'regiopas', 'club', 'betaald', 'verboden'];
  String _naam(String k) => k == 'regiopas' ? widget.regioPas!.trim() : t(k);

  String t(String k) { final loc = Provider.of<I18n>(context, listen: false).locale; return _t[k]?[loc] ?? _t[k]?['en'] ?? k; }

  Future<void> _laadClubs() async {
    try {
      final q = _q.trim();
      final r = await Api.get('/waters/${widget.waterId}/permit-clubs${q.isEmpty ? '' : '?q=${Uri.encodeQueryComponent(q)}'}');
      if (mounted) setState(() => _clubs = (r is Map && r['clubs'] is List) ? List<Map>.from(r['clubs']) : []);
    } catch (_) { if (mounted) setState(() => _clubs = []); }
  }

  Future<void> _stuur() async {
    if (_keuze == null || (_keuze == 'club' && _club == null)) return;
    setState(() => _bezig = true);
    try {
      final r = await Api.post('/waters/${widget.waterId}/permit-report', {
        'claim': _keuze, if (_keuze == 'club') 'directory_id': _club!['id'],
      });
      if (!mounted) return;
      setState(() => _melding = r is Map ? '${r['message']}' : 'OK');
      if (r is Map && r['applied'] == true) widget.onApplied?.call('${r['permit_type'] ?? _label[_keuze]}');
    } catch (e) {
      if (mounted) setState(() => _melding = e is ApiException ? e.message : '$e');
    }
    if (mounted) setState(() => _bezig = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_melding != null) {
      return Padding(padding: const EdgeInsets.only(top: 8),
        child: Text(_melding!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF047857))));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 8),
      Text(t('vraag'), style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.navy)),
      const SizedBox(height: 2),
      Text(t('uitleg'), style: const TextStyle(fontSize: 12, color: Colors.black54, height: 1.3)),
      const SizedBox(height: 8),
      Wrap(spacing: 6, runSpacing: 6, children: _keuzes.map((k) => ChoiceChip(
        label: Text(_naam(k), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _keuze == k ? Colors.white : Colors.black87)),
        selected: _keuze == k,
        selectedColor: AppColors.teal,
        showCheckmark: false,
        visualDensity: VisualDensity.compact,
        onSelected: (_) { setState(() { _keuze = k; _club = null; }); if (k == 'club') _laadClubs(); },
      )).toList()),
      if (_keuze == 'club') Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(border: Border.all(color: const Color(0xFFCBD5E1)), borderRadius: BorderRadius.circular(10)),
        child: _club != null
          ? Row(children: [
              Expanded(child: Text('${_club!['name']}${(_club!['city'] ?? '') != '' ? ' · ${_club!['city']}' : ''}${(_club!['pas'] ?? '') != '' ? ' · ${_club!['pas']}' : ''}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
              TextButton(onPressed: () => setState(() => _club = null), child: Text(t('wijzig'))),
            ])
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              TextField(
                decoration: InputDecoration(isDense: true, hintText: t('zoek'), prefixIcon: const Icon(Icons.search, size: 18), border: const OutlineInputBorder()),
                onChanged: (v) { _q = v; _zoekTimer?.cancel(); _zoekTimer = Timer(const Duration(milliseconds: 300), _laadClubs); },
              ),
              if (_q.trim().isEmpty && _clubs.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8, bottom: 2),
                child: Text(t('dichtbij').toUpperCase(), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.black45, letterSpacing: 0.5))),
              ..._clubs.map((c) => InkWell(
                onTap: () => setState(() => _club = c),
                child: Padding(padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text.rich(TextSpan(children: [
                    TextSpan(text: '${c['name']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    TextSpan(text: '${(c['city'] ?? '') != '' ? ' · ${c['city']}' : ''}${c['km'] != null ? ' · ${c['km']} km' : ''}',
                        style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
                  ]))),
              )),
              if (_q.trim().isNotEmpty && _clubs.isEmpty) Padding(padding: const EdgeInsets.only(top: 6),
                child: Text(t('geen'), style: const TextStyle(fontSize: 12, color: Colors.black54))),
            ]),
      ),
      if (_keuze != null) Padding(padding: const EdgeInsets.only(top: 8),
        child: OutlinedButton.icon(
          icon: _bezig ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check, size: 16),
          label: Text(t('stuur')),
          onPressed: (_bezig || (_keuze == 'club' && _club == null)) ? null : _stuur,
        )),
    ]);
  }
}
