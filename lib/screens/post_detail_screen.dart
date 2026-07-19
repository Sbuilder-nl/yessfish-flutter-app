import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../core/api.dart';
import '../core/auth.dart';
import '../core/config.dart';
import '../core/i18n.dart';
import '../widgets/avatar.dart';
import '../widgets/photo_viewer.dart';
import '../widgets/feed_video.dart';
import 'feed_screen.dart';
import 'user_profile_screen.dart';

/// Opent één post (bv. vanuit een melding "X reageerde op je bericht"). Toont de post + de reacties.
class PostDetailScreen extends StatefulWidget {
  final int postId;
  final bool openComments; // meteen de reacties tonen (bij comment-meldingen)
  const PostDetailScreen({super.key, required this.postId, this.openComments = false});
  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  Map? _post;
  bool _loading = true;
  bool _gone = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final r = await Api.get('/posts/${widget.postId}');
      final p = (r is Map && r['data'] is Map) ? r['data'] as Map : null;
      setState(() { _post = p; _loading = false; });
      if (p != null && widget.openComments) {
        WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) _openComments(); });
      }
    } catch (_) {
      setState(() { _gone = true; _loading = false; });
    }
  }

  Future<void> _toggleLike() async {
    final p = _post!; final liked = p['liked_by_me'] == true;
    setState(() { p['liked_by_me'] = !liked; p['likes_count'] = (p['likes_count'] ?? 0) + (liked ? -1 : 1); });
    try { await (liked ? Api.delete('/posts/${p['id']}/like') : Api.post('/posts/${p['id']}/like')); } catch (_) {}
  }

  void _openComments() {
    final meId = context.read<AuthState>().user?.id;
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => CommentsSheet(
      postId: _post!['id'], meId: meId,
      onCount: (d) => setState(() => _post!['comments_count'] = (((_post!['comments_count'] ?? 0) as num).toInt() + d).clamp(0, 1 << 31)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('notifs.post'))),
      body: _loading ? const Center(child: CircularProgressIndicator())
        : _gone || _post == null ? Center(child: Text(context.tr('notifs.post_gone'), style: const TextStyle(color: Colors.black45)))
        : _buildPost(context, _post!),
    );
  }

  Widget _buildPost(BuildContext context, Map p) {
    final u = p['user'] as Map?;
    return ListView(padding: const EdgeInsets.all(14), children: [
      Row(children: [
        GestureDetector(
          onTap: u?['id'] != null ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(userId: u!['id']))) : null,
          child: Avatar(name: u?['username'], src: u?['avatar_path'], size: 40)),
        const SizedBox(width: 10),
        Text(u?['username'] ?? context.tr('feed.angler'), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy, fontSize: 16)),
      ]),
      if ((p['content'] ?? '').toString().trim().isNotEmpty)
        Padding(padding: const EdgeInsets.only(top: 10), child: Text(p['content'], style: const TextStyle(fontSize: 15))),
      if (p['image_path'] != null)
        Padding(padding: const EdgeInsets.only(top: 10), child: GestureDetector(
          onTap: () => PhotoViewer.open(context, [p['image_path'].toString()]),
          child: ClipRRect(borderRadius: BorderRadius.circular(12), child: CachedNetworkImage(imageUrl: p['image_path'], width: double.infinity, fit: BoxFit.cover)))),
      if (p['video_path'] != null || p['youtube_id'] != null)
        Padding(padding: const EdgeInsets.only(top: 10), child: FeedVideo(
          videoUrl: p['video_path']?.toString(), poster: p['video_poster']?.toString(),
          youtubeId: p['youtube_id']?.toString(), ready: p['video_ready'] != false)),
      const Divider(height: 24),
      Row(children: [
        InkWell(onTap: _toggleLike, child: Row(children: [
          Icon(Icons.thumb_up, size: 20, color: p['liked_by_me'] == true ? AppColors.teal : Colors.black38),
          const SizedBox(width: 6), Text('${p['likes_count'] ?? 0}'),
        ])),
        const SizedBox(width: 24),
        InkWell(onTap: _openComments, child: Row(children: [
          const Icon(Icons.mode_comment_outlined, size: 20, color: Colors.black38),
          const SizedBox(width: 6), Text('${p['comments_count'] ?? 0}'),
        ])),
      ]),
      const SizedBox(height: 12),
      OutlinedButton.icon(onPressed: _openComments, icon: const Icon(Icons.forum_outlined, size: 18), label: Text(context.tr('notifs.view_comments'))),
    ]);
  }
}
