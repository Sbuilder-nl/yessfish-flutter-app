import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/config.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List _list = [];
  bool _loading = true;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try {
      final r = await Api.get('/notifications');
      setState(() { _list = r is List ? r : (r['data'] ?? []); _loading = false; });
      Api.post('/notifications/read-all').catchError((_) => null);
    } catch (_) { setState(() => _loading = false); }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Meldingen')),
      body: _loading ? const Center(child: CircularProgressIndicator()) : _list.isEmpty
        ? const Center(child: Text('Geen meldingen', style: TextStyle(color: Colors.black45)))
        : ListView.builder(padding: const EdgeInsets.all(12), itemCount: _list.length, itemBuilder: (_, i) {
            final n = _list[i] as Map; final data = (n['data'] ?? n) as Map;
            return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
              leading: const CircleAvatar(backgroundColor: AppColors.bg, child: Icon(Icons.notifications, color: AppColors.teal)),
              title: Text(data['message'] ?? ''),
            ));
          }));
  }
}
