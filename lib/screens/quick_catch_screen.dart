import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import '../core/api.dart';
import '../core/location.dart';
import '../core/units.dart';
import '../core/config.dart';

/// Snelvangst: camera-first CONCEPT-vangst. Je maakt meteen foto's die direct uploaden;
/// bij de eerste foto wordt een concept (is_draft) aangemaakt met caught_at = nu (het vangstmoment).
/// Daarna rustig afmaken (soort/gewicht/aas/privacy) en afronden. Ook 'resume' voor een bestaand concept.
class QuickCatchScreen extends StatefulWidget {
  final int? draftId; // hervatten van een bestaand concept
  const QuickCatchScreen({super.key, this.draftId});
  @override
  State<QuickCatchScreen> createState() => _QuickCatchScreenState();
}

class _QuickCatchScreenState extends State<QuickCatchScreen> {
  final _species = TextEditingController();
  final _weight = TextEditingController();
  final _length = TextEditingController();
  final _bait = TextEditingController();
  String _privacy = 'public';
  bool _showInFeed = true;
  DateTime _caughtAt = DateTime.now();
  final List<Map<String, dynamic>> _photos = []; // {id?, path?, url}
  final Set<int> _selected = {}; // aangevinkte foto's (gaan mee naar de vangst)
  int? _draftId;
  bool _uploading = false, _saving = false, _loading = false;

  String get _lang => Localizations.localeOf(context).languageCode;
  String _t(Map<String, String> m) => m[_lang] ?? m['en'] ?? m['nl'] ?? '';

