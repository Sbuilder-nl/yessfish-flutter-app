import 'package:dio/dio.dart';
import '../../domain/models/post.dart';
import '../../../../core/api/dio_client.dart';

class PostsService {
  late final Dio _dio;
  bool _initialized = false;

  PostsService();

  Future<void> _init() async {
    if (_initialized) return; // Already initialized
    
    final client = await DioClient.getInstance();
    _dio = client.dio;
    _initialized = true;
  }

  /// Fetch feed posts
  Future<List<Post>> getFeedPosts({int limit = 20, int offset = 0}) async {
    try {
      await _init();
      
      final response = await _dio.get(
        '/posts.php',
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
      );
      
      if (response.data['success'] == true) {
        final posts = (response.data['posts'] as List)
            .map((post) => Post.fromJson(post))
            .toList();
        return posts;
      } else {
        throw Exception(response.data['error'] ?? 'Failed to load posts');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  /// Create a new post
  Future<Post> createPost({
    required String content,
    String? imageUrl,
    String? location,
  }) async {
    try {
      await _init();
      
      final response = await _dio.post(
        '/posts.php',
        data: {
          'content': content,
          'image_url': imageUrl,
          'location': location,
        },
      );

      if (response.data['success'] == true) {
        return Post.fromJson(response.data['post']);
      } else {
        throw Exception(response.data['error'] ?? 'Failed to create post');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  /// Like a post
  Future<void> likePost(String postId) async {
    try {
      await _init();
      
      final response = await _dio.post(
        '/likes.php?action=like',
        data: {'post_id': postId},
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['error'] ?? 'Failed to like post');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  /// Unlike a post
  Future<void> unlikePost(String postId) async {
    try {
      await _init();
      
      final response = await _dio.post(
        '/likes.php?action=unlike',
        data: {'post_id': postId},
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['error'] ?? 'Failed to unlike post');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  /// Add a comment to a post
  Future<void> addComment(String postId, String comment) async {
    try {
      await _init();
      
      final response = await _dio.post(
        '/comments.php',
        data: {
          'post_id': postId,
          'comment': comment,
        },
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['error'] ?? 'Failed to add comment');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }
}
