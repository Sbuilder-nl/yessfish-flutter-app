import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
  final List<Map<String, String>> _photos = []; // {path, url}
  bool _uploading = false, _identifying = false, _saving = false;
  String? _aiTip;

  Future<void> _pick(ImageSource src) async {
    List<XFile> files = [];
    try {
      final picker = ImagePicker();
      if (src == ImageSource.gallery) {
        files = await picker.pickMultiImage(maxWidth: 1600, imageQuality: 85);
      } else {
        final x = await picker.pickImage(source: ImageSource.camera, maxWidth: 1600, imageQuality: 85);
        if (x != null) files = [x];
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${src == ImageSource.camera ? context.tr('newcatch.openCameraFail') : context.tr('newcatch.openGalleryFail')}: $e')));
      return;
    }
    if (files.isEmpty) return;
    setState(() => _uploading = true);
    try {
      for (final f in files) {
        final r = await Api.uploadImage(f.path);
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

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _caughtAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => _caughtAt = DateTime(d.year, d.month, d.day, 12));
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
