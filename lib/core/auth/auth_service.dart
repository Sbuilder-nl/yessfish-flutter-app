import 'package:dio/dio.dart';
import '../api/dio_client.dart';

class AuthService {
  late final Dio _dio;
  bool _initialized = false;

  AuthService();

  Future<void> _init() async {
    if (_initialized) return;
    
    final client = await DioClient.getInstance();
    _dio = client.dio;
    _initialized = true;
  }

  /// Login with email and password
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      await _init();
      
      final response = await _dio.post(
        '/auth/login.php',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.data['success'] == true) {
        return {
          'success': true,
          'user': response.data['user'],
          'message': response.data['message'],
        };
      } else {
        throw Exception(response.data['error'] ?? 'Login mislukt');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final error = e.response!.data['error'] ?? 'Login mislukt';
        throw Exception(error);
      } else {
        throw Exception('Geen internet verbinding');
      }
    }
  }

  /// Register new account
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    String? name,
  }) async {
    try {
      await _init();
      
      final response = await _dio.post(
        '/auth/register.php',
        data: {
          'username': username,
          'email': email,
          'password': password,
          'name': name ?? username,
        },
      );

      if (response.data['success'] == true) {
        return {
          'success': true,
          'user': response.data['user'],
          'message': response.data['message'],
        };
      } else {
        throw Exception(response.data['error'] ?? 'Registratie mislukt');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final error = e.response!.data['error'] ?? 'Registratie mislukt';
        throw Exception(error);
      } else {
        throw Exception('Geen internet verbinding');
      }
    }
  }

  /// Logout (clear session)
  Future<void> logout() async {
    final client = await DioClient.getInstance();
    await client.clearCookies();
  }

  /// Check if user has valid session
  Future<bool> hasValidSession() async {
    final client = await DioClient.getInstance();
    return await client.hasValidSession();
  }
}
