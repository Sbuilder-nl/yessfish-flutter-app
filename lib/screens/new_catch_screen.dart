import 'package:flutter/material.dart';
import '../core/rondleiding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:exif/exif.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import '../core/api.dart';
import '../widgets/soort_kiezer.dart';
import '../core/review.dart';
import '../core/analytics.dart';
import '../core/units.dart';
import '../core/config.dart';
import '../core/location.dart';
import 'package:provider/provider.dart';
import '../core/i18n.dart';

class NewCatchScreen extends StatefulWidget {
  const NewCatchScreen({super.key});
  @override
  State<NewCatchScreen> createState() => _NewCatchScreenState();
}

class _NewCatchScreenState extends State<NewCatchScreen> {
  final _species = TextEditingController();

  /// Gekozen soort uit de lijst. Zonder dit hangt de vangst aan geen enkele soort en telt hij
  /// niet mee in de soortstatistieken, records en visstijl-dashboards (20-09-2026).
  int? _speciesId;
  final _weight = TextEditingController();
  final _length = TextEditingController();
  final _bait = TextEditingController();
  final _aantal = TextEditingController();
  final List<_ExtraSoort> _extra = [];
  String _privacy = 'public';
  bool _showInFeed = true;
  bool _addLocation = true;
  DateTime _caughtAt = DateTime.now();
  int? _waterId;
  String? _waterName;
  final List<Map<String, String>> _photos = []; // {path, url}
  bool _uploading = false, _identifying = false, _saving = false;
  String? _aiTip;

