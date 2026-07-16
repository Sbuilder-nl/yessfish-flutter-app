import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../core/api.dart';
import '../core/auth.dart';
import '../core/config.dart';
import '../core/realtime_service.dart';
import '../core/i18n.dart';
import '../widgets/avatar.dart';
import '../widgets/photo_viewer.dart';
import '../widgets/report.dart';
import 'user_profile_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});
  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List _posts = [];
  bool _loading = true;
  final _composer = TextEditingController();
  String? _photoPath, _photoUrl;
  bool _posting = false;
  final Map<int, Map> _trans = {}; // post-id → {content, shown, busy}
  StreamSubscription? _liveSub;

  @override
  void initState() {
    super.initState();
    _load();
    _liveSub = context.read<RealtimeService>().feedPosts.listen((post) {
      if (mounted && !_posts.any((p) => p['id'] == post['id'])) setState(() => _posts.insert(0, post));
    });
  }

  @override
  void dispose() { _liveSub?.cancel(); super.dispose(); }

  Future<void> _load() async {
    try { final r = await Api.get('/feed'); setState(() { _posts = r['data'] ?? []; _loading = false; }); }
    catch (_) { setState(() { _loading = false; }); }
  }

  Future<void> _pickPhoto(ImageSource src) async {
    XFile? x;
    try { x = await ImagePicker().pickImage(source: src, maxWidth: 1600, imageQuality: 85); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${src == ImageSource.camera ? context.tr('feed.openCameraFail') : context.tr('feed.openGalleryFail')}: $e'))); return; }
    if (x == null) return;
    try { final r = await Api.uploadImage(x.path); setState(() { _photoPath = r['path']; _photoUrl = r['url']; }); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? '${context.tr('feed.uploadFail')}: ${e.message}' : '${context.tr('feed.uploadFail')}: $e'))); }
  }

  Future<void> _post() async {
    if (_composer.text.trim().isEmpty && _photoPath == null) return;
    setState(() => _posting = true);
    try {
      await Api.post('/posts', {'content': _composer.text.trim().isEmpty ? ' ' : _composer.text.trim(), 'visibility': 'public', if (_photoPath != null) 'image_path': _photoPath});
      _composer.clear();
      setState(() { _photoPath = null; _photoUrl = null; });
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'Er ging iets mis')));
    } finally { setState(() => _posting = false); }
  }

  Future<void> _deletePost(Map p) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(context.tr('feed.deleteTitle')),
      content: Text(context.tr('feed.deleteBody')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('feed.no'))),
        FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.danger), onPressed: () => Navigator.pop(ctx, true), child: Text(context.tr('feed.delete'))),
      ]));
    if (ok != true) return;
    try { await Api.delete('/posts/${p['id']}'); _load(); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : context.tr('feed.deleteFail')))); }
  }

  Future<void> _toggleLike(Map p) async {
    final liked = p['liked_by_me'] == true;
    setState(() { p['liked_by_me'] = !liked; p['likes_count'] = (p['likes_count'] ?? 0) + (liked ? -1 : 1); });
    try { await (liked ? Api.delete('/posts/${p['id']}/like') : Api.post('/posts/${p['id']}/like')); } catch (_) { _load(); }
  }

  Future<void> _translate(Map p) async {
    final id = p['id'] as int;
    final cur = _trans[id];
    if (cur != null && cur['content'] != null) { setState(() => cur['shown'] = !(cur['shown'] == true)); return; }
    setState(() => _trans[id] = {'shown': false, 'busy': true});
    try {
      final loc = context.read<I18n>().locale;
      final r = await Api.post('/posts/$id/translate', {'lang': loc});
      setState(() => _trans[id] = {'content': r['content'], 'shown': r['same'] != true, 'busy': false});
    } catch (_) { setState(() => _trans.remove(id)); }
  }

  // Bewerken van een eigen bericht (tekst); zichtbaarheid en foto blijven staan.
  Future<void> _editPost(Map p) async {
    final c = TextEditingController(text: (p['content'] ?? '').toString());
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(context.tr('feed.edit_title')),
      content: TextField(controller: c, maxLines: 5, autofocus: true, textCapitalization: TextCapitalization.sentences),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('feed.cancel'))),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.tr('feed.save'))),
      ],
    ));
    if (ok != true || !mounted) return;
    try {
      final r = await Api.put('/posts/${p['id']}', {'content': c.text.trim()});
      final dynamic nc = (r is Map && r['data'] is Map) ? r['data']['content'] : null;
      setState(() => p['content'] = nc ?? c.text.trim());
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : '$e'))); }
  }

  void _openComments(Map p) {
    final meId = context.read<AuthState>().user?.id;
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => _CommentsSheet(
      postId: p['id'], meId: meId,
      onCount: (d) => setState(() => p['comments_count'] = (((p['comments_count'] ?? 0) as num).toInt() + d).clamp(0, 1 << 31)),
    ));
  }

  Widget _onlineBar(BuildContext context) {
    final rt = context.watch<RealtimeService>();
    if (rt.onlineCount == 0) return const SizedBox.shrink();
    final list = rt.online;
    return Card(margin: const EdgeInsets.only(bottom: 12), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), child: Row(children: [
      Container(width: 9, height: 9, decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Text('${rt.onlineCount} ${context.tr('online.now')}', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.navy)),
      const SizedBox(width: 12),
      Expanded(child: SizedBox(height: 34, child: ListView.separated(
        scrollDirection: Axis.horizontal, itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) { final u = list[i]; return Avatar(name: u['username'], src: u['avatar_path'], size: 32); }))),
    ])));
  }

  @override
  Widget build(BuildContext context) {
    final me = context.read<AuthState>().user;
    if (_loading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _posts.length + 2,
        itemBuilder: (_, idx) {
          if (idx == 0) return _onlineBar(context);
          if (idx == 1) {
            return Card(margin: const EdgeInsets.only(bottom: 12), child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
              Row(children: [
                Avatar(name: me?.username, src: me?.avatarPath, size: 38), const SizedBox(width: 10),
                Expanded(child: TextField(controller: _composer, maxLines: null, textCapitalization: TextCapitalization.sentences, decoration: InputDecoration(hintText: context.tr('feed.composerHint'), border: InputBorder.none, filled: false))),
              ]),
              if (_photoUrl != null) Padding(padding: const EdgeInsets.only(top: 8), child: ClipRRect(borderRadius: BorderRadius.circular(10), child: CachedNetworkImage(imageUrl: _photoUrl!, height: 140, width: double.infinity, fit: BoxFit.cover))),
              Row(children: [
                IconButton(onPressed: () => _pickPhoto(ImageSource.camera), icon: const Icon(Icons.camera_alt, color: AppColors.teal), tooltip: context.tr('feed.camera')),
                IconButton(onPressed: () => _pickPhoto(ImageSource.gallery), icon: const Icon(Icons.photo, color: AppColors.teal), tooltip: context.tr('feed.gallery')),
                const Spacer(),
                FilledButton(onPressed: _posting ? null : _post, child: Text(context.tr('feed.post'))),
              ]),
            ])));
          }
          final p = _posts[idx - 2] as Map;
          final u = p['user'] as Map?;
          final mine = u?['username'] == me?.username;
          return Card(margin: const EdgeInsets.only(bottom: 12), child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              GestureDetector(onTap: (!mine && u?['id'] != null) ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(userId: u!['id']))) : null,
                child: Avatar(name: u?['username'], src: u?['avatar_path'], size: 38)), const SizedBox(width: 10),
              Expanded(child: GestureDetector(onTap: (!mine && u?['id'] != null) ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(userId: u!['id']))) : null,
                child: Text(u?['username'] ?? context.tr('feed.angler'), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy)))),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20, color: Colors.black26),
                onSelected: (v) {
                  if (v == 'edit') _editPost(p);
                  if (v == 'delete') _deletePost(p);
                  if (v == 'report') showReportSheet(context, type: 'post', targetId: p['id']);
                },
                itemBuilder: (_) => [
                  if (mine) PopupMenuItem(value: 'edit', child: Row(children: [const Icon(Icons.edit_outlined, size: 18, color: Colors.black54), const SizedBox(width: 8), Text(context.tr('feed.menu_edit'))])),
                  if (mine) PopupMenuItem(value: 'delete', child: Row(children: [const Icon(Icons.delete_outline, size: 18, color: Colors.red), const SizedBox(width: 8), Text(context.tr('feed.menu_delete'), style: const TextStyle(color: Colors.red))])),
                  if (!mine) PopupMenuItem(value: 'report', child: Row(children: [const Icon(Icons.flag_outlined, size: 18, color: Colors.black54), const SizedBox(width: 8), Text(context.tr('feed.menu_report'))])),
                ],
              ),
            ]),
            if ((p['content'] ?? '').toString().trim().isNotEmpty) ...[
              Padding(padding: const EdgeInsets.only(top: 8), child: Text((_trans[p['id']]?['shown'] == true && _trans[p['id']]?['content'] != null) ? _trans[p['id']]!['content'] : p['content'], style: const TextStyle(fontSize: 15))),
              Padding(padding: const EdgeInsets.only(top: 4), child: InkWell(onTap: () => _translate(p), child: Row(mainAxisSize: MainAxisSize.min, children: [
                _trans[p['id']]?['busy'] == true ? const SizedBox(height: 12, width: 12, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal)) : const Icon(Icons.translate, size: 14, color: AppColors.teal),
                const SizedBox(width: 4),
                Text(_trans[p['id']]?['shown'] == true ? context.tr('feed.show_original') : context.tr('feed.translate'), style: const TextStyle(fontSize: 12, color: AppColors.teal, fontWeight: FontWeight.w600)),
              ]))),
            ],
            if (p['image_path'] != null) Padding(padding: const EdgeInsets.only(top: 10), child: GestureDetector(onTap: () => PhotoViewer.open(context, [p['image_path'].toString()]), child: ClipRRect(borderRadius: BorderRadius.circular(12), child: CachedNetworkImage(imageUrl: p['image_path'], width: double.infinity, fit: BoxFit.cover)))),
            const Divider(height: 22),
            Row(children: [
              InkWell(onTap: () => _toggleLike(p), child: Row(children: [Icon(Icons.thumb_up, size: 18, color: p['liked_by_me'] == true ? AppColors.teal : Colors.black38), const SizedBox(width: 5), Text('${p['likes_count'] ?? 0}')])),
              const SizedBox(width: 20),
              InkWell(onTap: () => _openComments(p), child: Row(children: [const Icon(Icons.mode_comment_outlined, size: 18, color: Colors.black38), const SizedBox(width: 5), Text('${p['comments_count'] ?? 0}')])),
              if ((p['visibility'] ?? 'public') == 'public') ...[
                const SizedBox(width: 20),
                InkWell(onTap: () {
                  Clipboard.setData(ClipboardData(text: 'https://yessfish.com/deel/bericht/${p['id']}'));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link gekopieerd — plak \'m om te delen 🔗')));
                }, child: const Row(children: [Icon(Icons.share_outlined, size: 18, color: Colors.black38), SizedBox(width: 5), Text('Delen', style: TextStyle(color: Colors.black54))])),
              ],
            ]),
          ])));
        },
      ),
    );
  }
}

