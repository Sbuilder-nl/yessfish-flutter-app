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

  // Toevoegen (item == null) of bewerken (item != null).
  Future<void> _form([Map? item]) async {
    final editing = item != null;
    final name = TextEditingController(text: editing ? (item['name']?.toString() ?? '') : '');
    final brand = TextEditingController(text: editing ? (item['brand']?.toString() ?? '') : '');
    final setup = TextEditingController(text: editing ? (item['setup']?.toString() ?? '') : '');
    const cats = ['Hengel', 'Molen', 'Lijn', 'Aas', 'Accessoire', 'Overig'];
    String category = (editing && cats.contains(item['category'])) ? item['category'] as String : 'Hengel';
    final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      title: Text(editing ? context.tr('p.edit') : context.tr('tackle.add_title')),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
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
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('tackle.cancel'))),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(editing ? context.tr('map.save') : context.tr('tackle.add'))),
      ],
    )));
    if (ok != true || name.text.trim().isEmpty) return;
    final m = ScaffoldMessenger.of(context);
    final payload = {
      'name': name.text.trim(),
      'category': category,
      if (brand.text.trim().isNotEmpty) 'brand': brand.text.trim(),
      if (setup.text.trim().isNotEmpty) 'setup': setup.text.trim(),
    };
    try {
      if (editing) {
        await Api.put('/tackle/${item['id']}', payload);
      } else {
        await Api.post('/tackle', payload);
      }
      await _load();
    } catch (e) { m.showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : context.tr('tackle.add_failed')))); }
  }

  Future<void> _delete(Map t) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(context.tr('settings.delete')),
      content: Text(t['name']?.toString() ?? ''),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('tackle.cancel'))),
        FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true), child: Text(context.tr('settings.delete'))),
      ],
    ));
    if (ok != true) return;
    final m = ScaffoldMessenger.of(context);
    try { await Api.delete('/tackle/${t['id']}'); await _load(); }
    catch (e) { m.showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : context.tr('tackle.add_failed')))); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text(context.tr('tackle.title'))),
      floatingActionButton: FloatingActionButton.extended(backgroundColor: AppColors.teal, onPressed: () => _form(), icon: const Icon(Icons.add, color: Colors.white), label: Text(context.tr('tackle.add'), style: const TextStyle(color: Colors.white))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(child: Text(context.tr('tackle.empty'), style: const TextStyle(color: Colors.black45)))
              : RefreshIndicator(onRefresh: _load, child: ListView.builder(
                  padding: EdgeInsets.fromLTRB(12, 12, 12, 12 + MediaQuery.of(context).padding.bottom),
                  itemCount: _items.length,
                  itemBuilder: (_, i) {
                    final t = _items[i] as Map;
                    return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
                      leading: const Icon(Icons.phishing, color: AppColors.teal),
                      title: Text(t['name'] ?? ''),
                      subtitle: Text([t['category'], if (t['setup'] != null) t['setup']].where((e) => e != null).join(' · ')),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) => v == 'edit' ? _form(t) : _delete(t),
                        itemBuilder: (_) => [
                          PopupMenuItem(value: 'edit', child: Row(children: [const Icon(Icons.edit, size: 18), const SizedBox(width: 8), Text(context.tr('p.edit'))])),
                          PopupMenuItem(value: 'delete', child: Row(children: [const Icon(Icons.delete_outline, size: 18, color: Colors.red), const SizedBox(width: 8), Text(context.tr('settings.delete'))])),
                        ],
                      ),
                    ));
                  })),
    );
  }
}
