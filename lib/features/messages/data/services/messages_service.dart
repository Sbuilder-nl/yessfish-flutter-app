import 'package:dio/dio.dart';
import '../../../../core/api/dio_client.dart';

class MessagesService {
  late final Dio _dio;
  bool _initialized = false;

  Future<void> _init() async {
    if (_initialized) return;
    final client = await DioClient.getInstance();
    _dio = client.dio;
    _initialized = true;
  }

  /// Get all conversations
  Future<List<Map<String, dynamic>>> getConversations() async {
    await _init();
    
    try {
      final response = await _dio.get('/messages.php');

      if (response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['conversations'] ?? []);
      } else {
        throw Exception(response.data['error'] ?? 'Gesprekken ophalen mislukt');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response!.data['error'] ?? 'Gesprekken ophalen mislukt');
      } else {
        throw Exception('Geen internet verbinding');
      }
    }
  }

  /// Get messages with a specific user
  Future<List<Map<String, dynamic>>> getMessagesWithUser(String userId) async {
    await _init();
    
    try {
      final response = await _dio.get(
        '/messages.php',
        queryParameters: {'user_id': userId},
      );

      if (response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['messages'] ?? []);
      } else {
        throw Exception(response.data['error'] ?? 'Berichten ophalen mislukt');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response!.data['error'] ?? 'Berichten ophalen mislukt');
      } else {
        throw Exception('Geen internet verbinding');
      }
    }
  }

  /// Send a message
  Future<Map<String, dynamic>> sendMessage({
    required String receiverId,
    required String message,
  }) async {
    await _init();
    
    try {
      final response = await _dio.post(
        '/messages.php',
        data: {
          'receiver_id': receiverId,
          'message': message,
        },
      );

      if (response.data['success'] == true) {
        return response.data['message'];
      } else {
        throw Exception(response.data['error'] ?? 'Bericht versturen mislukt');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final error = e.response!.data['error'] ?? 'Bericht versturen mislukt';
        final reason = e.response!.data['reason'];
        throw Exception(reason != null ? '$error\\n$reason' : error);
      } else {
        throw Exception('Geen internet verbinding');
      }
    }
  }

  /// Mark messages as read
  Future<void> markAsRead(String userId) async {
    await _init();
    
    try {
      final response = await _dio.put(
        '/messages.php',
        data: {
          'user_id': userId,
          'action': 'mark_read',
        },
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['error'] ?? 'Markeren als gelezen mislukt');
      }
    } on DioException catch (e) {
      // Silent fail for read receipts
      print('Mark as read failed: $e');
    }
  }

  /// Delete conversation
  Future<void> deleteConversation(String userId) async {
    await _init();
    
    try {
      final response = await _dio.delete(
        '/messages.php',
        data: {'user_id': userId},
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
