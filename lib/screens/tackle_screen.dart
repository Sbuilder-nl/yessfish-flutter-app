import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/config.dart';

class TackleScreen extends StatefulWidget {
  const TackleScreen({super.key});
  @override
  State<TackleScreen> createState() => _TackleScreenState();
}

class _TackleScreenState extends State<TackleScreen> {
  List _items = [];
  bool _loading = true;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try { final r = await Api.get('/tackle'); setState(() { _items = r is List ? r : (r['data'] ?? []); _loading = false; }); }
    catch (_) { setState(() => _loading = false); }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Uitrusting')),
      body: _loading ? const Center(child: CircularProgressIndicator()) : _items.isEmpty ? const Center(child: Text('Nog geen uitrusting', style: TextStyle(color: Colors.black45))) : ListView.builder(
        padding: const EdgeInsets.all(12), itemCount: _items.length,
        itemBuilder: (_, i) { final t = _items[i] as Map; return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(leading: const Icon(Icons.phishing, color: AppColors.teal), title: Text(t['name'] ?? ''), subtitle: Text([t['category'], if (t['setup'] != null) t['setup']].where((e) => e != null).join(' · ')))); }));
  }
}
