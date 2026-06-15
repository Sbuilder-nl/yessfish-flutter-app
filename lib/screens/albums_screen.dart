import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/config.dart';

class AlbumsScreen extends StatefulWidget {
  const AlbumsScreen({super.key});
  @override
  State<AlbumsScreen> createState() => _AlbumsScreenState();
}

class _AlbumsScreenState extends State<AlbumsScreen> {
  List _items = [];
  bool _loading = true;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try { final r = await Api.get('/albums'); setState(() { _items = r is List ? r : (r['data'] ?? []); _loading = false; }); }
    catch (_) { setState(() => _loading = false); }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Albums')),
      body: _loading ? const Center(child: CircularProgressIndicator()) : _items.isEmpty ? const Center(child: Text('Nog geen albums', style: TextStyle(color: Colors.black45))) : ListView.builder(
        padding: const EdgeInsets.all(12), itemCount: _items.length,
        itemBuilder: (_, i) { final a = _items[i] as Map; return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(leading: const Icon(Icons.photo_album, color: AppColors.teal), title: Text(a['title'] ?? ''), subtitle: Text('${a['photos_count'] ?? a['photos']?.length ?? 0} foto\x27s'))); }));
  }
}
