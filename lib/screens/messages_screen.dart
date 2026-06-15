import 'package:flutter/material.dart';
import '../core/api.dart';
import '../widgets/avatar.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});
  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  List _convs = [];
  bool _loading = true;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try { final r = await Api.get('/conversations'); setState(() { _convs = r is List ? r : (r['data'] ?? []); _loading = false; }); }
    catch (_) { setState(() => _loading = false); }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Berichten')),
      body: _loading ? const Center(child: CircularProgressIndicator()) : _convs.isEmpty
        ? const Center(child: Text('Nog geen gesprekken', style: TextStyle(color: Colors.black45)))
        : RefreshIndicator(onRefresh: _load, child: ListView.builder(itemCount: _convs.length, itemBuilder: (_, i) {
            final c = _convs[i] as Map;
            final others = (c['users'] ?? []) as List;
            final other = others.isNotEmpty ? others.first as Map : null;
            return ListTile(
              leading: Avatar(name: other?['username'], src: other?['avatar_path'], size: 44),
              title: Text(other?['username'] ?? 'Gesprek'),
              onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(conversation: c))); _load(); },
            );
          })));
  }
}
