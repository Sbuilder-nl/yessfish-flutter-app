import 'package:flutter/foundation.dart';
import 'api.dart';
import 'i18n.dart';
import 'push.dart';
import 'units.dart';

class User {
  final int id;
  final String username;
  final String? firstName;
  final String? avatarPath;
  final bool isAdmin;
  final bool canModerate;
  final bool emailVerified;
  User({required this.id, required this.username, this.firstName, this.avatarPath, this.isAdmin = false, this.canModerate = false, this.emailVerified = true});
  factory User.fromJson(Map<String, dynamic> j) => User(
        id: j['id'] as int,
        username: (j['username'] ?? '') as String,
        firstName: j['first_name'] as String?,
        avatarPath: j['avatar_path'] as String?,
        isAdmin: (j['is_admin'] ?? false) as bool,
        canModerate: (j['can_moderate'] ?? j['is_admin'] ?? false) as bool,
        emailVerified: (j['email_verified'] ?? true) as bool,
      );
}

class AuthState extends ChangeNotifier {
  User? user;
  bool loading = true;

  // Na een geslaagde authenticatie: push opzetten + toestel-token registreren (best-effort).
  void _afterAuth() {
    Push.init();
    Push.registerToken();
    _loadUnitPref();
  }

  // Gewichts-eenheid-voorkeur (kg/lb) laden zodat de app overal in de juiste eenheid toont.
  Future<void> _loadUnitPref() async {
    try {
      final s = await Api.get('/profile/settings');
      if (s is Map) {
        if (s['weight_unit'] == 'kg' || s['weight_unit'] == 'lb') {
          Units.unit = s['weight_unit'] as String;
        }
        // Eenmaal ingelogd: pas de accountvoorkeur toe. Bewust gekozen (locked) wint van de
        // apparaat-taal; anders blijft de apparaat-taal leidend en synct die naar de server.
        if (s['language'] is String) {
          I18n.instance?.applyServerLocale(s['language'] as String, locked: s['language_locked'] == true);
        }
      }
    } catch (_) {}
  }

  Future<void> bootstrap() async {
    // Volledig afgeschermd: wat er ook misgaat bij de opstartcheck, de app moet
    // ALTIJD doorgaan naar het inlogscherm (nooit op een wit laadscherm blijven hangen).
    try {
      await Api.loadToken();
      if (Api.token != null) {
        try {
          final r = await Api.get('/auth/me');
          user = User.fromJson(r['data']);
          _afterAuth();
        } catch (_) {
          await Api.clearToken();
        }
      }
    } catch (_) {/* niets mag de opstart blokkeren */}
    loading = false;
    notifyListeners();
  }

  Future<void> login(String email, String password, {bool remember = true}) async {
    final r = await Api.post('/auth/login', {'email': email, 'password': password});
    await Api.setToken(r['token'], persist: remember);
    user = User.fromJson(r['user']);
    _afterAuth();
    notifyListeners();
  }

  Future<void> register(Map<String, String> data) async {
    final r = await Api.post('/auth/register', data);
    await Api.setToken(r['token']);
    user = User.fromJson(r['user']);
    _afterAuth();
    notifyListeners();
  }


  Future<void> loginWithToken(String token) async {
    await Api.setToken(token);
    final r = await Api.get('/auth/me');
    user = User.fromJson(r['data']);
    _afterAuth();
    notifyListeners();
  }

  Future<void> logout() async {
    await Push.unregisterToken();
    try { await Api.post('/auth/logout'); } catch (_) {}
    await Api.clearToken();
    user = null;
    notifyListeners();
  }

  Future<void> refresh() async {
    try {
      final r = await Api.get('/auth/me');
      user = User.fromJson(r['data']);
      notifyListeners();
    } catch (_) {}
  }
}
