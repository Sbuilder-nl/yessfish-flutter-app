import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/i18n.dart';

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
  String _status(BuildContext context, String? s) => {'open': context.tr('tournaments.status_open'), 'closed': context.tr('tournaments.status_closed'), 'draft': context.tr('tournaments.status_draft')}[s] ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text(context.tr('tournaments.title'))),
      body: _loading ? const Center(child: CircularProgressIndicator()) : _items.isEmpty ? Center(child: Text(context.tr('tournaments.empty'), style: const TextStyle(color: Colors.black45))) : ListView.builder(
        padding: const EdgeInsets.all(12), itemCount: _items.length,
        itemBuilder: (_, i) {
          final t = _items[i] as Map; final id = t['id'] as int;
          return Card(margin: const EdgeInsets.only(bottom: 10), child: ExpansionTile(
            onExpansionChanged: (open) { if (open && _boards[id] == null) _board(id); },
            title: Text(t['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${_status(context, t['status'])} · ${t['participants_count'] ?? 0} ${context.tr('tournaments.participants')}'),
            children: [
              if (t['status'] == 'open') Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Align(alignment: Alignment.centerLeft, child: FilledButton(onPressed: () async { final m = ScaffoldMessenger.of(context); await Api.post('/tournaments/$id/join').catchError((_) => null); m.showSnackBar(SnackBar(content: Text(context.tr('tournaments.joined')))); }, child: Text(context.tr('tournaments.join'))))),
              ...((_boards[id] ?? []).asMap().entries.map((e) {
                final r = e.value as Map; final u = r['user'] as Map?;
                return ListTile(dense: true, leading: Text('${e.key + 1}'), title: Text(u?['username'] ?? ''), trailing: Text('${r['score'] ?? 0} ${context.tr('tournaments.points')}'));
              })),
            ],
          ));
        }));
  }
}