class _CommentsSheet extends StatefulWidget {
  final int postId;
  final int? meId;
  final void Function(int delta) onCount;
  const _CommentsSheet({required this.postId, required this.meId, required this.onCount});
  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  List _comments = [];
  final _input = TextEditingController();
  bool _loading = true;
  Map? _replyTo; // reactie waarop geantwoord wordt (1 niveau)
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try { final r = await Api.get('/posts/${widget.postId}/comments'); setState(() { _comments = r['data'] ?? []; _loading = false; }); }
    catch (_) { setState(() => _loading = false); }
  }
  // Top-level reacties (of wees-antwoorden) met hun antwoorden ingesprongen eronder.
  List<Widget> _grouped(BuildContext context) {
    final ids = _comments.map((c) => c['id']).toSet();
    final tops = _comments.where((c) => c['parent_id'] == null || !ids.contains(c['parent_id'])).toList();
    final out = <Widget>[];
    for (final c in tops) {
      out.add(_row(context, c, false));
      final kids = _comments.where((k) => k['parent_id'] == c['id']).toList().reversed;
      for (final k in kids) { out.add(Padding(padding: const EdgeInsets.only(left: 34), child: _row(context, k, true))); }
    }
    return out;
  }

  Widget _row(BuildContext context, dynamic c, bool isReply) {
    final u = c['user'] as Map?;
    final mineC = widget.meId != null && (c['user_id'] == widget.meId || u?['id'] == widget.meId);
    return ListTile(
      dense: isReply,
      contentPadding: EdgeInsets.zero,
      leading: Avatar(name: u?['username'], src: u?['avatar_path'], size: isReply ? 26 : 32),
      title: Text(u?['username'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(c['body'] ?? ''),
        if (!isReply) InkWell(onTap: () => setState(() => _replyTo = c), child: Padding(padding: const EdgeInsets.only(top: 2), child: Text(context.tr('feed.reply'), style: const TextStyle(fontSize: 11, color: AppColors.teal, fontWeight: FontWeight.w600)))),
      ]),
      trailing: mineC ? IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.black26), onPressed: () => _del(c)) : null,
    );
  }

  Future<void> _del(Map c) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      content: Text(context.tr('feed.comment_del_confirm')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('feed.cancel'))),
        FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(ctx, true), child: Text(context.tr('feed.menu_delete'))),
      ],
    ));
    if (ok != true || !mounted) return;
    try {
      await Api.delete('/posts/${widget.postId}/comments/${c['id']}');
      setState(() => _comments.remove(c)); widget.onCount(-1);
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : '$e'))); }
  }

  Future<void> _add() async {
    if (_input.text.trim().isEmpty) return;
    final body = _input.text.trim(); _input.clear();
    final parentId = _replyTo?['id'];
    try { final c = await Api.post('/posts/${widget.postId}/comments', {'body': body, if (parentId != null) 'parent_id': parentId}); setState(() { _comments.insert(0, c); _replyTo = null; }); widget.onCount(1); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'Er ging iets mis'))); }
  }
  @override
  Widget build(BuildContext context) {
    return Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(height: MediaQuery.of(context).size.height * 0.7, child: Column(children: [
        Padding(padding: const EdgeInsets.all(12), child: Text(context.tr('feed.comments'), style: const TextStyle(fontWeight: FontWeight.bold))),
        Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) : ListView(padding: const EdgeInsets.symmetric(horizontal: 12), children: _grouped(context))),
        if (_replyTo != null) Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Row(children: [
          Expanded(child: Text('${context.tr('feed.replying_to')} ${(_replyTo!['user'] as Map?)?['username'] ?? ''}', style: const TextStyle(fontSize: 12, color: AppColors.teal, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
          IconButton(icon: const Icon(Icons.close, size: 16, color: Colors.black38), onPressed: () => setState(() => _replyTo = null)),
        ])),
        SafeArea(child: Padding(padding: const EdgeInsets.all(8), child: Row(children: [
          Expanded(child: TextField(controller: _input, textCapitalization: TextCapitalization.sentences, decoration: InputDecoration(hintText: context.tr('feed.commentHint')))),
          IconButton.filled(style: IconButton.styleFrom(backgroundColor: AppColors.teal), onPressed: _add, icon: const Icon(Icons.send)),
        ]))),
      ])));
  }
}
