import 'package:google_sign_in/google_sign_in.dart';
import 'package:dio/dio.dart';
import '../api/dio_client.dart';

class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
    serverClientId: '722347151371-ht0f8ekdrb3e5p2k61ugb6jck8d42upm.apps.googleusercontent.com',
  );

  late final Dio _dio;

  GoogleAuthService() {
    _init();
  }

  Future<void> _init() async {
    final client = await DioClient.getInstance();
    _dio = client.dio;
  }

  /// Sign in with Google and exchange token with backend
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      await _init();
      
      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        throw Exception('Failed to get Google ID token');
      }

      // Send Google token to backend for verification
      final response = await _dio.post(
        '/auth/google.php',
        data: {
          'id_token': idToken,
          'access_token': accessToken,
          'email': googleUser.email,
          'name': googleUser.displayName,
          'photo': googleUser.photoUrl,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;

        return {
          'user': data['user'],
          'token': data['token'],
          'google_user': {
            'email': googleUser.email,
            'name': googleUser.displayName,
            'photo': googleUser.photoUrl,
          },
        };
      }

      return null;
    } catch (e) {
      print('Google Sign-In error: $e');
      rethrow;
    }
  }

  /// Sign out from Google
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      final client = await DioClient.getInstance();
      await client.clearCookies();
    } catch (e) {
      print('Google Sign-Out error: $e');
    }
  }

  /// Check if user is currently signed in with Google
  Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }

  /// Get current signed-in Google account
  Future<GoogleSignInAccount?> getCurrentUser() async {
    return _googleSignIn.currentUser;
  }

  /// Silent sign-in (if user previously signed in)
  Future<GoogleSignInAccount?> signInSilently() async {
    try {
      return await _googleSignIn.signInSilently();
    } catch (e) {
      print('Silent sign-in failed: $e');
      return null;
    }
  }
}
