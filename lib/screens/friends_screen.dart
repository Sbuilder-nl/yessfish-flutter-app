import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/config.dart';
import '../core/i18n.dart';
import '../widgets/avatar.dart';
import '../widgets/report.dart';
import 'chat_screen.dart';
import 'user_profile_screen.dart';

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
  Future<void> _accept(int friendshipId) async { await Api.post('/friends/$friendshipId/accept').catchError((_) => null); _load(); }
  Future<void> _addFriend(int userId) async {
    final m = ScaffoldMessenger.of(context);
    try {
      await Api.post('/friends', {'addressee_id': userId});
      m.showSnackBar(SnackBar(content: Text(context.tr('friends.request_sent'))));
    } catch (e) {
      m.showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : context.tr('friends.send_failed'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(length: 3, child: Scaffold(
      appBar: AppBar(title: Text(context.tr('friends.title')), bottom: TabBar(tabs: [
        Tab(text: context.tr('friends.tab_friends')),
        Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(context.tr('friends.tab_requests')),
          if (_pending.isNotEmpty) Padding(padding: const EdgeInsets.only(left: 6), child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: const BoxDecoration(color: Color(0xFFFF5A5A), borderRadius: BorderRadius.all(Radius.circular(10))),
            child: Text('${_pending.length}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)))),
        ])),
        Tab(text: context.tr('friends.tab_search')),
      ])),
      body: _loading ? const Center(child: CircularProgressIndicator()) : TabBarView(children: [
        ListView(children: _friends.map((u) => ListTile(leading: Avatar(name: u['username'], src: u['avatar_path'], size: 40), title: Text(u['username'] ?? ''), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(userId: u['id']))), trailing: IconButton(icon: const Icon(Icons.chat_bubble_outline, color: AppColors.teal), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(recipientId: u['id'], recipientName: u['username'])))))).toList()),
        _pending.isEmpty
          ? Center(child: Text(context.tr('friends.no_requests'), style: const TextStyle(color: Colors.black45)))
          : ListView(children: _pending.map((f) {
              final r = (f['requester'] ?? {}) as Map;
              return ListTile(
                leading: Avatar(name: r['username'], src: r['avatar_path'], size: 40), title: Text(r['username'] ?? context.tr('friends.unknown')),
                trailing: FilledButton(onPressed: () => _accept(f['id']), child: Text(context.tr('friends.accept'))),
              );
            }).toList()),
        Column(children: [
          Padding(padding: const EdgeInsets.all(12), child: TextField(controller: _q, onChanged: _doSearch, decoration: InputDecoration(prefixIcon: const Icon(Icons.search), labelText: context.tr('friends.search_label')))),
          Expanded(child: ListView(children: _search.map((u) => ListTile(
            leading: Avatar(name: u['username'], src: u['avatar_path'], size: 40), title: Text(u['username'] ?? ''),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(userId: u['id']))),
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