  @override
  void initState() {
    super.initState();
    _draftId = widget.draftId;
    if (_draftId != null) {
      _loadDraft();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _shoot(loop: true));
    }
  }

  Future<void> _loadDraft() async {
    setState(() => _loading = true);
    try {
      final r = await Api.get('/catches/$_draftId');
      final d = r is Map && r['data'] is Map ? r['data'] as Map : (r as Map);
      final sp = (d['species'] ?? d['species_text'] ?? '').toString();
      _species.text = sp == 'Concept' ? '' : sp;
      if (d['length_cm'] != null) _length.text = '${d['length_cm']}';
      if (d['bait'] != null) _bait.text = '${d['bait']}';
      if (d['privacy'] != null) _privacy = '${d['privacy']}';
      if (d['caught_at'] != null) _caughtAt = DateTime.tryParse('${d['caught_at']}') ?? _caughtAt;
      final ph = (d['photos'] is List) ? d['photos'] as List : [];
      for (final p in ph) { _photos.add({'id': p['id'], 'url': p['url']}); if (p['id'] != null) _selected.add(p['id'] as int); }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<String> _compress(String path) async {
    try {
      final dir = await getTemporaryDirectory();
      final target = '${dir.path}/yf_${DateTime.now().microsecondsSinceEpoch}.jpg';
      final out = await FlutterImageCompress.compressAndGetFile(path, target, minWidth: 1600, minHeight: 1600, quality: 85);
      return out?.path ?? path;
    } catch (_) { return path; }
  }

  // Camera openen (herhaalbaar: blijf foto's maken). Elke foto uploadt en hangt aan het concept.
  // Camera-lus: blijf foto's maken tot je de camera annuleert (dan verschijnt het afrond-formulier).
  Future<void> _shoot({bool loop = false}) async {
    do {
      XFile? x;
      try {
        x = await ImagePicker().pickImage(source: ImageSource.camera);
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${_t(_camFail)}: $e')));
        return;
      }
      if (x == null) return; // klaar met fotograferen
      setState(() => _uploading = true);
      try {
        final path = await _compress(x.path);
        final up = await Api.uploadImage(path);
        if (_draftId == null) {
          await _createDraft(up['path'].toString(), up['url'].toString());
        } else {
          final r = await Api.post('/catches/$_draftId/photos', {'path': up['path']});
          _photos.add({'id': r['id'], 'url': r['url'] ?? up['url']}); if (r['id'] != null) _selected.add(r['id'] as int);
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : '$e')));
      } finally {
        if (mounted) setState(() => _uploading = false);
      }
    } while (loop && mounted);
  }

  // Eerste foto → concept aanmaken (meteen veilig opgeslagen, ook als je de app sluit).
  Future<void> _createDraft(String path, String url) async {
    final body = <String, dynamic>{
      'species_text': 'Concept',
      'is_draft': true,
      'privacy': _privacy,
      'show_in_feed': false,
      'caught_at': _caughtAt.toIso8601String(),
      'photo_paths': [path],
    };
    try {
      final loc = await currentLocation();
      if (loc.isReal) { body['latitude'] = loc.lat; body['longitude'] = loc.lng; }
    } catch (_) {}
    final r = await Api.post('/catches', body);
    final d = r is Map && r['data'] is Map ? r['data'] as Map : (r as Map);
    _draftId = d['id'] as int?;
    final ph = (d['photos'] is List) ? d['photos'] as List : [];
    _photos.clear();
    if (ph.isNotEmpty) { for (final p in ph) { _photos.add({'id': p['id'], 'url': p['url']}); if (p['id'] != null) _selected.add(p['id'] as int); } }
    else { _photos.add({'url': url}); }
  }


  // Afronden: concept → definitieve vangst (is_draft false) + de ingevulde gegevens.
  void _enlarge(int i) {
    showDialog(context: context, barrierColor: Colors.black, builder: (_) => GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(alignment: Alignment.center, child: CachedNetworkImage(imageUrl: '${_photos[i]['url']}', fit: BoxFit.contain)),
    ));
  }

  Future<void> _finish() async {
    if (_draftId == null) { Navigator.pop(context); return; }
    if (_species.text.trim().isEmpty || _species.text.trim() == 'Concept') {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t(_needSpecies))));
      return;
    }
    final withId = _photos.where((p) => p['id'] != null).toList();
    if (withId.isNotEmpty && _selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t(_needPhoto))));
      return;
    }
    setState(() => _saving = true);
    try {
      // Niet-aangevinkte foto's verwijderen uit de concept-vangst.
      for (final ph in withId) {
        final pid = ph['id'] as int;
        if (!_selected.contains(pid)) { try { await Api.delete('/catches/$_draftId/photos/$pid'); } catch (_) {} }
      }
      final body = <String, dynamic>{
        'species_text': _species.text.trim(),
        'is_draft': false,
        'privacy': _privacy,
        'show_in_feed': _privacy == 'public' && _showInFeed,
        'caught_at': _caughtAt.toIso8601String(),
        if (_weight.text.isNotEmpty) 'weight_kg': Units.toKg(_weight.text),
        if (_length.text.isNotEmpty) 'length_cm': double.tryParse(_length.text.replaceAll(',', '.')),
        if (_bait.text.isNotEmpty) 'bait': _bait.text.trim(),
      };
      await Api.put('/catches/$_draftId', body);
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_t(_title))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(16), children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.teal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  const Icon(Icons.bolt, color: AppColors.teal),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_t(_intro), style: const TextStyle(fontSize: 12.5))),
                ]),
              ),
              const SizedBox(height: 12),
              if (_photos.isNotEmpty)
                SizedBox(height: 96, child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _photos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final id = _photos[i]['id'] as int?;
                    final sel = id == null || _selected.contains(id);
                    return GestureDetector(
                      onTap: () => _enlarge(i),
                      child: Stack(children: [
                        Opacity(opacity: sel ? 1 : 0.35, child: ClipRRect(borderRadius: BorderRadius.circular(10), child: CachedNetworkImage(imageUrl: '${_photos[i]['url']}', height: 96, width: 96, fit: BoxFit.cover))),
                        Positioned(right: 2, top: 2, child: GestureDetector(
                          onTap: () { if (id != null) setState(() { if (sel) { _selected.remove(id); } else { _selected.add(id); } }); },
                          child: Container(decoration: BoxDecoration(color: sel ? AppColors.teal : Colors.black45, shape: BoxShape.circle), padding: const EdgeInsets.all(3), child: Icon(sel ? Icons.check : Icons.crop_square, size: 15, color: Colors.white)))),
                      ]),
                    );
                  },
                )),
              if (_photos.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text(_t(_selectHint), style: const TextStyle(fontSize: 11.5, color: Colors.black45))),
              if (_uploading) const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: LinearProgressIndicator()),
              const SizedBox(height: 8),
              OutlinedButton.icon(onPressed: _uploading ? null : _shoot, icon: const Icon(Icons.add_a_photo), label: Text(_t(_addPhoto))),
              const Divider(height: 28),
              TextField(controller: _species, decoration: InputDecoration(labelText: _t(_speciesL))),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextField(controller: _weight, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: '${_t(_weightL)} (${Units.label})'))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: _length, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: _t(_lengthL)))),
              ]),
              const SizedBox(height: 12),
              TextField(controller: _bait, decoration: InputDecoration(labelText: _t(_baitL))),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _privacy,
                decoration: InputDecoration(labelText: _t(_privacyL)),
                items: [
                  DropdownMenuItem(value: 'public', child: Text(_t(_pubL))),
                  DropdownMenuItem(value: 'friends', child: Text(_t(_friL))),
                  DropdownMenuItem(value: 'private', child: Text(_t(_priL))),
                ],
                onChanged: (v) => setState(() => _privacy = v ?? 'public'),
              ),
              if (_privacy == 'public')
                CheckboxListTile(contentPadding: EdgeInsets.zero, value: _showInFeed, onChanged: (v) => setState(() => _showInFeed = v ?? true), title: Text(_t(_feedL))),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _saving ? null : _finish,
                icon: _saving ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check),
                label: Text(_t(_finishL)),
              ),
            ]),
    );
  }
}

