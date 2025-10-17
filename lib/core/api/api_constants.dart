/// API Constants for YessFish Backend
class ApiConstants {
  // Base URL
  static const String baseUrl = 'https://yessfish.com/api';

  // API Version
  static const String apiVersion = 'v1';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Endpoints
  static const String auth = '/auth';
  static const String login = '$auth/login';
  static const String register = '$auth/register';
  static const String logout = '$auth/logout';
  static const String refreshToken = '$auth/refresh';

  static const String users = '/users';
  static const String profile = '$users/profile';

  static const String posts = '/posts';
  static const String createPost = posts;
  static const String deletePost = '$posts/{id}';
  static const String likePost = '$posts/{id}/like';
  static const String commentPost = '$posts/{id}/comments';

  static const String friends = '/friends';
  static const String friendRequests = '$friends/requests';
  static const String friendsList = '$friends/list';
  static const String sendFriendRequest = '$friends/request';
  static const String acceptFriendRequest = '$friends/accept/{id}';
  static const String rejectFriendRequest = '$friends/reject/{id}';
  static const String unfriend = '$friends/unfriend/{id}';
  static const String followers = '$friends/followers';
  static const String following = '$friends/following';

  static const String catches = '/catches';
  static const String createCatch = catches;
  static const String userCatches = '$catches/user/{userId}';

  static const String spots = '/spots';
  static const String premiumSpots = '$spots/premium';

  static const String notifications = '/notifications';
  static const String markNotificationRead = '$notifications/{id}/read';
  static const String markAllNotificationsRead = '$notifications/read-all';

  // Headers
  static const String headerAuthorization = 'Authorization';
  static const String headerContentType = 'Content-Type';
  static const String headerAccept = 'Accept';

  // Content Types
  static const String contentTypeJson = 'application/json';
  static const String contentTypeFormData = 'multipart/form-data';
}
