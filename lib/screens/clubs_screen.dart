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
    try { final r = await Api.get('/clubs'); setState(() { _clubs = r is List ? r : (r['data'] ?? []); _loading = false; }); }
    catch (_) { setState(() => _loading = false); }
  }

  Future<void> _create() async {
    final name = TextEditingController();
    final city = TextEditingController();
    String country = 'NL';
    final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      title: const Text('Club starten'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Clubnaam')),
        const SizedBox(height: 8),
        TextField(controller: city, decoration: const InputDecoration(labelText: 'Plaats')),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(initialValue: country, decoration: const InputDecoration(labelText: 'Land'),
          items: const [DropdownMenuItem(value: 'NL', child: Text('Nederland')), DropdownMenuItem(value: 'BE', child: Text('België')), DropdownMenuItem(value: 'DE', child: Text('Duitsland')), DropdownMenuItem(value: 'FR', child: Text('Frankrijk'))],
          onChanged: (v) => setS(() => country = v!)),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuleren')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Aanmaken'))],
    )));
    if (ok != true || name.text.trim().isEmpty) return;
    try { await Api.post('/clubs', {'name': name.text.trim(), 'country': country, if (city.text.isNotEmpty) 'city': city.text.trim()}); _load(); } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(backgroundColor: AppColors.teal, onPressed: _create, icon: const Icon(Icons.add, color: Colors.white), label: const Text('Club', style: TextStyle(color: Colors.white))),
      body: _loading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(
        onRefresh: _load,
        child: _clubs.isEmpty
            ? ListView(children: const [SizedBox(height: 120), Center(child: Text('Nog geen clubs — start de eerste!', style: TextStyle(color: Colors.black45)))])
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _clubs.length,
                itemBuilder: (_, i) {
                  final c = _clubs[i] as Map;
                  return Card(margin: const EdgeInsets.only(bottom: 10), child: ListTile(
                    leading: const CircleAvatar(backgroundColor: AppColors.bg, child: Icon(Icons.groups, color: AppColors.teal)),
                    title: Text(c['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(['${c['members_count'] ?? 0} leden', if (c['city'] != null) c['city']].join(' · ')),
                    trailing: c['is_member'] == true ? const Chip(label: Text('Lid', style: TextStyle(fontSize: 11)), visualDensity: VisualDensity.compact) : const Icon(Icons.chevron_right),
                    onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => ClubDetailScreen(clubId: c['id']))); _load(); },
                  ));
                },
              ),
      ),
    );
  }
}
