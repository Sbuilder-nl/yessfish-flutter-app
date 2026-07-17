import 'dart:async';

import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/config.dart';
import '../core/i18n.dart';

/// Uitrusting v2: meerdere sets per visserij (karper: 2 hengels + 2 molens + rig;
/// roofvis: hengel + molen + kunstaas; enz.). Zelfde model als de web-pagina:
/// per set vakken (slots) met een catalogus-product óf vrije tekst.

const List<String> kGearSlots = ['rod', 'reel', 'line', 'hook', 'lure', 'bait', 'terminal', 'other'];

const Map<String, List<String>> kGearTemplates = {
  'karper': ['rod', 'rod', 'reel', 'reel', 'line', 'terminal', 'bait'],
  'roofvis': ['rod', 'reel', 'line', 'terminal', 'lure'],
  'witvis': ['rod', 'reel', 'line', 'hook', 'bait'],
  'feeder': ['rod', 'reel', 'line', 'hook', 'terminal', 'bait'],
  'match': ['rod', 'reel', 'line', 'hook', 'bait'],
  'zee': ['rod', 'reel', 'line', 'terminal', 'bait'],
  'forel': ['rod', 'reel', 'line', 'hook', 'bait'],
  'vlieg': ['rod', 'reel', 'line', 'lure'],
  'algemeen': ['rod', 'reel', 'line'],
};

class TackleScreen extends StatefulWidget {
  const TackleScreen({super.key});
  @override
  State<TackleScreen> createState() => _TackleScreenState();
}

class _TackleScreenState extends State<TackleScreen> {
  List _sets = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await Api.get('/gear-sets');
      final sets = r is Map ? r['sets'] : null;
      if (mounted) setState(() { _sets = sets is List ? sets : []; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _newSet() async {
    final String? disc = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(ctx.tr('gear.choose_style'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.navy)),
            ),
            for (final d in kGearTemplates.keys)
              ListTile(
                dense: true,
                leading: const Icon(Icons.phishing, color: AppColors.teal),
                title: Text(ctx.tr('gear.disc_$d')),
                onTap: () => Navigator.pop(ctx, d),
              ),
          ],
        ),
      ),
    );
    if (disc == null || !mounted) return;
    final bool? changed = await Navigator.push<bool>(context, MaterialPageRoute(
      builder: (_) => GearSetEditorScreen(discipline: disc),
    ));
    if (changed == true) _load();
  }

  Future<void> _openSet(Map set) async {
    final bool? changed = await Navigator.push<bool>(context, MaterialPageRoute(
      builder: (_) => GearSetEditorScreen(existing: Map<String, dynamic>.from(set)),
    ));
    if (changed == true) _load();
  }

  String _itemLabel(Map it) {
    final String brand = (it['brand'] ?? '').toString();
    final String name = (it['product'] ?? it['custom_name'] ?? '').toString();
    return brand.isEmpty ? name : '$brand $name';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(context.tr('gear.title'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newSet,
        icon: const Icon(Icons.add),
        label: Text(context.tr('gear.new_set')),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _sets.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 80),
                        const Icon(Icons.phishing, size: 56, color: Colors.black26),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(context.tr('gear.empty'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                      itemCount: _sets.length,
                      itemBuilder: (_, i) {
                        final Map set = _sets[i] as Map;
                        final List items = set['items'] is List ? set['items'] as List : [];
                        final String disc = (set['discipline'] ?? 'algemeen').toString();
                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.border)),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => _openSet(set),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Expanded(child: Text((set['name'] ?? '').toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.navy))),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                      decoration: BoxDecoration(color: AppColors.teal.withValues(alpha: .1), borderRadius: BorderRadius.circular(20)),
                                      child: Text(context.tr('gear.disc_$disc'), style: const TextStyle(fontSize: 12, color: AppColors.teal2, fontWeight: FontWeight.w600)),
                                    ),
                                  ]),
                                  if (items.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [
                                        for (final it in items.take(6))
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(12)),
                                            child: Text(_itemLabel(it as Map), style: const TextStyle(fontSize: 12, color: Colors.black87), overflow: TextOverflow.ellipsis),
                                          ),
                                        if (items.length > 6)
                                          Text('+${items.length - 6}', style: const TextStyle(fontSize: 12, color: Colors.black45)),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

