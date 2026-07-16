import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import '../core/api.dart';
import '../core/location.dart';
import '../core/config.dart';

/// Snelle stek toevoegen op je GPS-locatie, met een foto en eigen notitie.
class QuickSpotScreen extends StatefulWidget {
  const QuickSpotScreen({super.key});
  @override
  State<QuickSpotScreen> createState() => _QuickSpotScreenState();
}

class _QuickSpotScreenState extends State<QuickSpotScreen> {
  final _name = TextEditingController();
  final _notes = TextEditingController();
  String _privacy = 'friends';
  Map<String, dynamic>? _photo; // {path, url}
  LatLng? _loc;
  bool _locating = true, _saving = false, _uploading = false;
  String? _waterName;   // dichtstbijzijnd bekend viswater op deze plek
  bool? _spotAllowed;   // mag hier een stek? (check vooraf, niet pas bij opslaan)

  String get _lang => Localizations.localeOf(context).languageCode;
  String _t(Map<String, String> m) => m[_lang] ?? m['en'] ?? m['nl'] ?? '';

  @override
  void initState() {
    super.initState();
    _getLoc();
  }

  Future<void> _getLoc() async {
    setState(() { _locating = true; _waterName = null; _spotAllowed = null; });
    try { final l = await currentLocation(); if (l.isReal) _loc = l; } catch (_) {}
    if (mounted) setState(() => _locating = false);
    // Meteen checken of hier een bekend viswater is — zo weet je het VOOR het invullen.
    if (_loc != null) {
      try {
        final r = await Api.get('/spots/check-water?lat=${_loc!.lat}&lng=${_loc!.lng}');
        if (r is Map && mounted) setState(() { _spotAllowed = r['allowed'] == true; _waterName = r['water_name']?.toString(); });
      } catch (_) {}
    }
  }

  Future<String> _compress(String path) async {
    try {
      final dir = await getTemporaryDirectory();
      final target = '${dir.path}/yf_${DateTime.now().microsecondsSinceEpoch}.jpg';
      final out = await FlutterImageCompress.compressAndGetFile(path, target, minWidth: 1600, minHeight: 1600, quality: 85);
      return out?.path ?? path;
    } catch (_) { return path; }
  }

  Future<void> _pick(ImageSource src) async {
    XFile? x;
    try { x = await ImagePicker().pickImage(source: src); } catch (_) { return; }
    if (x == null) return;
    setState(() => _uploading = true);
    try {
      final up = await Api.uploadImage(await _compress(x.path));
      _photo = {'path': up['path'].toString(), 'url': up['url'].toString()};
    } catch (_) {} finally { if (mounted) setState(() => _uploading = false); }
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t(_needName))));
      return;
    }
    if (_loc == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t(_noLoc))));
      return;
    }
    setState(() => _saving = true);
    try {
      final r = await Api.post('/spots', {
        'name': _name.text.trim(),
        'latitude': _loc!.lat,
        'longitude': _loc!.lng,
        'privacy': _privacy,
        if (_notes.text.trim().isNotEmpty) 'notes': _notes.text.trim(),
      });
      final id = r is Map ? r['id'] : null;
      if (id != null && _photo != null) {
        try { await Api.post('/spots/$id/media', {'type': 'photo', 'path': _photo!['path']}); } catch (_) {}
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t(_saved))));
        Navigator.pop(context, true);
      }
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
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.teal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Icon(_locating ? Icons.gps_not_fixed : (_loc == null || _spotAllowed == false ? Icons.gps_off : Icons.gps_fixed),
                color: _loc == null || _spotAllowed == false ? Colors.orange : AppColors.teal),
            const SizedBox(width: 8),
            Expanded(child: Text(
              _locating ? _t(_locating2)
                : _loc == null ? _t(_noLocHint)
                : _spotAllowed == false ? _t(_noWaterHere)
                : _waterName != null ? '${_t(_atWater)} $_waterName'
                : _t(_locOk),
              style: const TextStyle(fontSize: 12.5))),
            if (!_locating) IconButton(icon: const Icon(Icons.refresh, size: 18, color: AppColors.teal), tooltip: _t(_retryL), onPressed: _getLoc),
          ]),
        ),
        const SizedBox(height: 12),
        TextField(controller: _name, decoration: InputDecoration(labelText: _t(_nameL))),
        const SizedBox(height: 12),
        TextField(controller: _notes, maxLines: 3, decoration: InputDecoration(labelText: _t(_notesL))),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _privacy,
          decoration: InputDecoration(labelText: _t(_privacyL)),
          items: [
            DropdownMenuItem(value: 'private', child: Text(_t(_priL))),
            DropdownMenuItem(value: 'friends', child: Text(_t(_friL))),
            DropdownMenuItem(value: 'public', child: Text(_t(_pubL))),
          ],
          onChanged: (v) => setState(() => _privacy = v ?? 'friends'),
        ),
        const SizedBox(height: 12),
        if (_photo != null)
          ClipRRect(borderRadius: BorderRadius.circular(10), child: CachedNetworkImage(imageUrl: '${_photo!['url']}', height: 120, fit: BoxFit.cover)),
        if (_uploading) const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: LinearProgressIndicator()),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: _uploading ? null : () => _pick(ImageSource.camera), icon: const Icon(Icons.camera_alt), label: Text(_t(_camL)))),
          const SizedBox(width: 8),
          Expanded(child: OutlinedButton.icon(onPressed: _uploading ? null : () => _pick(ImageSource.gallery), icon: const Icon(Icons.photo), label: Text(_t(_galL)))),
        ]),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.push_pin),
          label: Text(_t(_saveL)),
        ),
      ]),
    );
  }
}

