import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/dio_client.dart';

class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
    // Web client ID from Google Cloud Console
    // Used for server-side authentication
    serverClientId: '722347151371-ht0f8ekdrb3e5p2k61ugb6jck8d42upm.apps.googleusercontent.com',
  );

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final DioClient _dioClient = DioClient();

  /// Sign in with Google and exchange token with backend
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in
        return null;
      }

      // Get Google authentication
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        throw Exception('Failed to get Google ID token');
      }

      // Send Google token to your backend for verification
      final response = await _dioClient.dio.post(
        '/auth/google',
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

        // Store JWT token from backend
        if (data['token'] != null) {
          await _storage.write(key: 'auth_token', value: data['token']);
        }

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
      await _storage.delete(key: 'auth_token');
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
