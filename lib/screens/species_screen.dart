import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/api.dart';
import '../core/config.dart';
import 'species_detail_screen.dart';
import '../core/i18n.dart';

class SpeciesScreen extends StatefulWidget {
  const SpeciesScreen({super.key});
  @override
  State<SpeciesScreen> createState() => _SpeciesScreenState();
}

class _SpeciesScreenState extends State<SpeciesScreen> {
  List _list = [];
  bool _loading = true;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try { final r = await Api.get('/species'); setState(() { _list = r is List ? r : (r['data'] ?? []); _loading = false; }); }
    catch (_) { setState(() => _loading = false); }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text(context.tr('species.title'))),
      body: _loading ? const Center(child: CircularProgressIndicator()) : GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.82, crossAxisSpacing: 10, mainAxisSpacing: 10),
        itemCount: _list.length,
        itemBuilder: (_, i) {
          final s = _list[i] as Map;
          return Card(clipBehavior: Clip.antiAlias, child: InkWell(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SpeciesDetailScreen(id: s['id'], name: s['name_nl'] ?? s['name'] ?? ''))), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(child: s['image_path'] != null
              ? CachedNetworkImage(imageUrl: s['image_path'], fit: BoxFit.cover, errorWidget: (_, __, ___) => const ColoredBox(color: AppColors.bg, child: Icon(Icons.set_meal, color: AppColors.teal)))
              : const ColoredBox(color: AppColors.bg, child: Icon(Icons.set_meal, color: AppColors.teal, size: 40))),
            Padding(padding: const EdgeInsets.all(8), child: Text(s['name_nl'] ?? s['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
          ])));
        }));
  }
}
