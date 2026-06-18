import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'config.dart';

class ApiException implements Exception {
  final int status;
  final dynamic data;
  ApiException(this.status, this.data);
  String get message =>
      (data is Map && data['message'] != null) ? data['message'].toString() : 'Er ging iets mis';
}

class Api {
  static const _storage = FlutterSecureStorage();
  static String? _token;

  static Future<void> loadToken() async => _token = await _storage.read(key: 'yf_token');
  static Future<void> setToken(String t) async { _token = t; await _storage.write(key: 'yf_token', value: t); }
  static Future<void> clearToken() async { _token = null; await _storage.delete(key: 'yf_token'); }
  static String? get token => _token;

  static Map<String, String> _headers() => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  static Future<dynamic> get(String p) => _send('GET', p);
  static Future<dynamic> post(String p, [Map<String, dynamic>? b]) => _send('POST', p, b);
  static Future<dynamic> put(String p, [Map<String, dynamic>? b]) => _send('PUT', p, b);
  static Future<dynamic> delete(String p, [Map<String, dynamic>? b]) => _send('DELETE', p, b);

  static Future<dynamic> _send(String method, String path, [Map<String, dynamic>? body]) async {
    final req = http.Request(method, Uri.parse('${Config.apiBase}$path'));
    req.headers.addAll(_headers());
    if (body != null) req.body = jsonEncode(body);
    final res = await http.Response.fromStream(await http.Client().send(req).timeout(const Duration(seconds: 25)));
    final data = res.body.isNotEmpty ? jsonDecode(res.body) : null;
    if (res.statusCode >= 200 && res.statusCode < 300) return data;
    throw ApiException(res.statusCode, data);
  }

  static Future<Map<String, dynamic>> uploadImage(String filePath) async {
    final req = http.MultipartRequest('POST', Uri.parse('${Config.apiBase}/uploads'));
    req.headers['Accept'] = 'application/json';
    if (_token != null) req.headers['Authorization'] = 'Bearer $_token';
    req.files.add(await http.MultipartFile.fromPath('file', filePath));
    final res = await http.Response.fromStream(await req.send().timeout(const Duration(seconds: 60)));
    final data = res.body.isNotEmpty ? jsonDecode(res.body) : null;
    if (res.statusCode >= 200 && res.statusCode < 300) return Map<String, dynamic>.from(data);
    throw ApiException(res.statusCode, data);
  }
}
