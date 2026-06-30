import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/config.dart';
import '../core/i18n.dart';

const _countries = {'NL': 'Nederland', 'BE': 'België', 'DE': 'Duitsland', 'FR': 'Frankrijk', 'XX': 'Overig/EU'};

class LicensesScreen extends StatefulWidget {
  const LicensesScreen({super.key});
  @override
  State<LicensesScreen> createState() => _LicensesScreenState();
}

class _LicensesScreenState extends State<LicensesScreen> {
  List _list = [];
  bool _loading = true;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try { final r = await Api.get('/licenses'); setState(() { _list = r is List ? r : (r['data'] ?? []); _loading = false; }); }
    catch (_) { setState(() => _loading = false); }
  }

  Future<void> _add() async {
    final name = TextEditingController();
    final number = TextEditingController();
    String country = 'NL';
    final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      title: Text(context.tr('licenses.add_title')),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<String>(initialValue: country, decoration: InputDecoration(labelText: context.tr('licenses.country')),
          items: _countries.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(), onChanged: (v) => setS(() => country = v!)),
        const SizedBox(height: 8),
        TextField(controller: name, decoration: InputDecoration(labelText: context.tr('licenses.name'))),
        const SizedBox(height: 8),
        TextField(controller: number, decoration: InputDecoration(labelText: context.tr('licenses.number'))),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('licenses.cancel'))),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.tr('licenses.save'))),
      ],
    )));
    if (ok != true || name.text.trim().isEmpty) return;
    try { await Api.post('/licenses', {'country': country, 'name': name.text.trim(), 'type': 'vispas', if (number.text.isNotEmpty) 'number': number.text.trim()}); _load(); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'Er ging iets mis'))); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('licenses.title'))),
      floatingActionButton: FloatingActionButton(backgroundColor: AppColors.teal, onPressed: _add, child: const Icon(Icons.add, color: Colors.white)),
      body: _loading ? const Center(child: CircularProgressIndicator()) : Column(children: [
        Padding(padding: const EdgeInsets.all(12), child: Text(context.tr('licenses.hint'), style: const TextStyle(fontSize: 12, color: Colors.black45))),
        Expanded(child: _list.isEmpty ? Center(child: Text(context.tr('licenses.empty'), style: const TextStyle(color: Colors.black45))) : ListView.builder(
          padding: const EdgeInsets.all(12), itemCount: _list.length,
          itemBuilder: (_, i) {
            final l = _list[i] as Map;
            return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
              leading: const Icon(Icons.badge, color: AppColors.teal),
              title: Text(l['name'] ?? ''),
              subtitle: Text([_countries[l['country']] ?? l['country'], if (l['number'] != null) l['number'], if (l['valid_until'] != null) '${context.tr('licenses.until')} ${(l['valid_until'] as String).substring(0, 10)}'].join(' · ')),
              trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.black38), onPressed: () async { try { await Api.delete('/licenses/${l['id']}'); _load(); } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'Er ging iets mis'))); } }),
            ));
          })),
      ]),
    );
  }
}
