import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/config.dart';
import '../core/i18n.dart';
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
      title: Text(ctx.tr('clubdetail.comp_create_title')),
      content: TextField(controller: name, decoration: InputDecoration(labelText: ctx.tr('clubdetail.name_label'))),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.tr('clubdetail.cancel'))), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ctx.tr('clubdetail.create')))],
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
      appBar: AppBar(title: Text(c['name'] ?? context.tr('clubdetail.title')), actions: [
        if (isMember && role != 'owner') IconButton(icon: const Icon(Icons.logout), tooltip: context.tr('clubdetail.leave'), onPressed: _leave),
      ]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        if ((c['description'] ?? '').toString().isNotEmpty) Text(c['description'], style: const TextStyle(fontSize: 15)),
        const SizedBox(height: 12),
        Row(children: [
          Text('${c['members_count'] ?? 0} ${context.tr('clubdetail.members')}', style: const TextStyle(color: Colors.black54)),
          const Spacer(),
          if (!isMember) FilledButton(onPressed: _busy ? null : _join, child: Text(context.tr('clubdetail.join'))) else Chip(label: Text(context.tr('clubdetail.you_member'))),
        ]),
        if (isMember) ...[
          const Divider(height: 28),
          Text(context.tr('clubdetail.feed'), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: TextField(controller: _post, decoration: InputDecoration(hintText: context.tr('clubdetail.feed_hint')))),
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
          Text(context.tr('clubdetail.competitions'), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy)),
          const Spacer(),
          if (canManage) TextButton.icon(onPressed: _newCompetition, icon: const Icon(Icons.add, size: 18), label: Text(context.tr('clubdetail.new'))),
        ]),
        if (comps.isEmpty) Padding(padding: const EdgeInsets.all(8), child: Text(context.tr('clubdetail.no_competitions'), style: const TextStyle(color: Colors.black45))),
        ...comps.map((t) => Card(child: ListTile(leading: const Icon(Icons.emoji_events, color: AppColors.teal), title: Text(t['name'] ?? ''), subtitle: Text('${t['participants_count'] ?? 0} ${context.tr('clubdetail.participants')}')))),
        const Divider(height: 28),
        Text(context.tr('clubdetail.members_title'), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy)),
        const SizedBox(height: 8),
        ...members.map((m) => ListTile(contentPadding: EdgeInsets.zero, leading: Avatar(name: m['username'], src: m['avatar_path'], size: 36), title: Text(m['username'] ?? ''), trailing: Text(m['role'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.black45)))),
      ]),
    );
  }
}
