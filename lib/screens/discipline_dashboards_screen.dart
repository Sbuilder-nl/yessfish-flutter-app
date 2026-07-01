import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/api.dart';
import '../core/units.dart';
import '../core/config.dart';
import '../core/i18n.dart';
import '../core/disciplines_i18n.dart';
import 'disciplines_screen.dart';
import 'species_detail_screen.dart';

/// Eigen dashboard per gekozen visstijl. Wie karper én roofvis kiest, ziet
/// beide — elk met stats, doelsoorten en een stijl-tip.
class DisciplineDashboardsScreen extends StatefulWidget {
  const DisciplineDashboardsScreen({super.key});
  @override
  State<DisciplineDashboardsScreen> createState() => _DisciplineDashboardsScreenState();
}

class _DisciplineDashboardsScreenState extends State<DisciplineDashboardsScreen> {
  List<Map<String, dynamic>> _dash = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final loc = Provider.of<I18n>(context, listen: false).locale;
      final r = await Api.get('/profile/disciplines/dashboards?lang=$loc') as Map<String, dynamic>;
      _dash = ((r['dashboards'] as List?) ?? []).map((e) => Map<String, dynamic>.from(e)).toList();
      setState(() => _loading = false);
    } catch (e) {
      setState(() { _loading = false; _error = dui(context, 'err'); });
    }
  }

  Future<void> _edit() async {
    final changed = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const DisciplinesScreen()));
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(dui(context, 'title')),
        actions: [IconButton(onPressed: _edit, icon: const Icon(Icons.tune), tooltip: dui(context, 'edit'))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_error!),
                  const SizedBox(height: 12),
                  OutlinedButton(onPressed: _load, child: Text(dui(context, 'retry'))),
                ]))
              : _dash.isEmpty
                  ? _empty()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        // extra onderruimte i.v.m. edge-to-edge: laatste kaart valt anders
                        // deels achter de systeem-navigatiebalk.
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
                        itemCount: _dash.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (c, i) => _card(_dash[i]),
                      ),
                    ),
    );
  }

  Widget _empty() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.style_outlined, size: 56, color: Colors.black26),
            const SizedBox(height: 16),
            Text(dui(context, 'empty'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 18),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
              onPressed: _edit,
              icon: const Icon(Icons.add),
              label: Text(dui(context, 'choose')),
            ),
          ]),
        ),
      );

  Widget _card(Map<String, dynamic> d) {
    final disc = Map<String, dynamic>.from(d['discipline'] as Map);
    final st = Map<String, dynamic>.from(d['stats'] as Map);
    final species = ((d['target_species'] as List?) ?? []).map((e) => e.toString()).toList();
    final detail = ((d['target_species_detail'] as List?) ?? []).map((e) => Map<String, dynamic>.from(e)).toList();
    final anglers = (d['angler_count'] ?? 0) as int;
    final tip = d['tip']?.toString();
    final count = (st['catch_count'] ?? 0) as int;
    final bw = st['biggest_weight_kg'];
    final bl = st['biggest_length_cm'];

    String biggest() {
      final parts = <String>[];
      if (bw != null) parts.add(Units.weight(bw));
      if (bl != null) parts.add('$bl cm');
      return parts.isEmpty ? '—' : parts.join(' · ');
    }

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Kop
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.teal.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.set_meal, color: AppColors.teal, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(discName(context, disc['key'] as String),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy))),
          Text('$count ${dui(context, 'catches')}', style: const TextStyle(color: Colors.black54, fontSize: 13)),
        ]),
        if (anglers > 0) ...[
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.people_alt_outlined, size: 15, color: AppColors.teal),
            const SizedBox(width: 5),
            Text('$anglers', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.teal)),
          ]),
        ],
        const SizedBox(height: 14),
        // Stats
        if (count > 0) ...[
          Row(children: [
            _stat(dui(context, 'biggest'), biggest()),
            _stat(dui(context, 'topbait'), (st['top_bait'] ?? '—').toString()),
            _stat(dui(context, 'toptech'), (st['top_technique'] ?? '—').toString()),
          ]),
        ] else
          Text(dui(context, 'nocatch'), style: const TextStyle(color: Colors.black45, fontStyle: FontStyle.italic)),
        // Doelsoorten-gids (tikbaar, met foto's) — waardevol óók zonder eigen vangsten
        if (detail.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(dui(context, 'species'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
          const SizedBox(height: 8),
          SizedBox(
            height: 116,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: detail.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => _speciesCard(context, detail[i]),
            ),
          ),
        ] else if (species.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(dui(context, 'species'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 6, children: species.map((s) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(20)),
            child: Text(s, style: const TextStyle(fontSize: 12, color: Color(0xFF334155))),
          )).toList()),
        ],
        // Tip
        if (tip != null && tip.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.mint.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(12)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.lightbulb_outline, size: 18, color: AppColors.teal2),
              const SizedBox(width: 8),
              Expanded(child: Text(tip, style: const TextStyle(fontSize: 13, color: AppColors.navy, height: 1.3))),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _speciesCard(BuildContext context, Map<String, dynamic> s) {
    final img = s['image']?.toString();
    final maxL = s['max_length_cm'];
    final maxW = s['max_weight_kg'];
    String sub() {
      final p = <String>[];
      if (maxL != null) p.add('${maxL}cm');
      if (maxW != null) { final w = maxW as num; p.add(Units.weight(w)); }
      return p.isEmpty ? '' : 'tot ${p.join(' · ')}';
    }
    Widget ph() => Container(width: 96, height: 74, color: AppColors.bg, child: const Icon(Icons.set_meal, color: Colors.black26));
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => SpeciesDetailScreen(id: s['id'] as int, name: s['name'].toString()))),
      child: SizedBox(
        width: 96,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: (img != null && img.isNotEmpty)
                ? CachedNetworkImage(imageUrl: img, width: 96, height: 74, fit: BoxFit.cover,
                    placeholder: (_, __) => ph(), errorWidget: (_, __, ___) => ph())
                : ph(),
          ),
          const SizedBox(height: 4),
          Text(s['name'].toString(), maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.navy)),
          if (sub().isNotEmpty)
            Text(sub(), maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: Colors.black54)),
        ]),
      ),
    );
  }

  Widget _stat(String label, String value) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
          const SizedBox(height: 2),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.navy)),
        ]),
      );
}