// 6-talige labels
const _title = {'nl': 'Snelvangst', 'en': 'Quick catch', 'de': 'Schnellfang', 'fr': 'Prise rapide', 'es': 'Captura rápida', 'pl': 'Szybki połów'};
const _intro = {'nl': 'Maak meteen fotos (uploaden direct). Je vangst is als concept opgeslagen — later afmaken kan altijd.', 'en': 'Snap photos now (they upload instantly). Your catch is saved as a draft — finish it anytime.', 'de': 'Sofort Fotos machen (laden direkt hoch). Dein Fang ist als Entwurf gespeichert — jederzeit fertigstellen.', 'fr': 'Prends des photos (envoi direct). Ta prise est enregistrée en brouillon — à finir plus tard.', 'es': 'Haz fotos ya (se suben al instante). Tu captura queda como borrador — termínala cuando quieras.', 'pl': 'Zrób zdjęcia (od razu się wgrywają). Połów zapisany jako szkic — dokończ kiedy chcesz.'};
const _addPhoto = {'nl': 'Nog een foto', 'en': 'Another photo', 'de': 'Noch ein Foto', 'fr': 'Autre photo', 'es': 'Otra foto', 'pl': 'Kolejne zdjęcie'};
const _speciesL = {'nl': 'Vissoort', 'en': 'Species', 'de': 'Fischart', 'fr': 'Espèce', 'es': 'Especie', 'pl': 'Gatunek'};
const _weightL = {'nl': 'Gewicht', 'en': 'Weight', 'de': 'Gewicht', 'fr': 'Poids', 'es': 'Peso', 'pl': 'Waga'};
const _lengthL = {'nl': 'Lengte (cm)', 'en': 'Length (cm)', 'de': 'Länge (cm)', 'fr': 'Longueur (cm)', 'es': 'Longitud (cm)', 'pl': 'Długość (cm)'};
const _baitL = {'nl': 'Aas / techniek', 'en': 'Bait / technique', 'de': 'Köder / Technik', 'fr': 'Appât / technique', 'es': 'Cebo / técnica', 'pl': 'Przynęta / technika'};
const _privacyL = {'nl': 'Zichtbaarheid', 'en': 'Visibility', 'de': 'Sichtbarkeit', 'fr': 'Visibilité', 'es': 'Visibilidad', 'pl': 'Widoczność'};
const _pubL = {'nl': 'Openbaar', 'en': 'Public', 'de': 'Öffentlich', 'fr': 'Public', 'es': 'Público', 'pl': 'Publiczny'};
const _friL = {'nl': 'Vrienden', 'en': 'Friends', 'de': 'Freunde', 'fr': 'Amis', 'es': 'Amigos', 'pl': 'Znajomi'};
const _priL = {'nl': 'Privé', 'en': 'Private', 'de': 'Privat', 'fr': 'Privé', 'es': 'Privado', 'pl': 'Prywatny'};
const _feedL = {'nl': 'In de feed tonen', 'en': 'Show in feed', 'de': 'Im Feed zeigen', 'fr': 'Afficher dans le fil', 'es': 'Mostrar en el feed', 'pl': 'Pokaż w kanale'};
const _finishL = {'nl': 'Vangst afronden', 'en': 'Finish catch', 'de': 'Fang abschließen', 'fr': 'Terminer la prise', 'es': 'Finalizar captura', 'pl': 'Zakończ połów'};
const _needSpecies = {'nl': 'Vul de vissoort in.', 'en': 'Enter the species.', 'de': 'Fischart eingeben.', 'fr': 'Espèce requise.', 'es': 'Indica la especie.', 'pl': 'Podaj gatunek.'};
const _selectHint = {'nl': 'Tik een foto om groot te bekijken · vink aan welke meegaan', 'en': 'Tap a photo to enlarge · tick which ones to keep', 'de': 'Foto antippen zum Vergrößern · markiere, welche mitkommen', 'fr': 'Touche une photo pour agrandir · coche celles à garder', 'es': 'Toca una foto para ampliar · marca cuáles conservar', 'pl': 'Dotknij zdjęcie, aby powiększyć · zaznacz, które zachować'};
const _needPhoto = {'nl': 'Selecteer minstens één foto voor je vangst.', 'en': 'Select at least one photo for your catch.', 'de': 'Wähle mindestens ein Foto für deinen Fang.', 'fr': 'Sélectionne au moins une photo pour ta prise.', 'es': 'Selecciona al menos una foto para tu captura.', 'pl': 'Wybierz co najmniej jedno zdjęcie do połowu.'};
const _camFail = {'nl': 'Camera openen mislukt', 'en': 'Failed to open camera', 'de': 'Kamera öffnen fehlgeschlagen', 'fr': 'Échec ouverture caméra', 'es': 'No se pudo abrir la cámara', 'pl': 'Nie udało się otworzyć aparatu'};