const _title = {'nl': 'Nieuwe stek', 'en': 'New spot', 'de': 'Neue Stelle', 'fr': 'Nouveau spot', 'es': 'Nuevo spot', 'pl': 'Nowe miejsce'};
const _locating2 = {'nl': 'Locatie bepalen…', 'en': 'Getting location…', 'de': 'Standort wird ermittelt…', 'fr': 'Localisation…', 'es': 'Ubicando…', 'pl': 'Ustalanie lokalizacji…'};
const _locOk = {'nl': 'Stek komt op je huidige GPS-locatie.', 'en': 'Spot will be placed at your current GPS location.', 'de': 'Stelle wird an deinem GPS-Standort gesetzt.', 'fr': 'Le spot sera placé à ta position GPS.', 'es': 'El spot se colocará en tu ubicación GPS.', 'pl': 'Miejsce w Twojej lokalizacji GPS.'};
const _noLocHint = {'nl': 'Geen GPS. Zet locatie aan en tik op vernieuwen — of gebruik de kaart (Stek hier).', 'en': 'No GPS. Turn on location and tap refresh — or use the map (Spot here).', 'de': 'Kein GPS. Standort aktivieren und aktualisieren — oder die Karte nutzen (Stelle hier).', 'fr': 'Pas de GPS. Activez la localisation et actualisez — ou utilisez la carte (Spot ici).', 'es': 'Sin GPS. Activa la ubicación y actualiza — o usa el mapa (Spot aquí).', 'pl': 'Brak GPS. Włącz lokalizację i odśwież — lub użyj mapy (Miejsce tutaj).'};
const _noWaterHere = {'nl': 'Hier is geen bekend viswater. Sta je echt aan het water? Voeg het water dan eerst toe via de kaart.', 'en': 'No known fishing water here. At the waterside? Add the water first via the map.', 'de': 'Hier ist kein bekanntes Angelgewässer. Am Wasser? Füge das Gewässer zuerst über die Karte hinzu.', 'fr': "Pas d'eau de pêche connue ici. Au bord de l'eau ? Ajoutez d'abord l'eau via la carte.", 'es': 'No hay agua de pesca conocida aquí. ¿Junto al agua? Añade primero el agua desde el mapa.', 'pl': 'Brak znanej wody w tym miejscu. Nad wodą? Najpierw dodaj wodę na mapie.'};
const _atWater = {'nl': 'Stek komt bij:', 'en': 'Spot will be at:', 'de': 'Stelle kommt bei:', 'fr': 'Spot placé à :', 'es': 'Spot junto a:', 'pl': 'Miejsce przy:'};
const _retryL = {'nl': 'Locatie vernieuwen', 'en': 'Refresh location', 'de': 'Standort aktualisieren', 'fr': 'Actualiser la position', 'es': 'Actualizar ubicación', 'pl': 'Odśwież lokalizację'};
const _noLoc = {'nl': 'Geen GPS-locatie beschikbaar.', 'en': 'No GPS location available.', 'de': 'Kein GPS-Standort verfügbar.', 'fr': 'Position GPS indisponible.', 'es': 'Sin ubicación GPS.', 'pl': 'Brak lokalizacji GPS.'};
const _nameL = {'nl': 'Naam van de stek', 'en': 'Spot name', 'de': 'Name der Stelle', 'fr': 'Nom du spot', 'es': 'Nombre del spot', 'pl': 'Nazwa miejsca'};
const _notesL = {'nl': 'Notitie (diepte, aas, tips…)', 'en': 'Note (depth, bait, tips…)', 'de': 'Notiz (Tiefe, Köder, Tipps…)', 'fr': 'Note (profondeur, appât…)', 'es': 'Nota (profundidad, cebo…)', 'pl': 'Notatka (głębokość, przynęta…)'};
const _privacyL = {'nl': 'Zichtbaarheid', 'en': 'Visibility', 'de': 'Sichtbarkeit', 'fr': 'Visibilité', 'es': 'Visibilidad', 'pl': 'Widoczność'};
const _priL = {'nl': 'Privé', 'en': 'Private', 'de': 'Privat', 'fr': 'Privé', 'es': 'Privado', 'pl': 'Prywatny'};
const _friL = {'nl': 'Vrienden', 'en': 'Friends', 'de': 'Freunde', 'fr': 'Amis', 'es': 'Amigos', 'pl': 'Znajomi'};
const _pubL = {'nl': 'Openbaar', 'en': 'Public', 'de': 'Öffentlich', 'fr': 'Public', 'es': 'Público', 'pl': 'Publiczny'};
const _camL = {'nl': 'Camera', 'en': 'Camera', 'de': 'Kamera', 'fr': 'Caméra', 'es': 'Cámara', 'pl': 'Aparat'};
const _galL = {'nl': 'Galerij', 'en': 'Gallery', 'de': 'Galerie', 'fr': 'Galerie', 'es': 'Galería', 'pl': 'Galeria'};
const _needName = {'nl': 'Geef de stek een naam.', 'en': 'Give the spot a name.', 'de': 'Gib der Stelle einen Namen.', 'fr': 'Donne un nom au spot.', 'es': 'Ponle nombre al spot.', 'pl': 'Nadaj nazwę miejscu.'};
const _saved = {'nl': 'Stek opgeslagen ✓', 'en': 'Spot saved ✓', 'de': 'Stelle gespeichert ✓', 'fr': 'Spot enregistré ✓', 'es': 'Spot guardado ✓', 'pl': 'Miejsce zapisane ✓'};
const _saveL = {'nl': 'Stek opslaan', 'en': 'Save spot', 'de': 'Stelle speichern', 'fr': 'Enregistrer', 'es': 'Guardar spot', 'pl': 'Zapisz miejsce'};
