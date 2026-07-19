import 'package:flutter/material.dart';
import '../core/api.dart';
import 'package:provider/provider.dart';
import '../core/config.dart';
import '../core/i18n.dart';
import '../core/realtime_service.dart';
import '../core/notif_nav.dart';

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

  /// Eén melding uit de lijst halen (bij aantikken of wegvegen).
  void _remove(Map n) {
    setState(() => _list.remove(n));
    Api.delete('/notifications/${n['id']}').catchError((_) => null);
  }

  Future<void> _clearAll() async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(context.tr('notifs.clear_title')),
      content: Text(context.tr('notifs.clear_body')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('feed.cancel'))),
        FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.danger), onPressed: () => Navigator.pop(ctx, true), child: Text(context.tr('notifs.clear_confirm'))),
      ],
    ));
    if (ok != true) return;
    setState(() => _list = []);
    Api.delete('/notifications').catchError((_) => null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('notifs.title')), actions: [
        if (_list.isNotEmpty) IconButton(icon: const Icon(Icons.delete_sweep_outlined), tooltip: context.tr('notifs.clear_title'), onPressed: _clearAll),
      ]),
      body: _loading ? const Center(child: CircularProgressIndicator()) : _list.isEmpty
        ? Center(child: Text(context.tr('notifs.empty'), style: const TextStyle(color: Colors.black45)))
        : ListView.builder(padding: const EdgeInsets.all(12), itemCount: _list.length, itemBuilder: (_, i) {
            final n = _list[i] as Map; final data = (n['data'] ?? n) as Map;
            final link = (data['link'] ?? '').toString();
            final event = (data['event'] ?? '').toString();
            final Widget? target = screenForLink(link, event: event);
            return Dismissible(
              key: ValueKey(n['id'] ?? i),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (_) => _remove(n),
              child: Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
                leading: const CircleAvatar(backgroundColor: AppColors.bg, child: Icon(Icons.notifications, color: AppColors.teal)),
                title: Text(data['message'] ?? ''),
                trailing: target != null ? const Icon(Icons.chevron_right, color: Colors.black26) : null,
                // Aantikken → naar het doel + de melding uit de lijst halen (blijft niet staan).
                onTap: target != null ? () { _remove(n); Navigator.push(context, MaterialPageRoute(builder: (_) => target)); } : null,
              )),
            );
          }));
  }
}
