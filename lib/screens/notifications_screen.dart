import 'package:flutter/material.dart';
import '../core/api.dart';
import 'package:provider/provider.dart';
import '../core/config.dart';
import '../core/i18n.dart';
import '../core/realtime_service.dart';
import 'friends_screen.dart';
import 'messages_screen.dart';
import 'map_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List _list = [];
  bool _loading = true;
  @override
  void initState() { super.initState(); _load(); context.read<RealtimeService>().clearUnread(); }
  Future<void> _load() async {
    try {
      final r = await Api.get('/notifications');
      setState(() { _list = r is List ? r : (r['data'] ?? []); _loading = false; });
      Api.post('/notifications/read-all').catchError((_) => null);
    } catch (_) { setState(() => _loading = false); }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text(context.tr('notifs.title'))),
      body: _loading ? const Center(child: CircularProgressIndicator()) : _list.isEmpty
        ? Center(child: Text(context.tr('notifs.empty'), style: const TextStyle(color: Colors.black45)))
        : ListView.builder(padding: const EdgeInsets.all(12), itemCount: _list.length, itemBuilder: (_, i) {
            final n = _list[i] as Map; final data = (n['data'] ?? n) as Map;
            final link = (data['link'] ?? '').toString();
            final event = (data['event'] ?? '').toString();
            Widget? target;
            if (link.contains('vrienden') || event == 'friend_request') target = const FriendsScreen();
            else if (link.contains('berichten') || event == 'message') target = const MessagesScreen();
            else if (link.contains('kaart') && link.contains('w=')) {
              final wid = int.tryParse(RegExp(r'w=(\d+)').firstMatch(link)?.group(1) ?? '');
              if (wid != null) target = MapScreen(focusWaterId: wid);
            }
            return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
              leading: const CircleAvatar(backgroundColor: AppColors.bg, child: Icon(Icons.notifications, color: AppColors.teal)),
              title: Text(data['message'] ?? ''),
              trailing: target != null ? const Icon(Icons.chevron_right, color: Colors.black26) : null,
              onTap: target != null ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => target!)) : null,
            ));
          }));
  }
}
