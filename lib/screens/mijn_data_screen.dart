import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/config.dart';

/// "Mijn data" — fishfinder-/voerboot-uploads (CSV/GPX): importeren met voorbeeld,
/// batches bekijken, publiek/privé omzetten en verwijderen. Zelfde flow als de website.
const Map<String, Map<String, String>> _L = {
  'title': {'nl': 'Mijn data', 'en': 'My data', 'de': 'Meine Daten', 'fr': 'Mes données', 'es': 'Mis datos', 'pl': 'Moje dane'},
  'intro': {'nl': 'Importeer diepte- en stekdata van je fishfinder of voerboot (CSV of GPX). Publiek delen is gratis; privé houden kost 5 dobbers.', 'en': 'Import depth and spot data from your fishfinder or bait boat (CSV or GPX). Sharing publicly is free; keeping it private costs 5 bobbers.', 'de': 'Importiere Tiefen- und Stellen-Daten von Echolot oder Futterboot (CSV oder GPX). Öffentlich teilen ist gratis; privat halten kostet 5 Posen.', 'fr': 'Importe les données de profondeur et de spots de ton sondeur ou bateau amorceur (CSV ou GPX). Partager en public est gratuit ; garder privé coûte 5 flotteurs.', 'es': 'Importa datos de profundidad y puntos de tu sonda o barco cebador (CSV o GPX). Compartir en público es gratis; mantenerlo privado cuesta 5 boyas.', 'pl': 'Importuj dane głębokości i stanowisk z echosondy lub łodzi zanętowej (CSV lub GPX). Udostępnianie publiczne jest darmowe; prywatność kosztuje 5 spławików.'},
  'pick': {'nl': 'Bestand kiezen (CSV/GPX)', 'en': 'Choose file (CSV/GPX)', 'de': 'Datei wählen (CSV/GPX)', 'fr': 'Choisir un fichier (CSV/GPX)', 'es': 'Elegir archivo (CSV/GPX)', 'pl': 'Wybierz plik (CSV/GPX)'},
  'busy': {'nl': 'Bezig met verwerken…', 'en': 'Processing…', 'de': 'Wird verarbeitet…', 'fr': 'Traitement…', 'es': 'Procesando…', 'pl': 'Przetwarzanie…'},
  'preview': {'nl': 'Voorbeeld van de import', 'en': 'Import preview', 'de': 'Import-Vorschau', 'fr': 'Aperçu de l’import', 'es': 'Vista previa', 'pl': 'Podgląd importu'},
  'points': {'nl': 'punten', 'en': 'points', 'de': 'Punkte', 'fr': 'points', 'es': 'puntos', 'pl': 'punkty'},
  'skipped': {'nl': 'overgeslagen (buiten bekend water)', 'en': 'skipped (outside known waters)', 'de': 'übersprungen (außerhalb bekannter Gewässer)', 'fr': 'ignorés (hors eaux connues)', 'es': 'omitidos (fuera de aguas conocidas)', 'pl': 'pominięte (poza znanymi wodami)'},
  'waters': {'nl': 'Waters', 'en': 'Waters', 'de': 'Gewässer', 'fr': 'Eaux', 'es': 'Aguas', 'pl': 'Wody'},
  'vis_q': {'nl': 'Zichtbaarheid van deze dieptedata', 'en': 'Visibility of this depth data', 'de': 'Sichtbarkeit dieser Tiefendaten', 'fr': 'Visibilité de ces données', 'es': 'Visibilidad de estos datos', 'pl': 'Widoczność tych danych'},
  'vis_public': {'nl': 'Publiek delen (gratis)', 'en': 'Share publicly (free)', 'de': 'Öffentlich teilen (gratis)', 'fr': 'Partager en public (gratuit)', 'es': 'Compartir en público (gratis)', 'pl': 'Udostępnij publicznie (za darmo)'},
  'vis_private': {'nl': 'Privé houden (5 ⭐)', 'en': 'Keep private (5 ⭐)', 'de': 'Privat halten (5 ⭐)', 'fr': 'Garder privé (5 ⭐)', 'es': 'Mantener privado (5 ⭐)', 'pl': 'Zachowaj prywatnie (5 ⭐)'},
  'import': {'nl': 'Importeren', 'en': 'Import', 'de': 'Importieren', 'fr': 'Importer', 'es': 'Importar', 'pl': 'Importuj'},
  'cancel': {'nl': 'Annuleren', 'en': 'Cancel', 'de': 'Abbrechen', 'fr': 'Annuler', 'es': 'Cancelar', 'pl': 'Anuluj'},
  'done': {'nl': 'Import gelukt ✓', 'en': 'Import complete ✓', 'de': 'Import fertig ✓', 'fr': 'Import terminé ✓', 'es': 'Importación lista ✓', 'pl': 'Import zakończony ✓'},
  'empty': {'nl': 'Nog geen uploads. Kies een CSV- of GPX-bestand van je fishfinder om te beginnen.', 'en': 'No uploads yet. Pick a CSV or GPX file from your fishfinder to get started.', 'de': 'Noch keine Uploads. Wähle eine CSV- oder GPX-Datei deines Echolots.', 'fr': 'Pas encore d’imports. Choisis un fichier CSV ou GPX de ton sondeur.', 'es': 'Aún sin subidas. Elige un archivo CSV o GPX de tu sonda.', 'pl': 'Brak przesłanych plików. Wybierz plik CSV lub GPX z echosondy.'},
  'kind_depth': {'nl': 'Dieptemetingen', 'en': 'Depth soundings', 'de': 'Tiefenmessungen', 'fr': 'Sondages de profondeur', 'es': 'Sondeos de profundidad', 'pl': 'Pomiary głębokości'},
  'kind_spots': {'nl': 'Stekken', 'en': 'Spots', 'de': 'Stellen', 'fr': 'Spots', 'es': 'Puntos', 'pl': 'Stanowiska'},
  'public': {'nl': 'publiek', 'en': 'public', 'de': 'öffentlich', 'fr': 'public', 'es': 'público', 'pl': 'publiczne'},
  'private': {'nl': 'privé', 'en': 'private', 'de': 'privat', 'fr': 'privé', 'es': 'privado', 'pl': 'prywatne'},
  'make_public': {'nl': 'Publiek maken (gratis)', 'en': 'Make public (free)', 'de': 'Öffentlich machen (gratis)', 'fr': 'Rendre public (gratuit)', 'es': 'Hacer público (gratis)', 'pl': 'Ustaw jako publiczne (za darmo)'},
  'make_private': {'nl': 'Privé maken (5 ⭐)', 'en': 'Make private (5 ⭐)', 'de': 'Privat machen (5 ⭐)', 'fr': 'Rendre privé (5 ⭐)', 'es': 'Hacer privado (5 ⭐)', 'pl': 'Ustaw jako prywatne (5 ⭐)'},
  'delete': {'nl': 'Verwijderen', 'en': 'Delete', 'de': 'Löschen', 'fr': 'Supprimer', 'es': 'Eliminar', 'pl': 'Usuń'},
  'delete_q': {'nl': 'Hele upload verwijderen, inclusief alle metingen/stekken eruit?', 'en': 'Delete this whole upload, including all its soundings/spots?', 'de': 'Ganzen Upload löschen, inklusive aller Messungen/Stellen?', 'fr': 'Supprimer tout l’import, y compris toutes les données ?', 'es': '¿Eliminar toda la subida, con todos sus datos?', 'pl': 'Usunąć cały import wraz ze wszystkimi danymi?'},
  'stats': {'nl': 'Diepte: min %a m · gem %b m · max %c m', 'en': 'Depth: min %a m · avg %b m · max %c m', 'de': 'Tiefe: min %a m · Ø %b m · max %c m', 'fr': 'Profondeur : min %a m · moy %b m · max %c m', 'es': 'Profundidad: mín %a m · med %b m · máx %c m', 'pl': 'Głębokość: min %a m · śr. %b m · maks %c m'},
  'stars': {'nl': 'Dobbers', 'en': 'Bobbers', 'de': 'Posen', 'fr': 'Flotteurs', 'es': 'Boyas', 'pl': 'Spławiki'},
};

