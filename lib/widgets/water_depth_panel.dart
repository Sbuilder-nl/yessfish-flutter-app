import "package:yessfish/widgets/dobber_text.dart";
import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/config.dart';
import '../screens/sterren_screen.dart';
import '../screens/dieptekaart_screen.dart';

/// Dieptelaag + AI-wateranalyse in het waterpaneel (dobbers-model, 1.0.30).
/// Zelfstandige widget: haalt /waters/{id}/depth-info en /analysis op en toont
/// de juiste knoppen (ontgrendelen 10⭐ / update 3⭐ / delers gratis / lege-water-prompt).
class WaterDepthPanel extends StatefulWidget {
  final dynamic waterId;
  final VoidCallback? onUnlocked; // kaartlaag verversen na ontgrendelen
  const WaterDepthPanel({super.key, required this.waterId, this.onUnlocked});
  @override
  State<WaterDepthPanel> createState() => _WaterDepthPanelState();
}

class _WaterDepthPanelState extends State<WaterDepthPanel> {
  Map? _info;
  Map? _analysis;
  bool _busy = false;
  String _msg = '';
  bool _needBuy = false; // te weinig dobbers → "Dobbers kopen"-knop

  String get _lang => Localizations.localeOf(context).languageCode;
  String _t(Map<String, String> m) => m[_lang] ?? m['en'] ?? m['nl'] ?? '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final i = await Api.get('/waters/${widget.waterId}/depth-info');
      if (mounted && i is Map) setState(() => _info = i);
    } catch (_) {}
    try {
      final a = await Api.get('/waters/${widget.waterId}/analysis');
      if (mounted && a is Map && a['analysis'] != null) setState(() => _analysis = a['analysis']);
    } catch (_) {}
  }

  Future<void> _unlock() async {
    setState(() { _busy = true; _msg = ''; });
    try {
      await Api.post('/waters/${widget.waterId}/depth-unlock', {});
      setState(() => _msg = _t(_unlockedMsg));
      widget.onUnlocked?.call();
      await _load();
    } on ApiException catch (e) {
      setState(() { _msg = e.message; _needBuy = e.data is Map && e.data['code'] == 'insufficient_bobbers'; });
    } catch (_) {
      setState(() => _msg = _t(_fail));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _runAnalysis() async {
    setState(() { _busy = true; _msg = ''; });
    try {
      final r = await Api.post('/waters/${widget.waterId}/analysis', {});
      if (r is Map && r['analysis'] != null && mounted) setState(() => _analysis = r['analysis']);
    } on ApiException catch (e) {
      setState(() { _msg = e.message; _needBuy = e.data is Map && e.data['code'] == 'insufficient_bobbers'; });
    } catch (_) {
      setState(() => _msg = _t(_fail));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final i = _info;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // ── Dieptelaag ──────────────────────────────────────────────────
      Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.black12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [const Icon(Icons.water, size: 16, color: AppColors.navy), const SizedBox(width: 6),
            Text(_t(_depthTitle), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black54))]),
          const SizedBox(height: 8),
          if (i == null) const SizedBox(height: 18, child: Center(child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))))
          else if (i['sharer'] == true)
            Text(_t(_sharerFree), style: const TextStyle(fontSize: 13, color: AppColors.teal, fontWeight: FontWeight.w600))
          else if ((i['community_cells'] ?? 0) == 0 && i['my_data'] != true)
            Text(_t(_noData), style: const TextStyle(fontSize: 13, color: Colors.black54))
          else if (i['unlocked'] != true)
            Row(children: [
              Expanded(child: Text('${i['community_cells']} ${_t(_cellsOf)} ${i['contributors']} ${_t(_fishers)}', style: const TextStyle(fontSize: 13, color: Colors.black54))),
              FilledButton(onPressed: _busy ? null : _unlock,
                style: FilledButton.styleFrom(backgroundColor: AppColors.teal, visualDensity: VisualDensity.compact),
                child: DobberText('${_t(_unlockBtn)} (${i['unlock_cost']} ⭐)', style: const TextStyle(fontSize: 13))),
            ])
          else if (i['update_available'] == true)
            Row(children: [
              Expanded(child: Text(_t(_updateAvail), style: const TextStyle(fontSize: 13, color: Colors.black54))),
              FilledButton(onPressed: _busy ? null : _unlock,
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD85C26), visualDensity: VisualDensity.compact),
                child: DobberText('${_t(_updateBtn)} (${i['update_cost']} ⭐)', style: const TextStyle(fontSize: 13))),
            ])
          else ...[
            Text(_t(_unlockedMsg), style: const TextStyle(fontSize: 13, color: AppColors.teal, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.navy, visualDensity: VisualDensity.compact),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => DieptekaartScreen(waterId: widget.waterId))),
              icon: const Text('🌊', style: TextStyle(fontSize: 15)),
              label: Text(_t(_viewMap), style: const TextStyle(fontSize: 13))),
          ],
        ]),
      ),
      // ── AI-wateranalyse ─────────────────────────────────────────────
      Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.black12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('🤖 ', style: TextStyle(fontSize: 14)),
            Expanded(child: Text(_t(_aiTitle), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black54))),
            TextButton(onPressed: _busy ? null : _runAnalysis,
              child: DobberText(_busy ? '…' : (_analysis != null ? _t(_aiAgain) : '${_t(_aiRun)} (5 ⭐)'), style: const TextStyle(fontSize: 12.5))),
          ]),
          if (_analysis != null) ...[
            const SizedBox(height: 4),
            ..._renderMarkdown('${_analysis!['content']}'),
          ] else if (!_busy)
            DobberText(_t(_aiHint), style: const TextStyle(fontSize: 12.5, color: Colors.black45)),
        ]),
      ),
      if (_msg.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8),
        child: Text(_msg, style: const TextStyle(fontSize: 12.5, color: AppColors.teal))),
      if (_needBuy) Padding(padding: const EdgeInsets.only(top: 6), child: Align(alignment: Alignment.centerLeft, child: FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: const Color(0xFFd85c26), visualDensity: VisualDensity.compact),
        onPressed: () async { await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SterrenScreen())); if (mounted) setState(() { _needBuy = false; _msg = ''; }); },
        icon: const Icon(Icons.shopping_bag_outlined, size: 18), label: Text(_t(_buy))))),
    ]);
  }

  /// Mini-markdown: ## → vetgedrukte kop, ** weghalen, rest gewone regels.
  List<Widget> _renderMarkdown(String md) {
    final out = <Widget>[];
    for (final ln in md.split('\n')) {
      final t = ln.trim();
      if (t.isEmpty) continue;
      if (t.startsWith('## ')) {
        out.add(Padding(padding: const EdgeInsets.only(top: 8, bottom: 2),
          child: Text(t.substring(3), style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.navy))));
      } else {
        out.add(Padding(padding: const EdgeInsets.only(bottom: 3),
          child: Text(t.replaceAll('**', ''), style: const TextStyle(fontSize: 13, height: 1.35))));
      }
    }
    return out;
  }
}

