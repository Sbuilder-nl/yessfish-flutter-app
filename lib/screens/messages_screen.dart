import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api.dart';
import '../core/auth.dart';
import '../core/config.dart';
import '../core/i18n.dart';
import '../core/realtime_service.dart';
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
    final myId = context.read<AuthState>().user?.id;
    return Scaffold(appBar: AppBar(title: Text(context.tr('messages.title'))),
      body: _loading ? const Center(child: CircularProgressIndicator()) : _convs.isEmpty
        ? Center(child: Text(context.tr('messages.empty'), style: const TextStyle(color: Colors.black45)))
        : RefreshIndicator(onRefresh: _load, child: ListView.builder(itemCount: _convs.length, itemBuilder: (_, i) {
            final c = _convs[i] as Map;
            final users = (c['users'] ?? []) as List;
            // Toon de ANDER, niet jezelf (gesprek bevat beide deelnemers).
            final otherList = users.where((u) => (u as Map)['id'] != myId).toList();
            final other = (otherList.isNotEmpty ? otherList.first : (users.isNotEmpty ? users.first : null)) as Map?;
            final unread = (c['unread'] ?? 0) as int;
            final last = c['last_message'] as Map?;
            final preview = last != null
                ? '${last['sender_id'] == myId ? '${context.tr('messages.you')}: ' : ''}${last['body'] ?? ''}'
                : context.tr('messages.tap_to_chat');
            return ListTile(
              leading: Avatar(name: other?['username'], src: other?['avatar_path'], size: 46),
              title: Text(other?['username'] ?? context.tr('messages.conversation'), style: TextStyle(fontWeight: unread > 0 ? FontWeight.bold : FontWeight.w600)),
              subtitle: Text(preview, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: unread > 0 ? Colors.black87 : Colors.black45, fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.normal)),
              trailing: unread > 0
                ? Container(padding: const EdgeInsets.all(6), constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                    decoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle),
                    child: Text(unread > 9 ? '9+' : '$unread', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)))
                : const Icon(Icons.chevron_right, color: Colors.black26),
              onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(conversation: c))); _load(); context.read<RealtimeService>().refreshCounts(); },
            );
          })));
  }
}
