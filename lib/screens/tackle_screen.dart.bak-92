import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/config.dart';
import '../core/i18n.dart';

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
    setState(() => _loading = true);
    try { final r = await Api.get('/tackle'); setState(() { _items = r is List ? r : (r['data'] ?? []); _loading = false; }); }
    catch (_) { setState(() => _loading = false); }
  }

  Future<void> _create() async {
    final name = TextEditingController();
    final brand = TextEditingController();
    final setup = TextEditingController();
    String category = 'Hengel';
    final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      title: Text(context.tr('tackle.add_title')),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: InputDecoration(labelText: context.tr('tackle.name'))),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(initialValue: category, decoration: InputDecoration(labelText: context.tr('tackle.category')),
          items: [
            DropdownMenuItem(value: 'Hengel', child: Text(context.tr('tackle.cat_rod'))),
            DropdownMenuItem(value: 'Molen', child: Text(context.tr('tackle.cat_reel'))),
            DropdownMenuItem(value: 'Lijn', child: Text(context.tr('tackle.cat_line'))),
            DropdownMenuItem(value: 'Aas', child: Text(context.tr('tackle.cat_bait'))),
            DropdownMenuItem(value: 'Accessoire', child: Text(context.tr('tackle.cat_accessory'))),
            DropdownMenuItem(value: 'Overig', child: Text(context.tr('tackle.cat_other'))),
          ],
          onChanged: (v) => setS(() => category = v!)),
        const SizedBox(height: 8),
        TextField(controller: brand, decoration: InputDecoration(labelText: context.tr('tackle.brand'))),
        const SizedBox(height: 8),
        TextField(controller: setup, decoration: InputDecoration(labelText: context.tr('tackle.setup'))),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('tackle.cancel'))), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.tr('tackle.add')))],
    )));
    if (ok != true || name.text.trim().isEmpty) return;
    final m = ScaffoldMessenger.of(context);
    try {
      await Api.post('/tackle', {
        'name': name.text.trim(),
        'category': category,
        if (brand.text.trim().isNotEmpty) 'brand': brand.text.trim(),
        if (setup.text.trim().isNotEmpty) 'setup': setup.text.trim(),
      });
      await _load();
    } catch (e) { m.showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : context.tr('tackle.add_failed')))); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text(context.tr('tackle.title'))),
      floatingActionButton: FloatingActionButton.extended(backgroundColor: AppColors.teal, onPressed: _create, icon: const Icon(Icons.add, color: Colors.white), label: Text(context.tr('tackle.add'), style: const TextStyle(color: Colors.white))),
      body: _loading ? const Center(child: CircularProgressIndicator()) : _items.isEmpty ? Center(child: Text(context.tr('tackle.empty'), style: const TextStyle(color: Colors.black45))) : RefreshIndicator(onRefresh: _load, child: ListView.builder(
        padding: const EdgeInsets.all(12), itemCount: _items.length,
        itemBuilder: (_, i) { final t = _items[i] as Map; return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(leading: const Icon(Icons.phishing, color: AppColors.teal), title: Text(t['name'] ?? ''), subtitle: Text([t['category'], if (t['setup'] != null) t['setup']].where((e) => e != null).join(' · ')))); })));
  }
}
