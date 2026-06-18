import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../core/api.dart';
import '../core/auth.dart';
import '../core/config.dart';
import '../core/realtime_service.dart';
import '../core/i18n.dart';
import '../widgets/avatar.dart';
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
    } catch (_) {} finally { setState(() => _posting = false); }
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

  void _openComments(Map p) => showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => _CommentsSheet(postId: p['id']));

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
                Expanded(child: TextField(controller: _composer, maxLines: null, decoration: InputDecoration(hintText: context.tr('feed.composerHint'), border: InputBorder.none, filled: false))),
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
              if (!mine) IconButton(icon: const Icon(Icons.flag_outlined, size: 18, color: Colors.black26), onPressed: () => showReportSheet(context, type: 'post', targetId: p['id'])),
              if (mine) IconButton(icon: const Icon(Icons.delete_outline, size: 19, color: Colors.black26), onPressed: () => _deletePost(p)),
            ]),
            if ((p['content'] ?? '').toString().trim().isNotEmpty) ...[
              Padding(padding: const EdgeInsets.only(top: 8), child: Text((_trans[p['id']]?['shown'] == true && _trans[p['id']]?['content'] != null) ? _trans[p['id']]!['content'] : p['content'], style: const TextStyle(fontSize: 15))),
              Padding(padding: const EdgeInsets.only(top: 4), child: InkWell(onTap: () => _translate(p), child: Row(mainAxisSize: MainAxisSize.min, children: [
                _trans[p['id']]?['busy'] == true ? const SizedBox(height: 12, width: 12, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal)) : const Icon(Icons.translate, size: 14, color: AppColors.teal),
                const SizedBox(width: 4),
                Text(_trans[p['id']]?['shown'] == true ? context.tr('feed.show_original') : context.tr('feed.translate'), style: const TextStyle(fontSize: 12, color: AppColors.teal, fontWeight: FontWeight.w600)),
              ]))),
            ],
            if (p['image_path'] != null) Padding(padding: const EdgeInsets.only(top: 10), child: ClipRRect(borderRadius: BorderRadius.circular(12), child: CachedNetworkImage(imageUrl: p['image_path'], width: double.infinity, fit: BoxFit.cover))),
            const Divider(height: 22),
            Row(children: [
              InkWell(onTap: () => _toggleLike(p), child: Row(children: [Icon(Icons.thumb_up, size: 18, color: p['liked_by_me'] == true ? AppColors.teal : Colors.black38), const SizedBox(width: 5), Text('${p['likes_count'] ?? 0}')])),
              const SizedBox(width: 20),
              InkWell(onTap: () => _openComments(p), child: Row(children: [const Icon(Icons.mode_comment_outlined, size: 18, color: Colors.black38), const SizedBox(width: 5), Text('${p['comments_count'] ?? 0}')])),
            ]),
          ])));
        },
      ),
    );
  }
}

class _CommentsSheet extends StatefulWidget {
  final int postId;
  const _CommentsSheet({required this.postId});
  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  List _comments = [];
  final _input = TextEditingController();
  bool _loading = true;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try { final r = await Api.get('/posts/${widget.postId}/comments'); setState(() { _comments = r['data'] ?? []; _loading = false; }); }
    catch (_) { setState(() => _loading = false); }
  }
  Future<void> _add() async {
    if (_input.text.trim().isEmpty) return;
    final body = _input.text.trim(); _input.clear();
    try { final c = await Api.post('/posts/${widget.postId}/comments', {'body': body}); setState(() => _comments.insert(0, c)); } catch (_) {}
  }
  @override
  Widget build(BuildContext context) {
    return Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(height: MediaQuery.of(context).size.height * 0.7, child: Column(children: [
        Padding(padding: const EdgeInsets.all(12), child: Text(context.tr('feed.comments'), style: const TextStyle(fontWeight: FontWeight.bold))),
        Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) : ListView(padding: const EdgeInsets.symmetric(horizontal: 12), children: _comments.map((c) {
          final u = c['user'] as Map?;
          return ListTile(leading: Avatar(name: u?['username'], src: u?['avatar_path'], size: 32), title: Text(u?['username'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), subtitle: Text(c['body'] ?? ''));
        }).toList())),
        SafeArea(child: Padding(padding: const EdgeInsets.all(8), child: Row(children: [
          Expanded(child: TextField(controller: _input, decoration: InputDecoration(hintText: context.tr('feed.commentHint')))),
          IconButton.filled(style: IconButton.styleFrom(backgroundColor: AppColors.teal), onPressed: _add, icon: const Icon(Icons.send)),
        ]))),
      ])));
  }
}
