import 'package:dio/dio.dart';
import '../../../../core/api/dio_client.dart';

class FriendsService {
  late final Dio _dio;
  bool _initialized = false;

  Future<void> _init() async {
    if (_initialized) return;
    final client = await DioClient.getInstance();
    _dio = client.dio;
    _initialized = true;
  }

  /// Get friends list
  Future<List<Map<String, dynamic>>> getFriends() async {
    await _init();
    
    try {
      final response = await _dio.get('/friends.php');

      if (response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['friends'] ?? []);
      } else {
        throw Exception(response.data['error'] ?? 'Vrienden ophalen mislukt');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response!.data['error'] ?? 'Vrienden ophalen mislukt');
      } else {
        throw Exception('Geen internet verbinding');
      }
    }
  }

  /// Get friend requests (received)
  Future<List<Map<String, dynamic>>> getFriendRequests() async {
    await _init();
    
    try {
      final response = await _dio.get(
        '/friends.php',
        queryParameters: {'type': 'requests'},
      );

      if (response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['requests'] ?? []);
      } else {
        throw Exception(response.data['error'] ?? 'Verzoeken ophalen mislukt');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response!.data['error'] ?? 'Verzoeken ophalen mislukt');
      } else {
        throw Exception('Geen internet verbinding');
      }
    }
  }

  /// Send friend request
  Future<void> sendFriendRequest(String friendId) async {
    await _init();
    
    try {
      final response = await _dio.post(
        '/friends.php',
        data: {'friend_id': friendId},
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['error'] ?? 'Verzoek versturen mislukt');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response!.data['error'] ?? 'Verzoek versturen mislukt');
      } else {
        throw Exception('Geen internet verbinding');
      }
    }
  }

  /// Accept friend request
  Future<void> acceptFriendRequest(String requestId) async {
    await _init();
    
    try {
      final response = await _dio.put(
        '/friends.php',
        data: {
          'request_id': requestId,
          'action': 'accept',
        },
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['error'] ?? 'Accepteren mislukt');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response!.data['error'] ?? 'Accepteren mislukt');
      } else {
        throw Exception('Geen internet verbinding');
      }
    }
  }

  /// Decline friend request
  Future<void> declineFriendRequest(String requestId) async {
    await _init();
    
    try {
      final response = await _dio.put(
        '/friends.php',
        data: {
          'request_id': requestId,
          'action': 'decline',
        },
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['error'] ?? 'Afwijzen mislukt');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response!.data['error'] ?? 'Afwijzen mislukt');
      } else {
        throw Exception('Geen internet verbinding');
      }
    }
  }

  /// Remove friend
  Future<void> removeFriend(String friendId) async {
    await _init();
    
    try {
      final response = await _dio.delete(
        '/friends.php',
        data: {'friend_id': friendId},
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['error'] ?? 'Verwijderen mislukt');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response!.data['error'] ?? 'Verwijderen mislukt');
      } else {
        throw Exception('Geen internet verbinding');
      }
    }
  }
}
