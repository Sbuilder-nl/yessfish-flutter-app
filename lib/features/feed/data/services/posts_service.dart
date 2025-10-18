import 'package:dio/dio.dart';
import '../../domain/models/post.dart';
import '../../../../core/api/dio_client.dart';

class PostsService {
  final Dio _dio = DioClient.instance;

  /// Fetch feed posts
  Future<List<Post>> getFeedPosts({int limit = 20, int offset = 0}) async {
    try {
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
}
