import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/config.dart';
import '../widgets/avatar.dart';
import '../widgets/report.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});
  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  List _friends = [], _pending = [], _search = [];
  bool _loading = true;
  final _q = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try {
      final f = await Api.get('/friends');
      final p = await Api.get('/friends/pending');
      setState(() {
        _friends = (f is List ? f : f['data']) ?? [];
        _pending = (p is List ? p : p['data']) ?? [];
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }
  Future<void> _doSearch(String q) async {
    if (q.trim().isEmpty) { setState(() => _search = []); return; }
    try { final r = await Api.get('/users?q=${Uri.encodeComponent(q)}'); setState(() => _search = (r is List ? r : r['data']) ?? []); } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(length: 3, child: Scaffold(
      appBar: AppBar(title: const Text('Vrienden'), bottom: const TabBar(tabs: [Tab(text: 'Vrienden'), Tab(text: 'Verzoeken'), Tab(text: 'Zoeken')])),
      body: _loading ? const Center(child: CircularProgressIndicator()) : TabBarView(children: [
        ListView(children: _friends.map((u) => ListTile(leading: Avatar(name: u['username'], src: u['avatar_path'], size: 40), title: Text(u['username'] ?? ''))).toList()),
        ListView(children: _pending.map((u) => ListTile(
          leading: Avatar(name: u['username'], src: u['avatar_path'], size: 40), title: Text(u['username'] ?? ''),
          trailing: FilledButton(onPressed: () async { await Api.post('/friends/${u['id']}/accept').catchError((_) => null); _load(); }, child: const Text('Accepteren')),
        )).toList()),
        Column(children: [
          Padding(padding: const EdgeInsets.all(12), child: TextField(controller: _q, onChanged: _doSearch, decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: 'Zoek vissers'))),
          Expanded(child: ListView(children: _search.map((u) => ListTile(
            leading: Avatar(name: u['username'], src: u['avatar_path'], size: 40), title: Text(u['username'] ?? ''),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [IconButton(icon: const Icon(Icons.person_add, color: AppColors.teal), onPressed: () async { await Api.post('/friends/\${u['id']}').catchError((_) => null); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verzoek verstuurd'))); }), IconButton(icon: const Icon(Icons.flag_outlined, color: Colors.black26, size: 18), onPressed: () => showReportSheet(context, type: 'user', targetId: u['id']))]),
          )).toList())),
        ]),
      ]),
    ));
  }
}