String mdt(BuildContext c, String k) {
  final lang = Localizations.localeOf(c).languageCode;
  return _L[k]?[lang] ?? _L[k]?['en'] ?? k;
}

class MijnDataScreen extends StatefulWidget {
  const MijnDataScreen({super.key});
  @override
  State<MijnDataScreen> createState() => _MijnDataScreenState();
}

class _MijnDataScreenState extends State<MijnDataScreen> {
  List<dynamic> _batches = [];
  int? _bobbers;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final b = await Api.get('/imports');
      if (b is List) _batches = b;
    } catch (_) {}
    try {
      final c = await Api.get('/coins');
      if (c is Map) _bobbers = (c['ai_points'] as num?)?.toInt();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _fail(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : '$e')));
  }

  Future<void> _pickAndImport() async {
    final res = await FilePicker.pickFiles(type: FileType.any, withData: false);
    final path = res?.files.single.path;
    if (path == null) return;
    final naam = res!.files.single.name.toLowerCase();
    if (!naam.endsWith('.csv') && !naam.endsWith('.gpx')) {
      _fail('CSV/GPX'); return;
    }
    setState(() => _busy = true);
    Map preview;
    try {
      preview = await Api.uploadImport(path, dryRun: true);
    } catch (e) { _fail(e); setState(() => _busy = false); return; }
    setState(() => _busy = false);
    if (!mounted) return;

    // Voorbeeld + zichtbaarheidskeuze (alleen dieptedata heeft die keuze; stekken zijn altijd privé).
    final isDepth = preview['kind'] == 'depth';
    String vis = 'public';
    final ok = await showModalBottomSheet<bool>(context: context, isScrollControlled: true, builder: (ctx) =>
      StatefulBuilder(builder: (ctx, setSheet) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom + MediaQuery.of(ctx).padding.bottom),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(mdt(ctx, 'preview'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.navy)),
          const SizedBox(height: 10),
          Row(children: [
            Icon(isDepth ? Icons.water : Icons.place, size: 18, color: AppColors.teal), const SizedBox(width: 6),
            Text('${mdt(ctx, isDepth ? 'kind_depth' : 'kind_spots')}: ${preview['points']} ${mdt(ctx, 'points')}', style: const TextStyle(fontWeight: FontWeight.w600)),
          ]),
          if ((preview['skipped'] ?? 0) > 0) Padding(padding: const EdgeInsets.only(top: 4),
            child: Text('${preview['skipped']} ${mdt(ctx, 'skipped')}', style: const TextStyle(fontSize: 12, color: Colors.black54))),
          if (preview['waters'] is List && (preview['waters'] as List).isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6),
            child: Text('${mdt(ctx, 'waters')}: ${(preview['waters'] as List).map((w) => w['name']).join(', ')}',
              style: const TextStyle(fontSize: 12, color: Colors.black54))),
          if (isDepth) ...[
            const SizedBox(height: 12),
            Text(mdt(ctx, 'vis_q'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            RadioListTile<String>(value: 'public', groupValue: vis, dense: true, contentPadding: EdgeInsets.zero,
              title: Text(mdt(ctx, 'vis_public')), onChanged: (v) => setSheet(() => vis = v!)),
            RadioListTile<String>(value: 'private', groupValue: vis, dense: true, contentPadding: EdgeInsets.zero,
              title: Text(mdt(ctx, 'vis_private')), onChanged: (v) => setSheet(() => vis = v!)),
          ],
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: FilledButton.icon(onPressed: () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.file_download_done, size: 18), label: Text(mdt(ctx, 'import')))),
            const SizedBox(width: 8),
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(mdt(ctx, 'cancel'))),
          ]),
        ]),
      )));
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await Api.uploadImport(path, visibility: vis);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mdt(context, 'done'))));
    } catch (e) { _fail(e); }
    if (mounted) setState(() => _busy = false);
    _load();
  }

  Future<void> _toggleVisibility(Map b) async {
    final naarPrivate = b['visibility'] == 'public';
    try {
      await Api.put('/imports/${b['id']}', {'visibility': naarPrivate ? 'private' : 'public'});
      _load();
    } catch (e) { _fail(e); }
  }

  Future<void> _delete(Map b) async {
    final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      scrollable: true,
      content: Text(mdt(c, 'delete_q')),
      actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: Text(mdt(c, 'cancel'))),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(mdt(c, 'delete')))],
    ));
    if (ok != true) return;
    try { await Api.delete('/imports/${b['id']}'); _load(); } catch (e) { _fail(e); }
  }

  Future<void> _showDetail(Map b) async {
    Map d = {};
    try { final r = await Api.get('/imports/${b['id']}/points'); if (r is Map) d = r; } catch (e) { _fail(e); return; }
    if (!mounted) return;
    final stats = d['stats'] is Map ? d['stats'] as Map : null;
    showModalBottomSheet(context: context, builder: (ctx) => Padding(padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(ctx).padding.bottom),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${b['filename']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
        const SizedBox(height: 8),
        Text('${mdt(ctx, d['kind'] == 'spots' ? 'kind_spots' : 'kind_depth')}: ${(d['points'] as List?)?.length ?? 0} ${mdt(ctx, 'points')}'),
        if (stats != null && stats['min'] != null) Padding(padding: const EdgeInsets.only(top: 6),
          child: Text(mdt(ctx, 'stats').replaceFirst('%a', '${stats['min']}').replaceFirst('%b', '${stats['avg']}').replaceFirst('%c', '${stats['max']}'),
            style: const TextStyle(color: Colors.black54))),
        if (b['waters'] is List && (b['waters'] as List).isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6),
          child: Text('${mdt(ctx, 'waters')}: ${(b['waters'] as List).map((w) => w['name']).join(', ')}',
            style: const TextStyle(fontSize: 12, color: Colors.black54))),
        const SizedBox(height: 8),
      ])));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(mdt(context, 'title')), actions: [
        if (_bobbers != null) Padding(padding: const EdgeInsets.only(right: 14), child: Center(child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
          child: Text('⭐ $_bobbers', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))))),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy ? null : _pickAndImport,
        icon: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.upload_file, color: Colors.white),
        label: Text(mdt(context, _busy ? 'busy' : 'pick'), style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.teal,
      ),
      body: _loading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 90) + EdgeInsets.only(bottom: 16 + MediaQuery.of(context).padding.bottom), children: [
          Text(mdt(context, 'intro'), style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
          const SizedBox(height: 12),
          if (_batches.isEmpty) Padding(padding: const EdgeInsets.only(top: 40),
            child: Center(child: Text(mdt(context, 'empty'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.black45)))),
          for (final b in _batches)
            Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
              onTap: () => _showDetail(b as Map),
              leading: Icon(b['kind'] == 'spots' ? Icons.place_outlined : Icons.water_outlined, color: AppColors.teal),
              title: Text('${b['filename']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: Text('${mdt(context, b['kind'] == 'spots' ? 'kind_spots' : 'kind_depth')} · '
                  '${b['kind'] == 'spots' ? b['spots_count'] : b['depth_count']} ${mdt(context, 'points')} · '
                  '${mdt(context, '${b['visibility']}' == 'private' ? 'private' : 'public')} · ${'${b['created_at'] ?? ''}'.split('T').first}',
                style: const TextStyle(fontSize: 12)),
              trailing: PopupMenuButton<String>(
                onSelected: (v) { if (v == 'vis') { _toggleVisibility(b as Map); } else { _delete(b as Map); } },
                itemBuilder: (_) => [
                  if (b['kind'] != 'spots') PopupMenuItem(value: 'vis',
                    child: Text(mdt(context, b['visibility'] == 'public' ? 'make_private' : 'make_public'))),
                  PopupMenuItem(value: 'del', child: Text(mdt(context, 'delete'))),
                ]),
            )),
        ]),
      ),
    );
  }
}
