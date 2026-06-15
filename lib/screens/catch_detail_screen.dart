import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../core/api.dart';
import '../core/auth.dart';
import '../core/config.dart';

const _moonNl = {
  'new': 'Nieuwe maan', 'waxing_crescent': 'Wassende sikkel', 'first_quarter': 'Eerste kwartier',
  'waxing_gibbous': 'Wassende maan', 'full': 'Volle maan', 'waning_gibbous': 'Afnemende maan',
  'last_quarter': 'Laatste kwartier', 'waning_crescent': 'Afnemende sikkel',
};

class CatchDetailScreen extends StatefulWidget {
  final int catchId;
  const CatchDetailScreen({super.key, required this.catchId});
  @override
  State<CatchDetailScreen> createState() => _CatchDetailScreenState();
}

class _CatchDetailScreenState extends State<CatchDetailScreen> {
  Map? _c;
  bool _loading = true, _storyBusy = false;

  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try { final r = await Api.get('/catches/${widget.catchId}'); setState(() { _c = r['data']; _loading = false; }); }
    catch (_) { setState(() => _loading = false); }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Vangst verwijderen?'), actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Nee')),
        FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.danger), onPressed: () => Navigator.pop(ctx, true), child: const Text('Verwijderen')),
      ]));
    if (ok != true) return;
    await Api.delete('/catches/${widget.catchId}').catchError((_) => null);
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _aiStory() async {
    setState(() => _storyBusy = true);
    try {
      final r = await Api.post('/catches/${widget.catchId}/story', {'lang': 'nl'});
      final story = (r['story'] ?? r['content'] ?? '').toString();
      if (!mounted) return;
      final ctrl = TextEditingController(text: story);
      final post = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
        title: const Text('AI-vangstverhaal'),
        content: TextField(controller: ctrl, maxLines: 6, decoration: const InputDecoration(border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Sluiten')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('In feed plaatsen')),
        ]));
      if (post == true) {
        await Api.post('/posts', {'content': ctrl.text, 'visibility': 'public', if (_c?['photo_path'] != null) 'image_path': _c!['photo_path']});
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('In je feed geplaatst!')));
      }
    } catch (_) {} finally { if (mounted) setState(() => _storyBusy = false); }
  }

  Widget _chip(String t) => Chip(label: Text(t), backgroundColor: AppColors.bg, visualDensity: VisualDensity.compact);

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_c == null) return const Scaffold(body: Center(child: Text('Niet gevonden')));
    final c = _c!;
    final me = context.read<AuthState>().user;
    final mine = c['user'] == null || (c['user'] as Map)['id'] == me?.id;
    final cond = [
      if (c['moon_phase'] != null) _moonNl[c['moon_phase']] ?? c['moon_phase'],
      if (c['pressure_hpa'] != null) '${c['pressure_hpa']} hPa',
      if (c['wind_ms'] != null) '${c['wind_ms']} m/s',
      if (c['cloud_pct'] != null) '${c['cloud_pct']}% bewolking',
    ];
    return Scaffold(
      appBar: AppBar(title: Text(c['species'] ?? 'Vangst'), actions: [
        if (mine) IconButton(icon: const Icon(Icons.delete_outline), onPressed: _delete),
      ]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        if (c['photo_path'] != null) ClipRRect(borderRadius: BorderRadius.circular(14), child: CachedNetworkImage(imageUrl: c['photo_path'], width: double.infinity, fit: BoxFit.cover)),
        const SizedBox(height: 14),
        Text(c['species'] ?? 'Vis', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.navy)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          if (c['weight_kg'] != null) _chip('${c['weight_kg']} kg'),
          if (c['length_cm'] != null) _chip('${c['length_cm']} cm'),
          if (c['bait'] != null) _chip(c['bait']),
          if (c['technique'] != null) _chip(c['technique']),
        ]),
        if (cond.isNotEmpty) ...[
          const SizedBox(height: 18),
          const Text('Omstandigheden bij de vangst', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: cond.map((e) => _chip(e.toString())).toList()),
        ],
        if (c['notes'] != null) ...[const SizedBox(height: 18), Text(c['notes'], style: const TextStyle(color: Colors.black54))],
        if (mine) ...[
          const SizedBox(height: 24),
          FilledButton.icon(onPressed: _storyBusy ? null : _aiStory,
            icon: _storyBusy ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.auto_awesome),
            label: const Text('AI-vangstverhaal maken')),
        ],
      ]),
    );
  }
}
