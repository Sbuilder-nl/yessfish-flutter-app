import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/config.dart';
import '../widgets/avatar.dart';

class ClubDetailScreen extends StatefulWidget {
  final int clubId;
  const ClubDetailScreen({super.key, required this.clubId});
  @override
  State<ClubDetailScreen> createState() => _ClubDetailScreenState();
}

class _ClubDetailScreenState extends State<ClubDetailScreen> {
  Map? _club;
  List _feed = [];
  bool _loading = true, _busy = false;
  final _post = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final r = await Api.get('/clubs/${widget.clubId}');
      Map? club = r is Map ? r : null;
      List feed = [];
      if (club?['my_role'] != null) {
        try { final f = await Api.get('/clubs/${widget.clubId}/feed'); feed = f['data'] ?? []; } catch (_) {}
      }
      setState(() { _club = club; _feed = feed; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _join() async { setState(() => _busy = true); await Api.post('/clubs/${widget.clubId}/join').catchError((_) => null); await _load(); setState(() => _busy = false); }
  Future<void> _leave() async { await Api.post('/clubs/${widget.clubId}/leave').catchError((_) => null); if (mounted) Navigator.pop(context); }

  Future<void> _postFeed() async {
    if (_post.text.trim().isEmpty) return;
    final body = _post.text.trim(); _post.clear();
    try { await Api.post('/clubs/${widget.clubId}/feed', {'content': body}); await _load(); } catch (_) {}
  }

  Future<void> _newCompetition() async {
    final name = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Competitie aanmaken'),
      content: TextField(controller: name, decoration: const InputDecoration(labelText: 'Naam')),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuleren')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Aanmaken'))],
    ));
    if (ok != true || name.text.trim().isEmpty) return;
    try { await Api.post('/clubs/${widget.clubId}/competitions', {'name': name.text.trim()}); _load(); } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final c = _club!;
    final members = (c['members'] ?? []) as List;
    final comps = (c['competitions'] ?? []) as List;
    final role = c['my_role'];
    final isMember = role != null;
    final canManage = role == 'owner' || role == 'admin';
    return Scaffold(
      appBar: AppBar(title: Text(c['name'] ?? 'Club'), actions: [
        if (isMember && role != 'owner') IconButton(icon: const Icon(Icons.logout), tooltip: 'Verlaten', onPressed: _leave),
      ]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        if ((c['description'] ?? '').toString().isNotEmpty) Text(c['description'], style: const TextStyle(fontSize: 15)),
        const SizedBox(height: 12),
        Row(children: [
          Text('${c['members_count'] ?? 0} leden', style: const TextStyle(color: Colors.black54)),
          const Spacer(),
          if (!isMember) FilledButton(onPressed: _busy ? null : _join, child: const Text('Lid worden')) else const Chip(label: Text('Je bent lid')),
        ]),
        if (isMember) ...[
          const Divider(height: 28),
          const Text('Clubfeed', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: TextField(controller: _post, decoration: const InputDecoration(hintText: 'Deel iets met de club…'))),
            IconButton.filled(style: IconButton.styleFrom(backgroundColor: AppColors.teal), onPressed: _postFeed, icon: const Icon(Icons.send)),
          ]),
          const SizedBox(height: 8),
          ..._feed.map((f) { final u = f['user'] as Map?; return Card(child: ListTile(
            leading: Avatar(name: u?['username'], src: u?['avatar_path'], size: 36),
            title: Text(u?['username'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: Text(f['content'] ?? ''))); }),
        ],
        const Divider(height: 28),
        Row(children: [
          const Text('Competities', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy)),
          const Spacer(),
          if (canManage) TextButton.icon(onPressed: _newCompetition, icon: const Icon(Icons.add, size: 18), label: const Text('Nieuw')),
        ]),
        if (comps.isEmpty) const Padding(padding: EdgeInsets.all(8), child: Text('Nog geen competities', style: TextStyle(color: Colors.black45))),
        ...comps.map((t) => Card(child: ListTile(leading: const Icon(Icons.emoji_events, color: AppColors.teal), title: Text(t['name'] ?? ''), subtitle: Text('${t['participants_count'] ?? 0} deelnemers')))),
        const Divider(height: 28),
        const Text('Leden', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy)),
        const SizedBox(height: 8),
        ...members.map((m) => ListTile(contentPadding: EdgeInsets.zero, leading: Avatar(name: m['username'], src: m['avatar_path'], size: 36), title: Text(m['username'] ?? ''), trailing: Text(m['role'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.black45)))),
      ]),
    );
  }
}
