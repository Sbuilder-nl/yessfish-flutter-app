import 'package:dio/dio.dart';
import '../../../../core/api/dio_client.dart';

class PrivacyService {
  late final Dio _dio;
  bool _initialized = false;

  Future<void> _init() async {
    if (_initialized) return;
    final client = await DioClient.getInstance();
    _dio = client.dio;
    _initialized = true;
  }

  /// Get privacy settings
  Future<Map<String, dynamic>> getPrivacySettings() async {
    await _init();
    
    try {
      final response = await _dio.get('/privacy-settings.php');

      if (response.data['success'] == true) {
        return response.data['settings'];
      } else {
        throw Exception(response.data['error'] ?? 'Privacy settings ophalen mislukt');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response!.data['error'] ?? 'Privacy settings ophalen mislukt');
      } else {
        throw Exception('Geen internet verbinding');
      }
    }
  }

  /// Update privacy settings
  Future<void> updatePrivacySettings({
    String? commentPrivacy,
    String? messagePrivacy,
    bool? profilePublic,
  }) async {
    await _init();
    
    try {
      final data = <String, dynamic>{};
      
      if (commentPrivacy != null) data['comment_privacy'] = commentPrivacy;
      if (messagePrivacy != null) data['message_privacy'] = messagePrivacy;
      if (profilePublic != null) data['profile_public'] = profilePublic ? 1 : 0;

      final response = await _dio.put(
        '/privacy-settings.php',
        data: data,
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['error'] ?? 'Privacy instellingen opslaan mislukt');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response!.data['error'] ?? 'Privacy instellingen opslaan mislukt');
      } else {
        throw Exception('Geen internet verbinding');
      }
    }
  }
}
