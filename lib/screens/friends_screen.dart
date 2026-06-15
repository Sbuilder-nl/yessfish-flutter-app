import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/config.dart';
import '../widgets/avatar.dart';
import '../widgets/report.dart';
import 'chat_screen.dart';

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
  Future<void> _accept(int id) async { await Api.post('/friends/$id/accept').catchError((_) => null); _load(); }
  Future<void> _addFriend(int id) async {
    final m = ScaffoldMessenger.of(context);
    await Api.post('/friends/$id').catchError((_) => null);
    m.showSnackBar(const SnackBar(content: Text('Verzoek verstuurd')));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(length: 3, child: Scaffold(
      appBar: AppBar(title: const Text('Vrienden'), bottom: const TabBar(tabs: [Tab(text: 'Vrienden'), Tab(text: 'Verzoeken'), Tab(text: 'Zoeken')])),
      body: _loading ? const Center(child: CircularProgressIndicator()) : TabBarView(children: [
        ListView(children: _friends.map((u) => ListTile(leading: Avatar(name: u['username'], src: u['avatar_path'], size: 40), title: Text(u['username'] ?? ''), trailing: IconButton(icon: const Icon(Icons.chat_bubble_outline, color: AppColors.teal), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(recipientId: u['id'], recipientName: u['username'])))))).toList()),
        ListView(children: _pending.map((u) => ListTile(
          leading: Avatar(name: u['username'], src: u['avatar_path'], size: 40), title: Text(u['username'] ?? ''),
          trailing: FilledButton(onPressed: () => _accept(u['id']), child: const Text('Accepteren')),
        )).toList()),
        Column(children: [
          Padding(padding: const EdgeInsets.all(12), child: TextField(controller: _q, onChanged: _doSearch, decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: 'Zoek vissers'))),
          Expanded(child: ListView(children: _search.map((u) => ListTile(
            leading: Avatar(name: u['username'], src: u['avatar_path'], size: 40), title: Text(u['username'] ?? ''),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: const Icon(Icons.person_add, color: AppColors.teal), onPressed: () => _addFriend(u['id'])),
              IconButton(icon: const Icon(Icons.flag_outlined, color: Colors.black26, size: 18), onPressed: () => showReportSheet(context, type: 'user', targetId: u['id'])),
            ]),
          )).toList())),
        ]),
      ]),
    ));
  }
}
