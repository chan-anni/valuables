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
    // Google sign in on Android will work without providing the Android
    // Client ID registered on Google Cloud.

    // Perform the sign in
    final googleAccount = await GoogleSignIn.instance.authenticate();
    final idToken = googleAccount.authentication.idToken;

    if (idToken == null) {
      throw Exception('No ID Token found.');
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