/// Eén onderdeel-regel binnen de editor.
class _GearItem {
  String slot;
  int? productId;
  String? productLabel; // "merk naam" bij catalogus-keuze
  String? customName;
  _GearItem({required this.slot, this.productId, this.productLabel, this.customName});

  bool get filled => productId != null || (customName != null && customName!.isNotEmpty);
}

class GearSetEditorScreen extends StatefulWidget {
  final Map<String, dynamic>? existing;
  final String? discipline;
  const GearSetEditorScreen({super.key, this.existing, this.discipline});
  @override
  State<GearSetEditorScreen> createState() => _GearSetEditorScreenState();
}

class _GearSetEditorScreenState extends State<GearSetEditorScreen> {
  final TextEditingController _name = TextEditingController();
  late String _disc;
  final List<_GearItem> _items = [];
  bool _busy = false;

  int? get _setId {
    final dynamic id = widget.existing == null ? null : widget.existing!['id'];
    return id is int ? id : int.tryParse('$id');
  }

  @override
  void initState() {
    super.initState();
    final Map<String, dynamic>? ex = widget.existing;
    if (ex != null) {
      _name.text = (ex['name'] ?? '').toString();
      _disc = (ex['discipline'] ?? 'algemeen').toString();
      final List raw = ex['items'] is List ? ex['items'] as List : [];
      for (final r in raw) {
        final Map m = r as Map;
        final String brand = (m['brand'] ?? '').toString();
        final String prod = (m['product'] ?? '').toString();
        final dynamic pid = m['product_id'];
        _items.add(_GearItem(
          slot: (m['slot'] ?? 'other').toString(),
          productId: pid is int ? pid : int.tryParse('$pid'),
          productLabel: prod.isEmpty ? null : (brand.isEmpty ? prod : '$brand $prod'),
          customName: (m['custom_name'] ?? '') == '' ? null : m['custom_name'].toString(),
        ));
      }
    } else {
      _disc = widget.discipline ?? 'algemeen';
      final List<String> tpl = kGearTemplates[_disc] ?? kGearTemplates['algemeen']!;
      for (final s in tpl) {
        _items.add(_GearItem(slot: s));
      }
    }
  }

  Future<void> _pickForItem(_GearItem item) async {
    final _PickResult? res = await showModalBottomSheet<_PickResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _SlotPickerSheet(slot: item.slot, discipline: _disc),
    );
    if (res == null) return;
    setState(() {
      item.productId = res.productId;
      item.productLabel = res.label;
      item.customName = res.customName;
    });
  }

  Future<void> _addItem() async {
    final String? slot = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final s in kGearSlots)
              ListTile(dense: true, title: Text(ctx.tr('gear.slot_$s')), onTap: () => Navigator.pop(ctx, s)),
          ],
        ),
      ),
    );
    if (slot == null) return;
    setState(() => _items.add(_GearItem(slot: slot)));
  }

  Future<void> _save() async {
    final String name = _name.text.trim();
    if (name.isEmpty) {
      setState(() {});
      return;
    }
    setState(() => _busy = true);
    try {
      final List<Map<String, dynamic>> items = [];
      for (int i = 0; i < _items.length; i++) {
        final _GearItem it = _items[i];
        if (!it.filled) continue;
        items.add({
          'slot': it.slot,
          if (it.productId != null) 'product_id': it.productId,
          if (it.productId == null && it.customName != null) 'custom_name': it.customName,
          'position': i,
        });
      }
      final Map<String, dynamic> body = {'name': name, 'discipline': _disc, 'items': items};
      if (_setId == null) {
        await Api.post('/gear-sets', body);
      } else {
        await Api.put('/gear-sets/$_setId', body);
      }
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('gear.save_failed'))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final int? id = _setId;
    if (id == null) return;
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('gear.delete')),
        content: Text(ctx.tr('gear.delete_confirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.tr('gear.cancel'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ctx.tr('gear.delete'))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Api.delete('/gear-sets/$id');
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('gear.save_failed'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isNew = _setId == null;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(isNew ? context.tr('gear.new_set') : context.tr('gear.edit_set')),
        actions: [
          if (!isNew) IconButton(icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: context.tr('gear.set_name'),
              hintText: context.tr('gear.name_hint'),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _disc,
            decoration: InputDecoration(
              labelText: context.tr('gear.choose_style'),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: [
              for (final d in kGearTemplates.keys)
                DropdownMenuItem(value: d, child: Text(context.tr('gear.disc_$d'))),
            ],
            onChanged: (v) { if (v != null) setState(() => _disc = v); },
          ),
          const SizedBox(height: 16),
          Text(context.tr('gear.parts'), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy)),
          const SizedBox(height: 8),
          for (int i = 0; i < _items.length; i++) _row(i),
          const SizedBox(height: 6),
          OutlinedButton.icon(onPressed: _addItem, icon: const Icon(Icons.add, size: 18), label: Text(context.tr('gear.add_part'))),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: _busy
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(context.tr('gear.save')),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _row(int i) {
    final _GearItem it = _items[i];
    final String label = it.productLabel ?? it.customName ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          SizedBox(
            width: 86,
            child: Text(context.tr('gear.slot_${it.slot}'), style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: it.filled
                ? Row(children: [
                    Flexible(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.navy), overflow: TextOverflow.ellipsis)),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16, color: Colors.black38),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => setState(() { it.productId = null; it.productLabel = null; it.customName = null; }),
                    ),
                  ])
                : TextButton.icon(
                    onPressed: () => _pickForItem(it),
                    icon: const Icon(Icons.search, size: 16),
                    label: Text(context.tr('gear.choose'), style: const TextStyle(fontSize: 13)),
                    style: TextButton.styleFrom(alignment: Alignment.centerLeft),
                  ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.black26),
            visualDensity: VisualDensity.compact,
            onPressed: () => setState(() => _items.removeAt(i)),
          ),
        ],
      ),
    );
  }
}