  Future<void> _pick(ImageSource src) async {
    List<XFile> files = [];
    try {
      final picker = ImagePicker();
      if (src == ImageSource.gallery) {
        files = await picker.pickMultiImage(); // origineel (met EXIF-datum)
      } else {
        final x = await picker.pickImage(source: ImageSource.camera);
        if (x != null) files = [x];
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${src == ImageSource.camera ? context.tr('newcatch.openCameraFail') : context.tr('newcatch.openGalleryFail')}: $e')));
      return;
    }
    if (files.isEmpty) return;
    // Galerij-foto: probeer de opnamedatum (EXIF) → vult de vangst-datum automatisch in.
    bool exifFound = false;
    if (src == ImageSource.gallery) exifFound = await _readExifDate(files.first);
    setState(() => _uploading = true);
    try {
      for (final f in files) {
        final path = await _compress(f.path); // klein maken vóór upload (EXIF is al gelezen)
        final r = await Api.uploadImage(path);
        _photos.add({'path': r['path'].toString(), 'url': r['url'].toString()});
      }
      setState(() {});
      // Geen opnamedatum uit de foto → gebruiker laten weten dat hij datum + tijd zelf zet.
      if (src == ImageSource.gallery && !exifFound && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.tr('newcatch.no_exif_date')), duration: const Duration(seconds: 5)));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? '${context.tr('newcatch.uploadFail')}: ${e.message}' : '${context.tr('newcatch.uploadFail')}: $e'), duration: const Duration(seconds: 8)));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
    // Net als op de site: zodra er een foto is, kijkt de herkenning mee. Hij vult alleen een leeg
    // soortveld — wat jij zelf typte blijft staan.
    if (mounted && _photos.isNotEmpty) await _identify();
  }

  /// Herkenning op de foto. `forceer` = jij drukte op de knop: dan mag hij je eigen soort
  /// overschrijven. Vanzelf (na het toevoegen van een foto) laat hij ingevulde tekst staan —
  /// precies zoals op de site (23-09-2026).
  Future<void> _identify({bool forceer = false}) async {
    if (_photos.isEmpty || _identifying) return;
    setState(() { _identifying = true; _aiTip = null; });
    try {
      final r = await Api.post('/catches/identify', {'path': _photos.first['path']});
      Analytics.log('ai_identify');
      if (r['is_fish'] == true && r['species_nl'] != null) {
        final zelfIngevuld = _species.text.trim().isNotEmpty;
        setState(() {
          if (forceer || !zelfIngevuld) _species.text = r['species_nl'];
          // De herkenning geeft de soort er al bij; die koppelen we meteen, anders blijft het
          // alsnog vrije tekst en telt de vangst niet mee in de statistieken.
          if (forceer || !zelfIngevuld) _speciesId = (r['species_id'] as num?)?.toInt();
          final conf = ((r['confidence'] ?? 0) as num).round();
          _aiTip = '${r['species_nl']} ($conf% ${context.tr('newcatch.sure')})${r['tip'] != null ? '\n${r['tip']}' : ''}';
        });
      } else {
        setState(() => _aiTip = context.tr('newcatch.noFish'));
      }
    } catch (_) {
      setState(() => _aiTip = context.tr('newcatch.identifyFail'));
    } finally {
      if (mounted) setState(() => _identifying = false);
    }
  }

  // EXIF-opnamedatum lezen (formaat "YYYY:MM:DD HH:MM:SS") → vult de vangst-datum.
  // Geeft true als er een geldige opnamedatum uit de EXIF kwam.
  Future<bool> _readExifDate(XFile f) async {
    try {
      final tags = await readExifFromBytes(await f.readAsBytes());
      final t = tags['EXIF DateTimeOriginal'] ?? tags['Image DateTime'];
      if (t == null) return false;
      // "YYYY:MM:DD HH:MM:SS" — datum + (optioneel) tijd meenemen.
      final m = RegExp(r'^(\d{4}):(\d{2}):(\d{2})(?:[ T](\d{2}):(\d{2}))?').firstMatch(t.printable);
      if (m == null) return false;
      final d = DateTime(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!),
          m[4] != null ? int.parse(m[4]!) : 12, m[5] != null ? int.parse(m[5]!) : 0);
      if (d.isAfter(DateTime.now())) return false;
      setState(() => _caughtAt = d);
      return true;
    } catch (_) { return false; }
  }

  // Comprimeer een (origineel) foto vóór upload zodat de upload klein blijft.
  Future<String> _compress(String path) async {
    try {
      final dir = await getTemporaryDirectory();
      final target = '${dir.path}/yf_${DateTime.now().microsecondsSinceEpoch}.jpg';
      final out = await FlutterImageCompress.compressAndGetFile(path, target,
          minWidth: 1600, minHeight: 1600, quality: 85);
      return out?.path ?? path;
    } catch (_) { return path; }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _caughtAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_caughtAt));
    setState(() => _caughtAt = DateTime(d.year, d.month, d.day,
        t?.hour ?? _caughtAt.hour, t?.minute ?? _caughtAt.minute));
  }

  // Optioneel een viswater koppelen (ook voor oude vangsten). Zoekt via /waters?q=.
  Future<void> _pickWater() async {
    final search = TextEditingController();
    List results = [];
    bool busy = false;
    final picked = await showDialog<Map?>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
      Future<void> doSearch() async {
        final q = search.text.trim();
        if (q.length < 2) return;
        setS(() => busy = true);
        try {
          final r = await Api.get('/waters?q=${Uri.encodeComponent(q)}');
          final list = r is List ? r : (r['data'] ?? []);
          final seen = <String>{};
          results = [];
          for (final w in list) { final n = '${w['name']}'; if (n.isNotEmpty && seen.add(n)) results.add(w); }
        } catch (_) {}
        setS(() => busy = false);
      }
      return AlertDialog(
        scrollable: true,
        title: Text(context.tr('newcatch.water')),
        content: SizedBox(width: double.maxFinite, child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: search, autofocus: true,
            decoration: InputDecoration(hintText: context.tr('newcatch.water_search'),
              suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: doSearch)),
            onSubmitted: (_) => doSearch()),
          const SizedBox(height: 8),
          if (busy) const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()),
          Flexible(child: ListView(shrinkWrap: true, children: results.map((w) => ListTile(
            dense: true, title: Text('${w['name'] ?? ''}'),
            subtitle: w['country'] != null ? Text('${w['country']}') : null,
            onTap: () => Navigator.pop(ctx, Map<String, dynamic>.from(w)),
          )).toList())),
        ])),
        actions: [
          if (_waterId != null) TextButton(onPressed: () => Navigator.pop(ctx, <String, dynamic>{}), child: Text(context.tr('newcatch.water_clear'))),
          TextButton(onPressed: () => Navigator.pop(ctx, null), child: Text(context.tr('map.cancel'))),
        ],
      );
    }));
    if (picked == null) return;
    if (picked.isEmpty) { setState(() { _waterId = null; _waterName = null; }); return; }
    setState(() { _waterId = picked['id'] as int?; _waterName = picked['name']?.toString(); });
  }

  /// Alle soorten van deze sessie als regels voor de API: eerst de vaste velden, dan de extra's.
  /// Lege regels laten we weg — iemand die op "meer soorten" tikt en zich bedenkt hoort geen
  /// spookvangst in zijn visboek te krijgen.
  List<Map<String, dynamic>> _rijenVoorSessie() {
    final uit = <Map<String, dynamic>>[];
    void voegToe(String soort, String gewicht, String lengte, String aantal, String aas, int? soortId) {
      if (soort.trim().isEmpty) return;
      uit.add({
        'species_text': soort.trim(),
        if (soortId != null) 'species_id': soortId,
        'aantal': int.tryParse(aantal.trim()) ?? 1,
        if (gewicht.trim().isNotEmpty) 'weight_kg': Units.toKg(gewicht),
        if (lengte.trim().isNotEmpty) 'length_cm': double.tryParse(lengte.replaceAll(',', '.')),
        if (aas.trim().isNotEmpty) 'bait': aas.trim(),
      });
    }
    voegToe(_species.text, _weight.text, _length.text, _aantal.text, _bait.text, _speciesId);
    for (final e in _extra) {
      voegToe(e.soort.text, e.gewicht.text, e.lengte.text, e.aantal.text, '', e.soortId);
    }
    return uit;
  }

  /// Eén regel per extra vissoort. De eerste soort staat in de vaste velden hierboven.
  ///
  /// Waarom dit er is: op één sessie vang je zelden één vis. Twintig voorns en twee brasems in
  /// twintig losse meldingen invoeren doet niemand, dus die vangsten verdwenen uit het visboek.
  /// De API kent hiervoor /catches/sessie, met per regel een aantal (Richard 18/19-09-2026).
  Widget _extraSoorten() {
    final tekst = _t(context, const {
      'nl': 'Meer soorten gevangen?', 'en': 'Caught more species?', 'de': 'Mehr Arten gefangen?',
      'fr': 'D’autres espèces ?', 'es': '¿Más especies?', 'pl': 'Więcej gatunków?'});
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (var i = 0; i < _extra.length; i++) Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 6, 6, 10),
          decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
          child: Column(children: [
            Row(children: [
              Expanded(child: SoortKiezer(controller: _extra[i].soort, isDense: true,
                label: context.tr('newcatch.species'),
                onKies: (_, id) => _extra[i].soortId = id)),
              IconButton(
                tooltip: _t(context, const {'nl': 'Regel weghalen', 'en': 'Remove row', 'de': 'Zeile entfernen', 'fr': 'Retirer la ligne', 'es': 'Quitar fila', 'pl': 'Usuń wiersz'}),
                icon: const Icon(Icons.close, size: 20, color: Colors.black45),
                onPressed: () => setState(() { _extra[i].weg(); _extra.removeAt(i); })),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(child: TextField(controller: _extra[i].gewicht, keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: '${context.tr('newcatch.weight')} (${Units.label})', isDense: true))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _extra[i].lengte, keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: context.tr('newcatch.length'), isDense: true))),
              const SizedBox(width: 8),
              SizedBox(width: 86, child: _aantalVeld(_extra[i].aantal, _t(context, const {
                'nl': 'Aantal', 'en': 'Number', 'de': 'Anzahl', 'fr': 'Nombre', 'es': 'Cantidad', 'pl': 'Liczba'}))),
            ]),
          ]),
        ),
      ),
      Align(alignment: Alignment.centerLeft, child: TextButton.icon(
        onPressed: _extra.length >= 24 ? null : () => setState(() => _extra.add(_ExtraSoort())),
        icon: const Icon(Icons.add, size: 18),
        label: Text(tekst))),
      // Zo weet een lid wat hij bij gewicht moet invullen als hij er twintig ving.
      if (_extra.isNotEmpty || (int.tryParse(_aantal.text) ?? 1) > 1) Padding(
        padding: const EdgeInsets.only(top: 2, left: 4),
        child: Text(_t(context, const {
          'nl': 'Vul bij het gewicht dat van de zwaarste vis in.',
          'en': 'For weight, enter the heaviest fish.',
          'de': 'Beim Gewicht den schwersten Fisch eintragen.',
          'fr': 'Pour le poids, indique le plus lourd.',
          'es': 'En el peso, pon el más pesado.',
          'pl': 'W wadze wpisz najcięższą rybę.'}),
          style: const TextStyle(fontSize: 12, color: Colors.black54))),
    ]);
  }

  Widget _aantalVeld(TextEditingController c, String label) => TextField(
    controller: c,
    keyboardType: TextInputType.number,
    decoration: InputDecoration(labelText: label, isDense: true, hintText: '1'),
  );

  String _t(BuildContext c, Map<String, String> m) {
    final l = c.read<I18n>().locale;
    return m[l] ?? m['en'] ?? m['nl'] ?? '';
  }

  @override
  void dispose() {
    _species.dispose();
    _weight.dispose();
    _length.dispose();
    _bait.dispose();
    _aantal.dispose();
    for (final e in _extra) { e.weg(); }
    super.dispose();
  }

  Future<void> _save() async {
    if (_species.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('newcatch.enterSpecies'))));
      return;
    }
    setState(() => _saving = true);
    try {
      final body = <String, dynamic>{
        'species_text': _species.text.trim(),
        if (_speciesId != null) 'species_id': _speciesId,
        'privacy': _privacy,
        'show_in_feed': _privacy == 'public' && _showInFeed,
        'caught_at': _caughtAt.toIso8601String(),
        if (_waterId != null) 'water_id': _waterId,
        if (_weight.text.isNotEmpty) 'weight_kg': Units.toKg(_weight.text),
        if (_length.text.isNotEmpty) 'length_cm': double.tryParse(_length.text.replaceAll(',', '.')),
        if (_bait.text.isNotEmpty) 'bait': _bait.text.trim(),
        if (_photos.isNotEmpty) 'photo_paths': _photos.map((p) => p['path']).toList(),
      };
      if (_addLocation) {
        final loc = await currentLocation();
        body['latitude'] = loc.lat;
        body['longitude'] = loc.lng;
      }

      // Meerdere soorten of meer dan één vis → in één keer als sessie. De server maakt er dan
      // losse vangsten van met één gezamenlijk feedbericht, zodat de feed niet volloopt.
      final rijen = _rijenVoorSessie();
      if (rijen.length > 1) {
        final sessieBody = Map<String, dynamic>.from(body)
          ..remove('species_text')
          ..remove('weight_kg')
          ..remove('length_cm')
          ..remove('bait')
          ..remove('photo_paths');
        if (_photos.isNotEmpty) sessieBody['photo_path'] = _photos.first['path'];
        sessieBody['rijen'] = rijen;
        await Api.post('/catches/sessie', sessieBody);
        Analytics.log('catch_created');
        if (mounted) Navigator.pop(context, true);
        return;
      }
      if (rijen.length == 1 && (rijen.first['aantal'] as int) > 1) {
        body['aantal'] = rijen.first['aantal'];
      }
      final r = await Api.post('/catches', body);
      Analytics.log('catch_created');
      // Geen vis op de foto? Dan is het geen vangst: wel geplaatst, maar zonder dobbers en punten.
      // De server bepaalt dat; wij vertellen het alleen (23-09-2026).
      final gegevens = (r is Map) ? ((r['data'] is Map ? r['data'] : r) as Map) : const {};
      if (gegevens['telt_als_vangst'] == false && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.tr('newcatch.geenVisTelt')), duration: const Duration(seconds: 7)));
      }
      // Vriendelijke reminder: niet op de feed gedeeld → +1 dobber als je het alsnog doet.
      final gedeeld = _privacy == 'public' && _showInFeed;
      final catchId = (r is Map) ? ((r['data'] is Map ? r['data']['id'] : r['id'])) : null;
      if (!gedeeld && catchId != null && mounted) {
        final ja = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(scrollable: true,
          title: Text(ctx.tr('newcatch.shareYes')),
          content: SingleChildScrollView(child: Text(ctx.tr('newcatch.shareAsk'))),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.tr('newcatch.shareNo'))),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ctx.tr('newcatch.shareYes'))),
          ],
        ));
        if (ja == true) {
          try { await Api.put('/catches/$catchId', {'privacy': 'public', 'show_in_feed': true}); } on ApiException catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message))); }
        }
      }
      maybeAskReview();
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
      appBar: AppBar(title: Text(context.tr('newcatch.title'))),
      body: Column(children: [
        Expanded(child: ListView(padding: const EdgeInsets.all(16) + EdgeInsets.only(bottom: 16 + MediaQuery.of(context).padding.bottom), children: [
        if (_photos.isNotEmpty)
          SizedBox(height: 96, child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _photos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => Stack(children: [
              ClipRRect(borderRadius: BorderRadius.circular(10), child: CachedNetworkImage(imageUrl: _photos[i]['url']!, height: 96, width: 96, fit: BoxFit.cover)),
              Positioned(right: 2, top: 2, child: GestureDetector(
                onTap: () => setState(() => _photos.removeAt(i)),
                child: Container(decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), padding: const EdgeInsets.all(2), child: const Icon(Icons.close, size: 16, color: Colors.white)))),
            ]),
          )),
        if (_photos.isNotEmpty) const SizedBox(height: 8),
        TourAnker(id: 'vangst-foto', child: Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: _uploading ? null : () => _pick(ImageSource.camera), icon: const Icon(Icons.camera_alt), label: Text(context.tr('newcatch.camera')))),
          const SizedBox(width: 8),
          Expanded(child: OutlinedButton.icon(onPressed: _uploading ? null : () => _pick(ImageSource.gallery), icon: const Icon(Icons.photo), label: Text(context.tr('newcatch.gallery')))),
        ])),
        if (_uploading) const Padding(padding: EdgeInsets.all(8), child: LinearProgressIndicator()),
        // Altijd zichtbaar, grijs zolang er geen foto is: zo weet je dat de herkenning bestaat, en
        // kan de handleiding hem aanwijzen (die had hier in geen taal een plaatje, 22-09-2026).
        Padding(padding: const EdgeInsets.only(top: 8),
          child: TourAnker(id: 'vangst-ai', child: FilledButton.icon(onPressed: (_identifying || _photos.isEmpty) ? null : () => _identify(forceer: true),
            icon: _identifying ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.auto_awesome),
            label: Text(context.tr('newcatch.identify'))))),
        if (_aiTip != null) Padding(padding: const EdgeInsets.only(top: 8),
          child: Container(width: double.infinity, padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.teal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Text(_aiTip!, style: const TextStyle(fontSize: 13)))),
        const SizedBox(height: 14),
        SoortKiezer(controller: _species, label: context.tr('newcatch.species'),
          onKies: (_, id) => _speciesId = id),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: TextField(controller: _weight, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: '${context.tr('newcatch.weight')} (${Units.label})'))),
          const SizedBox(width: 10),
          Expanded(child: TextField(controller: _length, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: context.tr('newcatch.length')))),
        ]),
        const SizedBox(height: 8),
        _aantalVeld(_aantal, _t(context, const {
          'nl': 'Aantal', 'en': 'Number', 'de': 'Anzahl', 'fr': 'Nombre', 'es': 'Cantidad', 'pl': 'Liczba'})),
        const SizedBox(height: 12),
        TourAnker(id: 'vangst-meer', child: _extraSoorten()),
        const SizedBox(height: 12),
        TextField(controller: _bait, decoration: InputDecoration(labelText: context.tr('newcatch.bait'))),
        const SizedBox(height: 12),
        InkWell(
          onTap: _pickDate,
          child: InputDecorator(
            decoration: InputDecoration(labelText: context.tr('newcatch.date')),
            child: Row(children: [
              const Icon(Icons.event, size: 18, color: AppColors.teal),
              const SizedBox(width: 8),
              Expanded(child: Text('${MaterialLocalizations.of(context).formatMediumDate(_caughtAt)} · ${TimeOfDay.fromDateTime(_caughtAt).format(context)}')),
              const Icon(Icons.arrow_drop_down, color: Colors.black45),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        TourAnker(id: 'vangst-water', child: InkWell(
          onTap: _pickWater,
          child: InputDecorator(
            decoration: InputDecoration(labelText: context.tr('newcatch.water')),
            child: Row(children: [
              const Icon(Icons.water, size: 18, color: AppColors.teal),
              const SizedBox(width: 8),
              Expanded(child: Text(_waterName ?? context.tr('newcatch.water_none'),
                  style: TextStyle(color: _waterName == null ? Colors.black45 : null))),
              const Icon(Icons.arrow_drop_down, color: Colors.black45),
            ]),
          ),
        )),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _privacy,
          decoration: InputDecoration(labelText: context.tr('newcatch.visibility')),
          items: [
            DropdownMenuItem(value: 'public', child: Text(context.tr('newcatch.public'))),
            DropdownMenuItem(value: 'friends', child: Text(context.tr('newcatch.friends'))),
            DropdownMenuItem(value: 'private', child: Text(context.tr('newcatch.private'))),
          ],
          onChanged: (v) => setState(() => _privacy = v!),
        ),
        if (_privacy == 'public')
          TourAnker(id: 'vangst-zichtbaar', child: CheckboxListTile(
            value: _showInFeed,
            onChanged: (v) => setState(() => _showInFeed = v ?? true),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(context.tr('newcatch.showInFeed')),
            subtitle: Text(context.tr('newcatch.feedBonus'), style: const TextStyle(fontSize: 12, color: Color(0xFF1f8a70), fontWeight: FontWeight.w600)),
          )),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _addLocation,
          activeThumbColor: AppColors.teal,
          onChanged: (v) => setState(() => _addLocation = v),
          title: Text(context.tr('newcatch.addLocation')),
          subtitle: Text(context.tr('newcatch.addLocationSub')),
        ),
        const SizedBox(height: 12),
        ])),
        // Opslaan-knop schuift mee boven het toetsenbord — altijd bereikbaar, ook tijdens invullen.
        SafeArea(top: false, minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12), child: SizedBox(width: double.infinity, child: FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(context.tr('newcatch.save'))))),
      ]),
    );
  }
}

/// Eén extra vissoort in het vangstformulier: soort, gewicht, lengte en aantal.
class _ExtraSoort {
  final soort = TextEditingController();

  /// Gekozen soort uit de lijst (null als het lid zelf iets typte).
  int? soortId;
  final gewicht = TextEditingController();
  final lengte = TextEditingController();
  final aantal = TextEditingController();

  void weg() {
    soort.dispose();
    gewicht.dispose();
    lengte.dispose();
    aantal.dispose();
  }
}
