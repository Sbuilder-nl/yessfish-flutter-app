import 'package:flutter/material.dart';
import '../core/api.dart';

class TournamentsScreen extends StatefulWidget {
  const TournamentsScreen({super.key});
  @override
  State<TournamentsScreen> createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends State<TournamentsScreen> {
  List _items = [];
  bool _loading = true;
  final Map<int, List> _boards = {};

  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try { final r = await Api.get('/tournaments'); setState(() { _items = r is List ? r : (r['data'] ?? []); _loading = false; }); }
    catch (_) { setState(() => _loading = false); }
  }
  Future<void> _board(int id) async {
    try { final r = await Api.get('/tournaments/$id/leaderboard'); setState(() => _boards[id] = r is List ? r : (r['data'] ?? [])); } catch (_) {}
  }
  String _status(String? s) => {'open': 'Open', 'closed': 'Gesloten', 'draft': 'Concept'}[s] ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Toernooien')),
      body: _loading ? const Center(child: CircularProgressIndicator()) : _items.isEmpty ? const Center(child: Text('Geen toernooien', style: TextStyle(color: Colors.black45))) : ListView.builder(
        padding: const EdgeInsets.all(12), itemCount: _items.length,
        itemBuilder: (_, i) {
          final t = _items[i] as Map; final id = t['id'] as int;
          return Card(margin: const EdgeInsets.only(bottom: 10), child: ExpansionTile(
            onExpansionChanged: (open) { if (open && _boards[id] == null) _board(id); },
            title: Text(t['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${_status(t['status'])} · ${t['participants_count'] ?? 0} deelnemers'),
            children: [
              if (t['status'] == 'open') Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Align(alignment: Alignment.centerLeft, child: FilledButton(onPressed: () async { final m = ScaffoldMessenger.of(context); await Api.post('/tournaments/$id/join').catchError((_) => null); m.showSnackBar(const SnackBar(content: Text('Aangemeld'))); }, child: const Text('Meedoen')))),
              ...((_boards[id] ?? []).asMap().entries.map((e) {
                final r = e.value as Map; final u = r['user'] as Map?;
                return ListTile(dense: true, leading: Text('${e.key + 1}'), title: Text(u?['username'] ?? ''), trailing: Text('${r['score'] ?? 0} pnt'));
              })),
            ],
          ));
        }));
  }
}
