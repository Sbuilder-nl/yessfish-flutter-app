import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../models/user_model.dart';
import '../../../../core/api/api_constants.dart';

part 'friends_api_service.g.dart';

@RestApi(baseUrl: ApiConstants.baseUrl)
abstract class FriendsApiService {
  factory FriendsApiService(Dio dio, {String baseUrl}) = _FriendsApiService;

  /// Get friends list
  @GET(ApiConstants.friendsList)
  Future<HttpResponse<List<FriendshipModel>>> getFriendsList(
    @Query('page') int page,
    @Query('limit') int limit,
  );

  /// Get followers list
  @GET(ApiConstants.followers)
  Future<HttpResponse<List<UserModel>>> getFollowers(
    @Query('page') int page,
    @Query('limit') int limit,
  );

  /// Get following list
  @GET(ApiConstants.following)
  Future<HttpResponse<List<UserModel>>> getFollowing(
    @Query('page') int page,
    @Query('limit') int limit,
  );

  /// Get pending friend requests
  @GET(ApiConstants.friendRequests)
  Future<HttpResponse<List<FriendRequestModel>>> getFriendRequests();

  /// Send friend request
  @POST(ApiConstants.sendFriendRequest)
  Future<HttpResponse<FriendRequestModel>> sendFriendRequest(
    @Body() Map<String, dynamic> body,
  );

  /// Accept friend request
  @POST('${ApiConstants.friends}/accept/{id}')
  Future<HttpResponse<void>> acceptFriendRequest(@Path('id') int requestId);

  /// Reject friend request
  @POST('${ApiConstants.friends}/reject/{id}')
  Future<HttpResponse<void>> rejectFriendRequest(@Path('id') int requestId);

  /// Unfriend a user
  @DELETE('${ApiConstants.friends}/unfriend/{id}')
  Future<HttpResponse<void>> unfriend(@Path('id') int userId);

  /// Follow a user
  @POST('${ApiConstants.friends}/follow')
  Future<HttpResponse<void>> followUser(@Body() Map<String, dynamic> body);

  /// Unfollow a user
  @DELETE('${ApiConstants.friends}/unfollow/{id}')
  Future<HttpResponse<void>> unfollowUser(@Path('id') int userId);

  /// Search users
  @GET('${ApiConstants.users}/search')
  Future<HttpResponse<List<UserModel>>> searchUsers(
    @Query('q') String query,
    @Query('page') int page,
    @Query('limit') int limit,
  );

  /// Get user profile
  @GET('${ApiConstants.users}/{id}')
  Future<HttpResponse<UserModel>> getUserProfile(@Path('id') int userId);
}
