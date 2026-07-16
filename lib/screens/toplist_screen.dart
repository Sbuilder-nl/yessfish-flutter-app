import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/config.dart';
import '../core/i18n.dart';
import '../widgets/fish_rating.dart';
import 'map_screen.dart';

/// Toplijst: best beoordeelde wateren + openbare stekken. Tik → naar de kaart.
class ToplistScreen extends StatefulWidget {
  const ToplistScreen({super.key});
  @override
  State<ToplistScreen> createState() => _ToplistScreenState();
}

class _ToplistScreenState extends State<ToplistScreen> {
  Map? _data;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try { final r = await Api.get('/toplist'); if (mounted) setState(() { _data = r is Map ? r : null; _loading = false; }); }
    catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final waters = (_data?['waters'] as List?) ?? [];
    final spots = (_data?['spots'] as List?) ?? [];
    final empty = !_loading && waters.isEmpty && spots.isEmpty;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('toplist.title'))),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : empty
          ? Center(child: Padding(padding: const EdgeInsets.all(32),
              child: Text(context.tr('toplist.empty'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.black45))))
          : ListView(padding: const EdgeInsets.all(16), children: [
              Text(context.tr('toplist.intro'), style: const TextStyle(color: Colors.black54)),
              if (waters.isNotEmpty) ...[
                const SizedBox(height: 18),
                _header(Icons.waves, context.tr('toplist.waters')),
                ...waters.asMap().entries.map((e) => _row(e.key + 1, e.value as Map, true)),
              ],
              if (spots.isNotEmpty) ...[
                const SizedBox(height: 22),
                _header(Icons.place, context.tr('toplist.spots')),
                ...spots.asMap().entries.map((e) => _row(e.key + 1, e.value as Map, false)),
              ],
            ]),
    );
  }

  Widget _header(IconData ic, String t) => Padding(padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [Icon(ic, size: 18, color: AppColors.teal), const SizedBox(width: 8),
      Text(t, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy))]));

  Widget _row(int rank, Map it, bool isWater) {
    final avg = (it['avg'] as num?)?.toDouble() ?? 0;
    final cnt = (it['count'] as num?)?.toInt() ?? 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MapScreen(
          focusLat: (it['lat'] as num?)?.toDouble(), focusLng: (it['lng'] as num?)?.toDouble()))),
        leading: CircleAvatar(
          backgroundColor: rank <= 3 ? const Color(0xFFD4A017) : Colors.black12,
          foregroundColor: rank <= 3 ? Colors.white : Colors.black54,
          child: Text('$rank', style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        title: Text('${it['name'] ?? '—'}', maxLines: 1, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Row(children: [FishRating(value: avg, size: 15), const SizedBox(width: 6),
          Text('${avg.toStringAsFixed(1)} · $cnt', style: const TextStyle(fontSize: 12, color: Colors.black45))]),
        trailing: const Icon(Icons.chevron_right, color: Colors.black26),
      ),
    );
  }
}