const _depthTitle = {'nl': 'DIEPTELAAG', 'en': 'DEPTH LAYER', 'de': 'TIEFENKARTE', 'fr': 'PROFONDEUR', 'es': 'PROFUNDIDAD', 'pl': 'GŁĘBOKOŚĆ'};
const _sharerFree = {'nl': 'Jij deelt hier zelf — dieptelaag gratis ✓', 'en': 'You share here — depth layer free ✓', 'de': 'Du teilst hier — Tiefenkarte gratis ✓', 'fr': 'Tu partages ici — profondeur gratuite ✓', 'es': 'Tú compartes aquí — capa gratis ✓', 'pl': 'Udostępniasz tutaj — warstwa gratis ✓'};
const _noData = {'nl': 'Nog geen dieptedata van dit water — importeer als eerste je metingen via Mijn data (en kijk hier daarna gratis).', 'en': 'No depth data yet — be the first to import your soundings via My data (and view it free afterwards).', 'de': 'Noch keine Tiefendaten — importiere als Erster über Meine Daten (und schau danach gratis).', 'fr': 'Pas encore de données — importe tes mesures via Mes données (et regarde gratuitement ensuite).', 'es': 'Sin datos aún — importa tus mediciones vía Mis datos (y míralo gratis después).', 'pl': 'Brak danych — zaimportuj pomiary przez Moje dane (i oglądaj za darmo).'};
const _cellsOf = {'nl': 'dieptevakken van', 'en': 'depth cells from', 'de': 'Tiefenzellen von', 'fr': 'cellules de', 'es': 'celdas de', 'pl': 'komórek od'};
const _fishers = {'nl': 'visser(s)', 'en': 'angler(s)', 'de': 'Angler(n)', 'fr': 'pêcheur(s)', 'es': 'pescador(es)', 'pl': 'wędkarzy'};
const _unlockBtn = {'nl': 'Ontgrendel', 'en': 'Unlock', 'de': 'Freischalten', 'fr': 'Débloquer', 'es': 'Desbloquear', 'pl': 'Odblokuj'};
const _updateBtn = {'nl': 'Update', 'en': 'Update', 'de': 'Update', 'fr': 'Mise à jour', 'es': 'Actualizar', 'pl': 'Aktualizuj'};
const _updateAvail = {'nl': 'Er zijn nieuwe metingen beschikbaar.', 'en': 'New soundings are available.', 'de': 'Neue Messungen verfügbar.', 'fr': 'Nouvelles mesures disponibles.', 'es': 'Nuevas mediciones disponibles.', 'pl': 'Dostępne nowe pomiary.'};
const _unlockedMsg = {'nl': 'Ontgrendeld ✓ — zet de dieptelaag (m) op de kaart aan', 'en': 'Unlocked ✓ — switch on the depth layer (m) on the map', 'de': 'Freigeschaltet ✓ — Tiefenkarte (m) einschalten', 'fr': 'Débloqué ✓ — active la couche (m) sur la carte', 'es': 'Desbloqueado ✓ — activa la capa (m)', 'pl': 'Odblokowano ✓ — włącz warstwę (m)'};
const _aiTitle = {'nl': 'AI-WATERANALYSE', 'en': 'AI WATER ANALYSIS', 'de': 'KI-GEWÄSSERANALYSE', 'fr': 'ANALYSE IA', 'es': 'ANÁLISIS IA', 'pl': 'ANALIZA AI'};
const _aiRun = {'nl': 'Analyseer', 'en': 'Analyse', 'de': 'Analysieren', 'fr': 'Analyser', 'es': 'Analizar', 'pl': 'Analizuj'};
const _aiAgain = {'nl': 'Opnieuw (gratis bij zelfde data)', 'en': 'Again (free if data unchanged)', 'de': 'Erneut (gratis bei gleichen Daten)', 'fr': 'Encore (gratuit si inchangé)', 'es': 'De nuevo (gratis sin datos nuevos)', 'pl': 'Ponownie (gratis bez zmian)'};
const _aiHint = {'nl': 'Laat de AI dropoffs, kansrijke plekken en voeradvies uit de diepte-data halen (5 ⭐).', 'en': 'Let the AI find dropoffs, hotspots and bait advice from the depth data (5 ⭐).', 'de': 'Lass die KI Dropoffs, Hotspots und Fütterungstipps aus den Tiefendaten holen (5 ⭐).', 'fr': 'L’IA trouve dropoffs, spots et conseils d’amorçage dans les données (5 ⭐).', 'es': 'La IA encuentra desniveles, zonas y consejos de cebado (5 ⭐).', 'pl': 'AI znajdzie uskoki, miejscówki i porady nęcenia (5 ⭐).'};
const _fail = {'nl': 'Even niet gelukt — probeer opnieuw.', 'en': 'That didn’t work — try again.', 'de': 'Hat nicht geklappt — versuch es erneut.', 'fr': 'Échec — réessaie.', 'es': 'No funcionó — inténtalo de nuevo.', 'pl': 'Nie udało się — spróbuj ponownie.'};
const _buy = {'nl': 'Dobbers kopen', 'en': 'Buy bobbers', 'de': 'Posen kaufen', 'fr': 'Acheter des flotteurs', 'es': 'Comprar boyas', 'pl': 'Kup spławiki'};
const _viewMap = {'nl': 'Dieptekaart bekijken', 'en': 'View depth map', 'de': 'Tiefenkarte ansehen', 'fr': 'Voir la carte', 'es': 'Ver mapa', 'pl': 'Zobacz mapę'};
