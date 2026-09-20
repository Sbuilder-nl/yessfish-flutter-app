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
  @override
  String toString() => message;
}

class Api {
  static const _storage = FlutterSecureStorage();
  static String? _token;
  static String lang = 'nl'; // ingestelde taal → backend geeft meldingen in deze taal (X-App-Lang)

  // Versleutelde opslag kan op sommige Android-toestellen na een app-update de waarde
  // niet meer ontsleutelen (keystore) → read/write/delete gooit. NOOIT laten crashen:
  // token blijft in het geheugen werken voor de sessie; corrupte waarde wordt gewist.
  static Future<void> loadToken() async {
    try {
      _token = await _storage.read(key: 'yf_token');
    } catch (_) {
      _token = null;
      try { await _storage.delete(key: 'yf_token'); } catch (_) {}
    }
  }
  static Future<void> setToken(String t, {bool persist = true}) async {
    _token = t;
    try {
      if (persist) { await _storage.write(key: 'yf_token', value: t); }
      else { await _storage.delete(key: 'yf_token'); }
    } catch (_) {}
  }
  static Future<void> clearToken() async {
    _token = null;
    try { await _storage.delete(key: 'yf_token'); } catch (_) {}
  }
  static String? get token => _token;

  static Map<String, String> _headers() => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'X-App-Lang': lang,
    // Versie meesturen zodat de backend weet dat deze app sponsored posts aankan (feed-injectie).
    'X-App-Build': '${Config.buildNumber}',
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
    req.headers['X-App-Lang'] = lang;
    if (_token != null) req.headers['Authorization'] = 'Bearer $_token';
    req.files.add(await http.MultipartFile.fromPath('file', filePath));
    final res = await http.Response.fromStream(await req.send().timeout(const Duration(seconds: 60)));
    final data = res.body.isNotEmpty ? jsonDecode(res.body) : null;
    if (res.statusCode >= 200 && res.statusCode < 300) return Map<String, dynamic>.from(data);
    throw ApiException(res.statusCode, data);
  }

  /// Een bestand naar een eigen route sturen (bv. de foto van een visdocument).
  ///
  /// `uploadImage` gaat altijd naar /uploads en levert een openbaar pad op. De foto van een
  /// vergunning hoort juist NIET in die map: die gaat naar een afgeschermde map en is alleen met
  /// je eigen inlog op te halen. Daarom een eigen verzending (20-09-2026).
  static Future<Map<String, dynamic>> uploadNaar(String path, String filePath, {String veld = 'file'}) async {
    final req = http.MultipartRequest('POST', Uri.parse('${Config.apiBase}$path'));
    req.headers['Accept'] = 'application/json';
    req.headers['X-App-Lang'] = lang;
    if (_token != null) req.headers['Authorization'] = 'Bearer $_token';
    req.files.add(await http.MultipartFile.fromPath(veld, filePath));
    final res = await http.Response.fromStream(await req.send().timeout(const Duration(seconds: 60)));
    final data = res.body.isNotEmpty ? jsonDecode(res.body) : null;
    if (res.statusCode >= 200 && res.statusCode < 300) return Map<String, dynamic>.from(data ?? {});
    throw ApiException(res.statusCode, data);
  }

  /// Rauwe bytes ophalen mét inlog — voor afbeeldingen die niet openbaar mogen zijn.
  static Future<List<int>> bytes(String path) async {
    final res = await http.get(Uri.parse('${Config.apiBase}$path'), headers: _headers())
        .timeout(const Duration(seconds: 30));
    if (res.statusCode >= 200 && res.statusCode < 300) return res.bodyBytes;
    throw ApiException(res.statusCode, null);
  }

  // Feed-video-upload: stuurt de rauwe video; de server transcodeert async (poster + web-MP4).
  static Future<Map<String, dynamic>> uploadVideo(String filePath) async {
    final req = http.MultipartRequest('POST', Uri.parse('${Config.apiBase}/uploads/video'));
    req.headers['Accept'] = 'application/json';
    req.headers['X-App-Lang'] = lang;
    req.headers['X-App-Build'] = '${Config.buildNumber}';
    if (_token != null) req.headers['Authorization'] = 'Bearer $_token';
    req.files.add(await http.MultipartFile.fromPath('file', filePath));
    final res = await http.Response.fromStream(await req.send().timeout(const Duration(seconds: 120)));
    final data = res.body.isNotEmpty ? jsonDecode(res.body) : null;
    if (res.statusCode >= 200 && res.statusCode < 300) return Map<String, dynamic>.from(data);
    throw ApiException(res.statusCode, data);
  }

  // Fishfinder-import (CSV/GPX) → /imports. dry_run=1 geeft alleen het voorbeeld terug.
  static Future<Map<String, dynamic>> uploadImport(String filePath, {String visibility = 'public', bool dryRun = false}) async {
    final req = http.MultipartRequest('POST', Uri.parse('${Config.apiBase}/imports'));
    req.headers['Accept'] = 'application/json';
    req.headers['X-App-Lang'] = lang;
    if (_token != null) req.headers['Authorization'] = 'Bearer $_token';
    req.fields['visibility'] = visibility;
    if (dryRun) req.fields['dry_run'] = '1';
    req.files.add(await http.MultipartFile.fromPath('file', filePath));
    final res = await http.Response.fromStream(await req.send().timeout(const Duration(seconds: 90)));
    final data = res.body.isNotEmpty ? jsonDecode(res.body) : null;
    if (res.statusCode >= 200 && res.statusCode < 300) return Map<String, dynamic>.from(data);
    throw ApiException(res.statusCode, data);
  }
}
