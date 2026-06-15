import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/api.dart';
import '../core/config.dart';
import '../core/location.dart';

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
  String? _photoPath;
  String? _photoUrl;
  bool _uploading = false, _identifying = false, _saving = false;
  String? _aiTip;

  Future<void> _pick(ImageSource src) async {
    final x = await ImagePicker().pickImage(source: src, maxWidth: 1600, imageQuality: 85);
    if (x == null) return;
    setState(() => _uploading = true);
    try {
      final r = await Api.uploadImage(x.path);
      setState(() { _photoPath = r['path']; _photoUrl = r['url']; });
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload mislukt')));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _identify() async {
    if (_photoPath == null) return;
    setState(() { _identifying = true; _aiTip = null; });
    try {
      final r = await Api.post('/catches/identify', {'photo_path': _photoPath});
      if (r['is_fish'] == true && r['species_nl'] != null) {
        setState(() {
          _species.text = r['species_nl'];
          final conf = ((r['confidence'] ?? 0) as num).round();
          _aiTip = '${r['species_nl']} ($conf% zeker)${r['tip'] != null ? '\n${r['tip']}' : ''}';
        });
      } else {
        setState(() => _aiTip = 'Geen vis herkend op de foto.');
      }
    } catch (_) {
      setState(() => _aiTip = 'Herkenning mislukt.');
    } finally {
      if (mounted) setState(() => _identifying = false);
    }
  }

  Future<void> _save() async {
    if (_species.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vul een vissoort in')));
      return;
    }
    setState(() => _saving = true);
    try {
      final body = <String, dynamic>{
        'species_text': _species.text.trim(),
        'privacy': _privacy,
        if (_weight.text.isNotEmpty) 'weight_kg': double.tryParse(_weight.text.replaceAll(',', '.')),
        if (_length.text.isNotEmpty) 'length_cm': double.tryParse(_length.text.replaceAll(',', '.')),
        if (_bait.text.isNotEmpty) 'bait': _bait.text.trim(),
        if (_photoPath != null) 'photo_path': _photoPath,
      };
      if (_addLocation) {
        final loc = await currentLocation();
        body['latitude'] = loc.lat;
        body['longitude'] = loc.lng;
      }
      await Api.post('/catches', body);
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
      appBar: AppBar(title: const Text('Nieuwe vangst')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        if (_photoUrl != null)
          ClipRRect(borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(imageUrl: _photoUrl!, height: 200, width: double.infinity, fit: BoxFit.cover)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: _uploading ? null : () => _pick(ImageSource.camera), icon: const Icon(Icons.camera_alt), label: const Text('Camera'))),
          const SizedBox(width: 8),
          Expanded(child: OutlinedButton.icon(onPressed: _uploading ? null : () => _pick(ImageSource.gallery), icon: const Icon(Icons.photo), label: const Text('Galerij'))),
        ]),
        if (_uploading) const Padding(padding: EdgeInsets.all(8), child: LinearProgressIndicator()),
        if (_photoPath != null) Padding(padding: const EdgeInsets.only(top: 8),
          child: FilledButton.icon(onPressed: _identifying ? null : _identify,
            icon: _identifying ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.auto_awesome),
            label: const Text('Herken vis (AI)'))),
        if (_aiTip != null) Padding(padding: const EdgeInsets.only(top: 8),
          child: Container(width: double.infinity, padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.teal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Text(_aiTip!, style: const TextStyle(fontSize: 13)))),
        const SizedBox(height: 14),
        TextField(controller: _species, decoration: const InputDecoration(labelText: 'Vissoort')),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: TextField(controller: _weight, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Gewicht (kg)'))),
          const SizedBox(width: 10),
          Expanded(child: TextField(controller: _length, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Lengte (cm)'))),
        ]),
        const SizedBox(height: 12),
        TextField(controller: _bait, decoration: const InputDecoration(labelText: 'Aas / techniek')),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _privacy,
          decoration: const InputDecoration(labelText: 'Zichtbaarheid'),
          items: const [
            DropdownMenuItem(value: 'public', child: Text('Openbaar')),
            DropdownMenuItem(value: 'friends', child: Text('Alleen vrienden')),
            DropdownMenuItem(value: 'private', child: Text('Privé')),
          ],
          onChanged: (v) => setState(() => _privacy = v!),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _addLocation,
          activeThumbColor: AppColors.teal,
          onChanged: (v) => setState(() => _addLocation = v),
          title: const Text('Locatie toevoegen'),
          subtitle: const Text('Voor de stekkenkaart + bijtkans in de buurt'),
        ),
        const SizedBox(height: 12),
        FilledButton(onPressed: _saving ? null : _save,
          child: _saving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Vangst opslaan')),
      ]),
    );
  }
}
