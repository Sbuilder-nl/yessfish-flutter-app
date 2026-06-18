import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/api.dart';
import '../core/config.dart';
import '../core/i18n.dart';
import '../widgets/avatar.dart';
import '../widgets/report.dart';
import 'catch_detail_screen.dart';
import 'chat_screen.dart';

/// Profiel van een ándere gebruiker bekijken (zoals web /gebruiker/[id]).
class UserProfileScreen extends StatefulWidget {
  final int userId;
  const UserProfileScreen({super.key, required this.userId});
  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Map? _r;
  bool _loading = true, _busy = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try { final r = await Api.get('/users/${widget.userId}'); setState(() { _r = r is Map ? r : null; _loading = false; }); }
    catch (_) { setState(() => _loading = false); }
  }

  Future<void> _act(String status, dynamic friendshipId) async {
    setState(() => _busy = true);
    final m = ScaffoldMessenger.of(context);
    try {
      if (status == 'none') { await Api.post('/friends', {'addressee_id': widget.userId}); m.showSnackBar(SnackBar(content: Text(context.tr('userprofile.request_sent')))); }
      else if (status == 'pending_received' && friendshipId != null) { await Api.post('/friends/$friendshipId/accept'); m.showSnackBar(SnackBar(content: Text(context.tr('userprofile.friend_added')))); }
      await _load();
    } catch (e) { m.showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : context.tr('userprofile.failed')))); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_r == null) return Scaffold(body: Center(child: Text(context.tr('userprofile.not_found'))));
    final u = (_r!['data'] ?? {}) as Map;
    final status = (_r!['friendship_status'] ?? 'none').toString();
    final fid = _r!['friendship_id'];
    final catches = (_r!['recent_catches'] ?? []) as List;
    final tackle = (_r!['tackle'] ?? []) as List;

    Widget friendBtn() {
      switch (status) {
        case 'self': return const SizedBox.shrink();
        case 'friends': return Row(mainAxisSize: MainAxisSize.min, children: [
          Chip(avatar: const Icon(Icons.check, size: 16, color: AppColors.teal), label: Text(context.tr('userprofile.friends'))),
          const SizedBox(width: 8),
          FilledButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(recipientId: u['id'], recipientName: u['username']))), icon: const Icon(Icons.chat_bubble_outline, size: 18), label: Text(context.tr('userprofile.message'))),
        ]);
        case 'pending_sent': return OutlinedButton(onPressed: null, child: Text(context.tr('userprofile.request_pending')));
        case 'pending_received': return FilledButton.icon(onPressed: _busy ? null : () => _act(status, fid), icon: const Icon(Icons.check, size: 18), label: Text(context.tr('userprofile.accept_request')));
        case 'blocked': return Text(context.tr('userprofile.blocked'), style: const TextStyle(color: AppColors.danger));
        default: return FilledButton.icon(onPressed: _busy ? null : () => _act('none', null), icon: const Icon(Icons.person_add_alt, size: 18), label: Text(context.tr('userprofile.add_friend')));
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(u['username'] ?? context.tr('userprofile.title')), actions: [
        if (status != 'self') IconButton(icon: const Icon(Icons.flag_outlined), tooltip: context.tr('userprofile.report'), onPressed: () => showReportSheet(context, type: 'user', targetId: u['id'])),
      ]),
      body: RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.all(16), children: [
        const SizedBox(height: 6),
        Center(child: Avatar(name: u['username'], src: u['avatar_path'], size: 84)),
        const SizedBox(height: 10),
        Center(child: Text(u['first_name'] ?? u['username'] ?? '', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: AppColors.navy))),
        Center(child: Text('@${u['username'] ?? ''}', style: const TextStyle(color: Colors.black54))),
        if (u['bio'] != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(u['bio'], textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54))),
        if (u['city'] != null) Center(child: Padding(padding: const EdgeInsets.only(top: 4), child: Text('📍 ${u['city']}', style: const TextStyle(color: Colors.black45, fontSize: 13)))),
        const SizedBox(height: 14),
        Center(child: friendBtn()),
        const SizedBox(height: 18),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _stat('${_r!['catches_count'] ?? 0}', context.tr('userprofile.catches')),
          _stat('${_r!['posts_count'] ?? 0}', context.tr('userprofile.posts')),
        ]),
        if (catches.isNotEmpty) ...[
          const SizedBox(height: 22),
          Text(context.tr('userprofile.recent_catches'), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy)),
          const SizedBox(height: 8),
          GridView.count(crossAxisCount: 3, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 6, mainAxisSpacing: 6, children: catches.map<Widget>((c) {
            final cc = c as Map;
            return GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CatchDetailScreen(catchId: cc['id']))),
              child: ClipRRect(borderRadius: BorderRadius.circular(8), child: cc['photo_path'] != null
                ? CachedNetworkImage(imageUrl: cc['photo_path'], fit: BoxFit.cover, errorWidget: (_, __, ___) => _ph(context, cc))
                : _ph(context, cc)),
            );
          }).toList()),
        ],
        if (tackle.isNotEmpty) ...[
          const SizedBox(height: 22),
          Text(context.tr('userprofile.tackle'), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy)),
          const SizedBox(height: 8),
          ...tackle.map<Widget>((tt) { final t = tt as Map; return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
            leading: const Icon(Icons.phishing, color: AppColors.teal),
            title: Text(t['name'] ?? ''),
            subtitle: Text([t['category'], if (t['setup'] != null) t['setup']].where((e) => e != null).join(' · ')))); }),
        ],
        const SizedBox(height: 20),
      ])),
    );
  }

  Widget _ph(BuildContext context, Map c) => Container(color: AppColors.bg, alignment: Alignment.center, child: Padding(padding: const EdgeInsets.all(4), child: Text(c['species'] ?? context.tr('userprofile.fish'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.black45))));
  Widget _stat(String v, String l) => Column(children: [Text(v, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.teal)), Text(l, style: const TextStyle(color: Colors.black45, fontSize: 12))]);
}
