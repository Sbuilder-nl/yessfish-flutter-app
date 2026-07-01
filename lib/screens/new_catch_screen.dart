import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:exif/exif.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import '../core/api.dart';
import '../core/analytics.dart';
import '../core/config.dart';
import '../core/location.dart';
import '../core/i18n.dart';

class NewCatchScreen extends StatefulWidget {
  const NewCatchScreen({super.key});
  @override
  State<NewCatchScreen> createState() => _NewCatchScreenState();
}

class _NewCatchScreenState extends State<NewCatchScreen> {
  final _species = TextEditingController();
  final _weight = TextEditingController();
  final _length = TextEditingController();
  final _bait = TextEditingController();
  String _privacy = 'public';
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
    if (src == ImageSource.gallery) await _readExifDate(files.first);
    setState(() => _uploading = true);
    try {
      for (final f in files) {
        final path = await _compress(f.path); // klein maken vóór upload (EXIF is al gelezen)
        final r = await Api.uploadImage(path);
        _photos.add({'path': r['path'].toString(), 'url': r['url'].toString()});
      }
      setState(() {});
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? '${context.tr('newcatch.uploadFail')}: ${e.message}' : '${context.tr('newcatch.uploadFail')}: $e'), duration: const Duration(seconds: 8)));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _identify() async {
    if (_photos.isEmpty) return;
    setState(() { _identifying = true; _aiTip = null; });
    try {
      final r = await Api.post('/catches/identify', {'path': _photos.first['path']});
      Analytics.log('ai_identify');
      if (r['is_fish'] == true && r['species_nl'] != null) {
        setState(() {
          _species.text = r['species_nl'];
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
  Future<void> _readExifDate(XFile f) async {
    try {
      final tags = await readExifFromBytes(await f.readAsBytes());
      final t = tags['EXIF DateTimeOriginal'] ?? tags['Image DateTime'];
      if (t == null) return;
      final m = RegExp(r'^(\d{4}):(\d{2}):(\d{2})').firstMatch(t.printable);
      if (m == null) return;
      final d = DateTime(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!), 12);
      if (!d.isAfter(DateTime.now())) setState(() => _caughtAt = d);
    } catch (_) {}
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
    if (d != null) setState(() => _caughtAt = DateTime(d.year, d.month, d.day, 12));
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

  Future<void> _save() async {
    if (_species.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('newcatch.enterSpecies'))));
      return;
    }
    setState(() => _saving = true);
    try {
      final body = <String, dynamic>{
        'species_text': _species.text.trim(),
        'privacy': _privacy,
        'caught_at': _caughtAt.toIso8601String(),
        if (_waterId != null) 'water_id': _waterId,
        if (_weight.text.isNotEmpty) 'weight_kg': double.tryParse(_weight.text.replaceAll(',', '.')),
        if (_length.text.isNotEmpty) 'length_cm': double.tryParse(_length.text.replaceAll(',', '.')),
        if (_bait.text.isNotEmpty) 'bait': _bait.text.trim(),
        if (_photos.isNotEmpty) 'photo_paths': _photos.map((p) => p['path']).toList(),
      };
      if (_addLocation) {
        final loc = await currentLocation();
        body['latitude'] = loc.lat;
        body['longitude'] = loc.lng;
      }
      await Api.post('/catches', body);
      Analytics.log('catch_created');
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
      body: ListView(padding: const EdgeInsets.all(16), children: [
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
        Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: _uploading ? null : () => _pick(ImageSource.camera), icon: const Icon(Icons.camera_alt), label: Text(context.tr('newcatch.camera')))),
          const SizedBox(width: 8),
          Expanded(child: OutlinedButton.icon(onPressed: _uploading ? null : () => _pick(ImageSource.gallery), icon: const Icon(Icons.photo), label: Text(context.tr('newcatch.gallery')))),
        ]),
        if (_uploading) const Padding(padding: EdgeInsets.all(8), child: LinearProgressIndicator()),
        if (_photos.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8),
          child: FilledButton.icon(onPressed: _identifying ? null : _identify,
            icon: _identifying ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.auto_awesome),
            label: Text(context.tr('newcatch.identify')))),
        if (_aiTip != null) Padding(padding: const EdgeInsets.only(top: 8),
          child: Container(width: double.infinity, padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.teal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Text(_aiTip!, style: const TextStyle(fontSize: 13)))),
        const SizedBox(height: 14),
        TextField(controller: _species, decoration: InputDecoration(labelText: context.tr('newcatch.species'))),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: TextField(controller: _weight, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: context.tr('newcatch.weight')))),
          const SizedBox(width: 10),
          Expanded(child: TextField(controller: _length, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: context.tr('newcatch.length')))),
        ]),
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
              Expanded(child: Text(MaterialLocalizations.of(context).formatFullDate(_caughtAt))),
              const Icon(Icons.arrow_drop_down, color: Colors.black45),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
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
        ),
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
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _addLocation,
          activeThumbColor: AppColors.teal,
          onChanged: (v) => setState(() => _addLocation = v),
          title: Text(context.tr('newcatch.addLocation')),
          subtitle: Text(context.tr('newcatch.addLocationSub')),
        ),
        const SizedBox(height: 12),
        FilledButton(onPressed: _saving ? null : _save,
          child: _saving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(context.tr('newcatch.save'))),
      ]),
    );
  }
}
