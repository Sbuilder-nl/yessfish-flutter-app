import 'package:flutter/material.dart';
import '../../domain/models/post.dart';
import '../../data/services/posts_service.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final PostsService _postsService = PostsService();
  final List<Post> _posts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final posts = await _postsService.getFeedPosts();
      setState(() {
        _posts.clear();
        _posts.addAll(posts);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLike(String postId, int index) async {
    try {
      await _postsService.likePost(postId);
      // Reload feed to get updated counts
      await _loadPosts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout bij liken: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _handleComment(String postId) async {
    final controller = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reageren'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Schrijf een reactie...'),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ANNULEREN'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                try {
                  await _postsService.addComment(postId, controller.text.trim());
                  Navigator.pop(context);
                  await _loadPosts();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Reactie geplaatst!')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Fout: ${e.toString()}')),
                    );
                  }
                }
              }
            },
            child: const Text('PLAATSEN'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Fout bij laden feed'),
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPosts,
              child: const Text('Opnieuw proberen'),
            ),
          ],
        ),
      );
    }

    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.post_add, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Nog geen posts'),
            const SizedBox(height: 8),
            const Text(
              'Wees de eerste om iets te delen!',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPosts,
      child: ListView.builder(
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          final post = _posts[index];
          return _PostCard(
            post: post,
            onLike: () => _handleLike(post.id, index),
            onComment: () => _handleComment(post.id),
          );
        },
      ),
    );
  }
}
class _PostCard extends StatefulWidget {
  final Post post;
  final VoidCallback onLike;
  final VoidCallback onComment;

  const _PostCard({
    required this.post,
    required this.onLike,
    required this.onComment,
  });

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  final _postsService = PostsService();
  List<Map<String, dynamic>> _comments = [];
  bool _loadingComments = false;
  bool _showAllComments = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    setState(() => _loadingComments = true);
    try {
      final comments = await _postsService.getComments(widget.post.id);
      setState(() {
        _comments = comments;
        _loadingComments = false;
      });
    } catch (e) {
      setState(() => _loadingComments = false);
      print("Error loading comments: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayedComments = _showAllComments 
        ? _comments 
        : _comments.take(3).toList();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundImage: widget.post.profilePhoto != null
                  ? NetworkImage(widget.post.profilePhoto!)
                  : null,
              child: widget.post.profilePhoto == null
                  ? Text(
                      widget.post.userName[0].toUpperCase(),
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    )
                  : null,
            ),
            title: Text(widget.post.userName),
            subtitle: Row(
              children: [
                Text(widget.post.timeAgo),
                if (widget.post.location != null) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.location_on, size: 12),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      widget.post.location!,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(widget.post.content),
          ),
          const SizedBox(height: 8),
          if (widget.post.imageUrl != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  widget.post.imageUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.image_not_supported,
                        size: 48,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    );
                  },
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.favorite_border),
                  onPressed: widget.onLike,
                ),
                Text("${widget.post.likesCount}"),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.comment_outlined),
                  onPressed: widget.onComment,
                ),
                Text("${_comments.length}"),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Delen komt binnenkort!")),
                    );
                  },
                ),
              ],
            ),
          ),
          if (_comments.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...displayedComments.map((comment) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundImage: comment["profile_photo"] != null
                              ? NetworkImage(comment["profile_photo"])
                              : null,
                          child: comment["profile_photo"] == null
                              ? Text(
                                  (comment["user_name"] ?? "?")[0].toUpperCase(),
                                  style: const TextStyle(fontSize: 12),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    comment["user_name"] ?? "Onbekend",
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    comment["time_ago"] ?? "",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(comment["comment"] ?? comment["content"] ?? ""),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
                  if (_comments.length > 3 && !_showAllComments)
                    TextButton.icon(
                      onPressed: () {
                        setState(() => _showAllComments = true);
                      },
                      icon: const Icon(Icons.expand_more),
                      label: Text("Lees meer (${_comments.length - 3} reacties)"),
                    ),
                  if (_showAllComments)
                    TextButton.icon(
                      onPressed: () {
                        setState(() => _showAllComments = false);
                      },
                      icon: const Icon(Icons.expand_less),
                      label: const Text("Toon minder"),
                    ),
                ],
              ),
            ),
          ],
          if (_loadingComments)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
