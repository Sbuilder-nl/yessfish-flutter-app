import 'package:flutter/foundation.dart';
import 'api.dart';
import 'push.dart';

class User {
  final int id;
  final String username;
  final String? firstName;
  final String? avatarPath;
  final bool isAdmin;
  final bool canModerate;
  User({required this.id, required this.username, this.firstName, this.avatarPath, this.isAdmin = false, this.canModerate = false});
  factory User.fromJson(Map<String, dynamic> j) => User(
        id: j['id'] as int,
        username: (j['username'] ?? '') as String,
        firstName: j['first_name'] as String?,
        avatarPath: j['avatar_path'] as String?,
        isAdmin: (j['is_admin'] ?? false) as bool,
        canModerate: (j['can_moderate'] ?? j['is_admin'] ?? false) as bool,
      );
}

class AuthState extends ChangeNotifier {
  User? user;
  bool loading = true;

  // Na een geslaagde authenticatie: push opzetten + toestel-token registreren (best-effort).
  void _afterAuth() {
    Push.init();
    Push.registerToken();
  }

  Future<void> bootstrap() async {
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
    loading = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final r = await Api.post('/auth/login', {'email': email, 'password': password});
    await Api.setToken(r['token']);
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
