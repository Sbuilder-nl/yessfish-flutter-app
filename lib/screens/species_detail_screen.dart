import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/api.dart';
import '../core/config.dart';
import '../core/i18n.dart';
import '../core/species_l10n.dart';

class SpeciesDetailScreen extends StatefulWidget {
  final int id;
  final String name;
  const SpeciesDetailScreen({super.key, required this.id, required this.name});
  @override
  State<SpeciesDetailScreen> createState() => _SpeciesDetailScreenState();
}

class _SpeciesDetailScreenState extends State<SpeciesDetailScreen> {
  Map? _s;
  bool _loading = true;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try { final r = await Api.get('/species/${widget.id}'); setState(() { _s = r is Map ? (r['data'] ?? r) : null; _loading = false; }); }
    catch (_) { setState(() => _loading = false); }
  }
  @override
  Widget build(BuildContext context) {
    final s = _s;
    return Scaffold(appBar: AppBar(title: Text(widget.name)),
      body: _loading ? const Center(child: CircularProgressIndicator()) : ListView(padding: const EdgeInsets.all(16), children: [
        if (s?['image_path'] != null) ClipRRect(borderRadius: BorderRadius.circular(14), child: CachedNetworkImage(imageUrl: s!['image_path'], width: double.infinity, fit: BoxFit.cover)),
        const SizedBox(height: 14),
        Text(s != null ? speciesName(context, s) : widget.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.navy)),
        if (s?['scientific_name'] != null) Text(s!['scientific_name'], style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black45)),
        if (s != null) _facts(context, s),
        const SizedBox(height: 12),
        if (s != null && speciesDescription(context, s).isNotEmpty) Text(speciesDescription(context, s), style: const TextStyle(fontSize: 15, height: 1.4)),
        const SizedBox(height: 16),
        Text(context.tr('speciesdetail.rules_disclaimer'), style: const TextStyle(fontSize: 12, color: Colors.black38)),
      ]));
  }

  // Feiten-blad: alleen de gevulde velden tonen, in de huidige taal.
  Widget _facts(BuildContext c, Map s) {
    String? kg() {
      final w = double.tryParse('${s['max_weight_kg']}');
      if (w == null) return null;
      return (w % 1 == 0 ? w.toInt().toString() : w.toString()) + ' kg';
    }
    final items = <Widget>[];
    void add(String label, String? val) { if (val != null && val.isNotEmpty) items.add(_chip(label, val)); }
    add(sui(c, 'family'), s['family']?.toString());
    add(sui(c, 'water'), waterTypeLabel(c, s['water_type']?.toString()));
    add(sui(c, 'maxlength'), s['max_length_cm'] != null ? '${s['max_length_cm']} cm' : null);
    add(sui(c, 'maxweight'), kg());
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(padding: const EdgeInsets.only(top: 14),
      child: Wrap(spacing: 8, runSpacing: 8, children: items));
  }

  Widget _chip(String label, String val) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(12)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
      Text(val, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.navy)),
    ]),
  );
}
