import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class SocialAuthService {
  /// Sign in with Google, returns idToken for backend verification.
  /// The serverClientId is your Google Web Client ID (needed to get idToken on Android).
  Future<String?> signInWithGoogle({required String serverClientId}) async {
    try {
      final googleSignIn = GoogleSignIn(
        serverClientId: serverClientId,
        scopes: ['email', 'profile'],
      );

      // Sign out first to force account picker
      await googleSignIn.signOut();
      final account = await googleSignIn.signIn();
      if (account == null) return null; // User cancelled

      final auth = await account.authentication;
      return auth.idToken;
    } catch (e) {
      rethrow;
    }
  }

  /// Sign in with Facebook, returns accessToken for backend verification.
  Future<String?> signInWithFacebook() async {
    try {
      final result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.success) {
        return result.accessToken?.tokenString;
      } else if (result.status == LoginStatus.cancelled) {
        return null; // User cancelled
      } else {
        throw Exception(result.message ?? 'Facebook login failed');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Sign out from all social providers
  Future<void> signOutAll() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    try {
      await FacebookAuth.instance.logOut();
    } catch (_) {}
  }
}
