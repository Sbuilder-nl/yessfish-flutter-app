import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/config.dart';
import 'club_detail_screen.dart';

class ClubsScreen extends StatefulWidget {
  const ClubsScreen({super.key});
  @override
  State<ClubsScreen> createState() => _ClubsScreenState();
}

class _ClubsScreenState extends State<ClubsScreen> {
  List _clubs = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await Api.get('/clubs');
      setState(() { _clubs = r is List ? r : (r['data'] ?? []); _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _load,
      child: _clubs.isEmpty
          ? ListView(children: const [SizedBox(height: 120), Center(child: Text('Nog geen clubs', style: TextStyle(color: Colors.black45)))])
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _clubs.length,
              itemBuilder: (_, i) {
                final c = _clubs[i] as Map;
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const CircleAvatar(backgroundColor: AppColors.bg, child: Icon(Icons.groups, color: AppColors.teal)),
                    title: Text(c['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text([
                      '${c['members_count'] ?? 0} leden',
                      if (c['city'] != null) c['city'],
                    ].join(' · ')),
                    trailing: c['is_member'] == true ? const Chip(label: Text('Lid', style: TextStyle(fontSize: 11)), visualDensity: VisualDensity.compact) : const Icon(Icons.chevron_right),
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => ClubDetailScreen(clubId: c['id'])));
                      _load();
                    },
                  ),
                );
              },
            ),
    );
  }
}