class _PickResult {
  final int? productId;
  final String? label;
  final String? customName;
  _PickResult({this.productId, this.label, this.customName});
}

/// Bottom-sheet: zoeken in de catalogus (gefilterd op vak + vistijl) of vrije tekst.
class _SlotPickerSheet extends StatefulWidget {
  final String slot;
  final String discipline;
  const _SlotPickerSheet({required this.slot, required this.discipline});
  @override
  State<_SlotPickerSheet> createState() => _SlotPickerSheetState();
}

class _SlotPickerSheetState extends State<_SlotPickerSheet> {
  final TextEditingController _q = TextEditingController();
  List _results = [];
  bool _searching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(v));
  }

  Future<void> _search(String v) async {
    setState(() => _searching = true);
    try {
      // 'other' heeft geen catalogus-categorie → alleen op tekst zoeken
      final String cat = widget.slot == 'other' ? '' : '&category=${widget.slot}';
      final String d = widget.discipline == 'algemeen' ? '' : '&discipline=${widget.discipline}';
      final r = await Api.get('/catalog/search?q=${Uri.encodeComponent(v.trim())}$cat$d');
      final list = r is Map ? r['products'] : null;
      if (mounted) setState(() { _results = list is List ? list : []; _searching = false; });
    } catch (_) {
      if (mounted) setState(() { _results = []; _searching = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String q = _q.text.trim();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * .72,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _q,
                autofocus: true,
                onChanged: _onChanged,
                decoration: InputDecoration(
                  hintText: context.tr('gear.search_hint'),
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  isDense: true,
                ),
              ),
            ),
            if (_searching) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: ListView(
                children: [
                  for (final p in _results)
                    ListTile(
                      dense: true,
                      title: Text('${(p as Map)['brand'] ?? ''} ${p['name'] ?? ''}'.trim()),
                      subtitle: Text((p['subtype'] ?? p['category'] ?? '').toString(), style: const TextStyle(fontSize: 12)),
                      onTap: () {
                        final Map m = p;
                        final dynamic pid = m['id'];
                        final String brand = (m['brand'] ?? '').toString();
                        final String name = (m['name'] ?? '').toString();
                        Navigator.pop(context, _PickResult(
                          productId: pid is int ? pid : int.tryParse('$pid'),
                          label: brand.isEmpty ? name : '$brand $name',
                        ));
                      },
                    ),
                  if (q.length >= 2)
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.add, color: AppColors.teal),
                      title: Text('${context.tr('gear.use_custom')} "$q"', style: const TextStyle(color: AppColors.teal2)),
                      onTap: () => Navigator.pop(context, _PickResult(customName: q)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
