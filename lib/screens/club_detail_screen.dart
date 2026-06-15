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
  bool _loading = true, _busy = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final r = await Api.get('/clubs/${widget.clubId}');
      setState(() { _club = r; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _join() async {
    setState(() => _busy = true);
    try { await Api.post('/clubs/${widget.clubId}/join'); await _load(); } catch (_) {}
    setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final c = _club!;
    final members = (c['members'] ?? []) as List;
    final comps = (c['competitions'] ?? []) as List;
    final isMember = c['my_role'] != null;
    return Scaffold(
      appBar: AppBar(title: Text(c['name'] ?? 'Club')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        if ((c['description'] ?? '').toString().isNotEmpty) Text(c['description'], style: const TextStyle(fontSize: 15)),
        const SizedBox(height: 12),
        Row(children: [
          Text('${c['members_count'] ?? 0} leden', style: const TextStyle(color: Colors.black54)),
          const Spacer(),
          if (!isMember) FilledButton(onPressed: _busy ? null : _join, child: const Text('Lid worden'))
          else const Chip(label: Text('Je bent lid')),
        ]),
        const Divider(height: 28),
        const Text('Leden', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy)),
        const SizedBox(height: 8),
        ...members.map((m) => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Avatar(name: m['username'], src: m['avatar_path'], size: 36),
          title: Text(m['username'] ?? ''),
          trailing: Text(m['role'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.black45)),
        )),
        if (comps.isNotEmpty) ...[
          const Divider(height: 28),
          const Text('Competities', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy)),
          const SizedBox(height: 8),
          ...comps.map((t) => Card(child: ListTile(
            leading: const Icon(Icons.emoji_events, color: AppColors.teal),
            title: Text(t['name'] ?? ''),
            subtitle: Text('${t['participants_count'] ?? 0} deelnemers'),
          ))),
        ],
      ]),
    );
  }
}
