import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_constants.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;
  
  DioClient._internal() {
    _initDio();
  }
  
  void _initDio() {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  DioClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        followRedirects: true,
        maxRedirects: 5,
        headers: {
          ApiConstants.headerContentType: ApiConstants.contentTypeJson,
          ApiConstants.headerAccept: ApiConstants.contentTypeJson,
        },
      ),
    );

    // Add interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onResponse: _onResponse,
        onError: _onError,
      ),
    );

    // Add logging interceptor (debug only)
    _dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        error: true,
      ),
    );
  }

  Dio get dio => _dio;
  static Dio get instance => _instance.dio;

  /// Request interceptor - Add auth token
  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Get token from secure storage
    final token = await _storage.read(key: 'auth_token');

    if (token != null) {
      options.headers[ApiConstants.headerAuthorization] = 'Bearer $token';
    }

    handler.next(options);
  }

  /// Response interceptor
  void _onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    handler.next(response);
  }

  /// Error interceptor - Handle common errors
  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    if (error.response?.statusCode == 401) {
      // Token expired - try to refresh
      try {
        await _refreshToken();
        // Retry the request
        final response = await _dio.request(
          error.requestOptions.path,
          options: Options(
            method: error.requestOptions.method,
            headers: error.requestOptions.headers,
          ),
          data: error.requestOptions.data,
          queryParameters: error.requestOptions.queryParameters,
        );
        return handler.resolve(response);
      } catch (e) {
        // Refresh failed - logout user
        await _storage.delete(key: 'auth_token');
        await _storage.delete(key: 'refresh_token');
      }
    }

    handler.next(error);
  }

  /// Refresh access token
  Future<void> _refreshToken() async {
    final refreshToken = await _storage.read(key: 'refresh_token');

    if (refreshToken == null) {
      throw Exception('No refresh token available');
    }

    try {
      final response = await _dio.post(
        ApiConstants.refreshToken,
        data: {'refresh_token': refreshToken},
      );

      final newToken = response.data['access_token'];
      final newRefreshToken = response.data['refresh_token'];

      await _storage.write(key: 'auth_token', value: newToken);
      await _storage.write(key: 'refresh_token', value: newRefreshToken);
    } catch (e) {
      throw Exception('Failed to refresh token');
    }
  }

  /// Store auth tokens
  Future<void> saveAuthTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: 'auth_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
  }

  /// Clear auth tokens
  Future<void> clearAuthTokens() async {
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'refresh_token');
  }

  /// Get current auth token
  Future<String?> getAuthToken() async {
    return await _storage.read(key: 'auth_token');
  }
}
