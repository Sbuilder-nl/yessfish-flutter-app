import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../core/api.dart';
import '../core/auth.dart';
import '../core/config.dart';
import '../widgets/avatar.dart';
import '../widgets/report.dart';

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

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try { final r = await Api.get('/feed'); setState(() { _posts = r['data'] ?? []; _loading = false; }); }
    catch (_) { setState(() { _loading = false; }); }
  }

  Future<void> _pickPhoto() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
    if (x == null) return;
    try { final r = await Api.uploadImage(x.path); setState(() { _photoPath = r['path']; _photoUrl = r['url']; }); } catch (_) {}
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

  Future<void> _toggleLike(Map p) async {
    final liked = p['liked_by_me'] == true;
    setState(() { p['liked_by_me'] = !liked; p['likes_count'] = (p['likes_count'] ?? 0) + (liked ? -1 : 1); });
    try { await (liked ? Api.delete('/posts/${p['id']}/like') : Api.post('/posts/${p['id']}/like')); } catch (_) { _load(); }
  }

  @override
  Widget build(BuildContext context) {
    final me = context.read<AuthState>().user;
    if (_loading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _posts.length + 1,
        itemBuilder: (_, idx) {
          if (idx == 0) {
            return Card(margin: const EdgeInsets.only(bottom: 12), child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
              Row(children: [
                Avatar(name: me?.username, src: me?.avatarPath, size: 38), const SizedBox(width: 10),
                Expanded(child: TextField(controller: _composer, maxLines: null, decoration: const InputDecoration(hintText: 'Deel je vangst of nieuws…', border: InputBorder.none, filled: false))),
              ]),
              if (_photoUrl != null) Padding(padding: const EdgeInsets.only(top: 8), child: ClipRRect(borderRadius: BorderRadius.circular(10), child: CachedNetworkImage(imageUrl: _photoUrl!, height: 140, width: double.infinity, fit: BoxFit.cover))),
              Row(children: [
                IconButton(onPressed: _pickPhoto, icon: const Icon(Icons.photo, color: AppColors.teal)),
                const Spacer(),
                FilledButton(onPressed: _posting ? null : _post, child: const Text('Plaatsen')),
              ]),
            ])));
          }
          final p = _posts[idx - 1] as Map;
          final u = p['user'] as Map?;
          final mine = u?['username'] == me?.username;
          return Card(margin: const EdgeInsets.only(bottom: 12), child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Avatar(name: u?['username'], src: u?['avatar_path'], size: 38), const SizedBox(width: 10),
              Expanded(child: Text(u?['username'] ?? 'Visser', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy))),
              if (!mine) IconButton(icon: const Icon(Icons.flag_outlined, size: 18, color: Colors.black26), onPressed: () => showReportSheet(context, type: 'post', targetId: p['id'])),
            ]),
            if ((p['content'] ?? '').toString().trim().isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(p['content'], style: const TextStyle(fontSize: 15))),
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

  void _openComments(Map p) {
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => _CommentsSheet(postId: p['id']));
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
        const Padding(padding: EdgeInsets.all(12), child: Text('Reacties', style: TextStyle(fontWeight: FontWeight.bold))),
        Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) : ListView(padding: const EdgeInsets.symmetric(horizontal: 12), children: _comments.map((c) {
          final u = c['user'] as Map?;
          return ListTile(leading: Avatar(name: u?['username'], src: u?['avatar_path'], size: 32), title: Text(u?['username'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), subtitle: Text(c['body'] ?? ''));
        }).toList())),
        SafeArea(child: Padding(padding: const EdgeInsets.all(8), child: Row(children: [
          Expanded(child: TextField(controller: _input, decoration: const InputDecoration(hintText: 'Schrijf een reactie…'))),
          IconButton.filled(style: IconButton.styleFrom(backgroundColor: AppColors.teal), onPressed: _add, icon: const Icon(Icons.send)),
        ]))),
      ])));
  }
}
