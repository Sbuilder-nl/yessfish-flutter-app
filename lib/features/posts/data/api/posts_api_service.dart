import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../models/post_model.dart';
import '../../../../core/api/api_constants.dart';

part 'posts_api_service.g.dart';

@RestApi(baseUrl: ApiConstants.baseUrl)
abstract class PostsApiService {
  factory PostsApiService(Dio dio, {String baseUrl}) = _PostsApiService;

  /// Get dashboard feed
  @GET(ApiConstants.posts)
  Future<HttpResponse<List<PostModel>>> getFeed(
    @Query('page') int page,
    @Query('limit') int limit,
  );

  /// Get user posts
  @GET('${ApiConstants.posts}/user/{userId}')
  Future<HttpResponse<List<PostModel>>> getUserPosts(
    @Path('userId') int userId,
    @Query('page') int page,
    @Query('limit') int limit,
  );

  /// Create new post
  @POST(ApiConstants.createPost)
  @MultiPart()
  Future<HttpResponse<PostModel>> createPost(
    @Part(name: 'content') String content,
    @Part(name: 'image') File? image,
  );

  /// Delete post
  @DELETE('${ApiConstants.posts}/{id}')
  Future<HttpResponse<void>> deletePost(@Path('id') int postId);

  /// Like/unlike post
  @POST('${ApiConstants.posts}/{id}/like')
  Future<HttpResponse<void>> toggleLikePost(@Path('id') int postId);

  /// Get post comments
  @GET('${ApiConstants.posts}/{id}/comments')
  Future<HttpResponse<List<CommentModel>>> getPostComments(
    @Path('id') int postId,
    @Query('page') int page,
    @Query('limit') int limit,
  );

  /// Add comment to post
  @POST('${ApiConstants.posts}/{id}/comments')
  Future<HttpResponse<CommentModel>> addComment(
    @Path('id') int postId,
    @Body() CreateCommentRequest request,
  );

  /// Delete comment
  @DELETE('${ApiConstants.posts}/comments/{id}')
  Future<HttpResponse<void>> deleteComment(@Path('id') int commentId);

  /// Save/unsave post
  @POST('${ApiConstants.posts}/{id}/save')
  Future<HttpResponse<void>> toggleSavePost(@Path('id') int postId);

  /// Share post
  @POST('${ApiConstants.posts}/{id}/share')
  Future<HttpResponse<void>> sharePost(@Path('id') int postId);
}
