import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'api_constants.dart';

class DioClient {
  late final Dio _dio;
  late final CookieJar _cookieJar;
  static DioClient? _instance;

  DioClient._internal();

  static Future<DioClient> getInstance() async {
    if (_instance == null) {
      _instance = DioClient._internal();
      await _instance!._init();
    }
    return _instance!;
  }

  Future<void> _init() async {
    // Initialize persistent cookie jar
    final appDocDir = await getApplicationDocumentsDirectory();
    final cookiePath = '${appDocDir.path}/.cookies/';
    _cookieJar = PersistCookieJar(storage: FileStorage(cookiePath));

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
        // CRITICAL: Include credentials (cookies) in requests
        extra: {'withCredentials': true},
      ),
    );

    // Add cookie manager - THIS IS THE KEY FIX!
    _dio.interceptors.add(CookieManager(_cookieJar));

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
  CookieJar get cookieJar => _cookieJar;

  /// Request interceptor - Cookies are automatically added by CookieManager
  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Cookies are handled automatically by CookieManager
    // No need to manually add auth headers
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
      // Session expired - user needs to log in again
      print('❌ Session expired - user needs to log in');
      // Could emit event here to force logout
    }

    handler.next(error);
  }

  /// Clear all cookies (logout)
  Future<void> clearCookies() async {
    await _cookieJar.deleteAll();
  }

  /// Check if user has valid session
  Future<bool> hasValidSession() async {
    try {
      final cookies = await _cookieJar.loadForRequest(
        Uri.parse(ApiConstants.baseUrl),
      );
      return cookies.any((cookie) => cookie.name == 'PHPSESSID');
    } catch (e) {
      return false;
    }
  }
}
