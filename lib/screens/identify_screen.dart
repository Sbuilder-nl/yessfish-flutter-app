import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/api.dart';
import '../core/config.dart';
import '../core/i18n.dart';
import 'species_detail_screen.dart';

/// Losse AI-visherkenning uit een foto (zoals op de website) — los van vangstregistratie.
class IdentifyScreen extends StatefulWidget {
  const IdentifyScreen({super.key});
  @override
  State<IdentifyScreen> createState() => _IdentifyScreenState();
}

class _IdentifyScreenState extends State<IdentifyScreen> {
  String? _photoPath, _photoUrl;
  bool _busy = false;
  Map? _result;
  String? _error;

  Future<void> _pickAndIdentify(ImageSource src) async {
    XFile? x;
    try { x = await ImagePicker().pickImage(source: src, maxWidth: 1600, imageQuality: 85); }
    catch (e) { if (mounted) setState(() => _error = '${context.tr(src == ImageSource.camera ? 'identify.camera_failed' : 'identify.gallery_failed')}: $e'); return; }
    if (x == null) return;
    setState(() { _busy = true; _result = null; _error = null; });
    try {
      final up = await Api.uploadImage(x.path);
      setState(() { _photoPath = up['path']; _photoUrl = up['url']; });
      final r = await Api.post('/catches/identify', {'path': _photoPath});
      setState(() => _result = r is Map ? r : null);
    } catch (e) {
      setState(() => _error = e is ApiException ? e.message : context.tr('identify.failed'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _result;
    final isFish = r?['is_fish'] == true;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('identify.title'))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text(context.tr('identify.intro'), style: const TextStyle(color: Colors.black54)),
        const SizedBox(height: 14),
        if (_photoUrl != null)
          ClipRRect(borderRadius: BorderRadius.circular(12), child: CachedNetworkImage(imageUrl: _photoUrl!, height: 220, width: double.infinity, fit: BoxFit.cover)),
        if (_photoUrl != null) const SizedBox(height: 10),
        Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: _busy ? null : () => _pickAndIdentify(ImageSource.camera), icon: const Icon(Icons.camera_alt), label: Text(context.tr('identify.camera')))),
          const SizedBox(width: 8),
          Expanded(child: OutlinedButton.icon(onPressed: _busy ? null : () => _pickAndIdentify(ImageSource.gallery), icon: const Icon(Icons.photo), label: Text(context.tr('identify.gallery')))),
        ]),
        if (_busy) Padding(padding: const EdgeInsets.all(16), child: Column(children: [const CircularProgressIndicator(), const SizedBox(height: 8), Text(context.tr('identify.identifying'), style: const TextStyle(color: Colors.black45))])),
        if (_error != null) Padding(padding: const EdgeInsets.only(top: 14),
          child: Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
            child: Text(_error!, style: const TextStyle(color: AppColors.danger)))),
        if (r != null && !_busy) Padding(padding: const EdgeInsets.only(top: 16), child: Card(child: Padding(padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(isFish ? Icons.set_meal : Icons.help_outline, color: isFish ? AppColors.teal : Colors.black38),
              const SizedBox(width: 8),
              Expanded(child: Text(isFish ? (r['species_nl'] ?? context.tr('identify.unknown_fish')) : context.tr('identify.no_fish'), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: AppColors.navy))),
            ]),
            if (isFish) ...[
              if ((r['species_scientific'] ?? '').toString().isNotEmpty)
                Text(r['species_scientific'], style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black54)),
              const SizedBox(height: 8),
              _confidenceBar(context, ((r['confidence'] ?? 0) as num).toDouble()),
              if ((r['alternatives'] as List?)?.isNotEmpty == true) Padding(padding: const EdgeInsets.only(top: 10),
                child: Text('${context.tr('identify.maybe_also')}: ${(r['alternatives'] as List).join(', ')}', style: const TextStyle(color: Colors.black54, fontSize: 13))),
              if ((r['tip'] ?? '').toString().isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10),
                child: Container(width: double.infinity, padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.teal.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                  child: Text('💡 ${r['tip']}', style: const TextStyle(fontSize: 13)))),
              if (r['species_id'] != null) Padding(padding: const EdgeInsets.only(top: 10),
                child: FilledButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SpeciesDetailScreen(id: r['species_id'], name: (r['species_nl'] ?? '').toString()))),
                  icon: const Icon(Icons.menu_book), label: Text(context.tr('identify.view_in_guide')))),
            ] else Text(context.tr('identify.try_clear_photo'), style: const TextStyle(color: Colors.black54)),
          ]))) ),
      ]),
    );
  }

  Widget _confidenceBar(BuildContext context, double pct) {
    final v = (pct.clamp(0, 100)) / 100.0;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('${context.tr('identify.confidence')}: ${pct.round()}%', style: const TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: v, minHeight: 8, backgroundColor: AppColors.bg, color: AppColors.teal)),
    ]);
  }
}
