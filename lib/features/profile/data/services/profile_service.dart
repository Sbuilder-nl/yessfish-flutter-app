import 'package:dio/dio.dart';
import '../../../../core/api/dio_client.dart';

class ProfileService {
  late final Dio _dio;
  bool _initialized = false;

  ProfileService();

  Future<void> _init() async {
    if (_initialized) return;
    final client = await DioClient.getInstance();
    _dio = client.dio;
    _initialized = true;
  }

  /// Get user profile
  Future<Map<String, dynamic>> getProfile() async {
    await _init();
    
    try {
      final response = await _dio.get('/profile.php');
      
      if (response.data['success'] == true) {
        return response.data['profile'];
      } else {
        throw Exception(response.data['error'] ?? 'Profiel ophalen mislukt');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response!.data['error'] ?? 'Profiel ophalen mislukt');
      } else {
        throw Exception('Geen internet verbinding');
      }
    }
  }

  /// Update user profile
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? bio,
    String? location,
    String? phone,
    String? website,
    String? birthDate,
  }) async {
    await _init();
    
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (bio != null) data['bio'] = bio;
      if (location != null) data['location'] = location;
      if (phone != null) data['phone'] = phone;
      if (website != null) data['website'] = website;
      if (birthDate != null) data['birthday'] = birthDate;

      final response = await _dio.put(
        '/profile.php',
        data: data,
      );

      if (response.data['success'] == true) {
        return response.data['profile'];
      } else {
        throw Exception(response.data['error'] ?? 'Profiel updaten mislukt');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response!.data['error'] ?? 'Profiel updaten mislukt');
      } else {
        throw Exception('Geen internet verbinding');
      }
    }
  }

  /// Upload profile photo
  Future<String> uploadProfilePhoto(String filePath) async {
    await _init();
    
    try {
      final formData = FormData.fromMap({
        'profile_photo': await MultipartFile.fromFile(filePath),
      });

      final response = await _dio.post(
        '/profile.php',
        data: formData,
      );

      if (response.data['success'] == true) {
        return response.data['photo_url'];
      } else {
        throw Exception(response.data['error'] ?? 'Foto uploaden mislukt');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response!.data['error'] ?? 'Foto uploaden mislukt');
      } else {
        throw Exception('Geen internet verbinding');
      }
    }
  }
}
