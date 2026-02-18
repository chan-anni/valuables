/// Class with functions related to user authentication. Allows user to login
/// with own email, sign up, and logout.
/// Includes helper function to get authentication status.
library;

import "dart:async";

import "package:supabase_flutter/supabase_flutter.dart";
import "package:google_sign_in/google_sign_in.dart";

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Sign in with personal email and password
  ///
  /// @param email The user's email
  /// @param password The user's password
  /// @return user session
  Future<AuthResponse> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign up with personal email and password
  ///
  /// @param email The user's email
  /// @param password The user's password
  /// @return user session
  Future<AuthResponse> signUpWithEmailPassword(
    String email,
    String password,
  ) async {
    return await _supabase.auth.signUp(email: email, password: password);
  }

  Future<AuthResponse> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn.instance;

    late final GoogleSignInAccount googleAccount;
    try {
      googleAccount = await googleSignIn.authenticate();
    } on GoogleSignInException catch (e) {
      switch (e.code) {
        case GoogleSignInExceptionCode.canceled:
        case GoogleSignInExceptionCode.interrupted:
        case GoogleSignInExceptionCode.uiUnavailable:
          throw Exception('Sign-in cancelled.');
        default:
          throw Exception(
            e.description ?? 'Google Sign-In failed (${e.code.name}).',
          );
      }
    }

    final idToken = googleAccount.authentication.idToken;
    if (idToken == null) {
      throw Exception(
        'Google Sign-In did not return an ID token. '
        'Check that Google Sign-In is configured with the correct client IDs.',
      );
    }

    return await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
    );
  }

  /// Sign out from the current session
  Future<void> signOut() async {
    final user = _supabase.auth.currentUser;
    final isGoogle =
        user?.appMetadata['provider'] == 'google' ||
        user?.identities?.any((i) => i.provider == 'google') == true;

    if (isGoogle) {
      await GoogleSignIn.instance.signOut();
    }
    await _supabase.auth.signOut();
  }

  /// Get the current user's email
  String? getCurrentUserEmail() {
    final session = _supabase.auth.currentSession;
    final user = session?.user;
    return user?.email;
  }
}
