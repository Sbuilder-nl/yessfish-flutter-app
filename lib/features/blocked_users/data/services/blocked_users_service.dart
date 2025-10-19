import "package:dio/dio.dart";
import "../../../../core/api/dio_client.dart";

class BlockedUsersService {
  late final Dio _dio;
  bool _initialized = false;

  Future<void> _init() async {
    if (_initialized) return;
    final client = await DioClient.getInstance();
    _dio = client.dio;
    _initialized = true;
  }

  /// Get list of blocked users
  Future<List<Map<String, dynamic>>> getBlockedUsers() async {
    await _init();
    
    try {
      final response = await _dio.get("/blocked-users.php");

      if (response.data["success"] == true) {
        return List<Map<String, dynamic>>.from(response.data["blocked_users"] ?? []);
      } else {
        throw Exception(response.data["error"] ?? "Geblokkeerde gebruikers ophalen mislukt");
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response!.data["error"] ?? "Geblokkeerde gebruikers ophalen mislukt");
      } else {
        throw Exception("Geen internet verbinding");
      }
    }
  }

  /// Block a user
  Future<void> blockUser(String userId) async {
    await _init();
    
    try {
      final response = await _dio.post(
        "/blocked-users.php",
        data: {"blocked_user_id": userId},
      );

      if (response.data["success"] != true) {
        throw Exception(response.data["error"] ?? "Blokkeren mislukt");
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response!.data["error"] ?? "Blokkeren mislukt");
      } else {
        throw Exception("Geen internet verbinding");
      }
    }
  }

  /// Unblock a user
  Future<void> unblockUser(String userId) async {
    await _init();
    
    try {
      final response = await _dio.delete(
        "/blocked-users.php",
        data: {"blocked_user_id": userId},
      );

      if (response.data["success"] != true) {
        throw Exception(response.data["error"] ?? "Deblokkeren mislukt");
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response!.data["error"] ?? "Deblokkeren mislukt");
      } else {
        throw Exception("Geen internet verbinding");
      }
    }
  }
}
