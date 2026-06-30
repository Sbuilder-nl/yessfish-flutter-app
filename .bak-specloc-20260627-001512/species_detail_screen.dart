import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/api.dart';
import '../core/config.dart';
import '../core/i18n.dart';

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
        Text(s?['name_nl'] ?? widget.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.navy)),
        if (s?['scientific_name'] != null) Text(s!['scientific_name'], style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black45)),
        const SizedBox(height: 12),
        if (s?['description'] != null) Text(s!['description'], style: const TextStyle(fontSize: 15, height: 1.4)),
        const SizedBox(height: 16),
        Text(context.tr('speciesdetail.rules_disclaimer'), style: const TextStyle(fontSize: 12, color: Colors.black38)),
      ]));
  }
}
