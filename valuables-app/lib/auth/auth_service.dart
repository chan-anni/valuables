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
    const webClientId =
        '398491837853-hvd35lt2rgjb0g4ui20ft8kqg0oa4bmm.apps.googleusercontent.com';

    const iosClientId =
        '398491837853-k279v0djfia5g0s9itnnnbumo2a24aab.apps.googleusercontent.com';

    // Google sign in on Android will work without providing the Android
    // Client ID registered on Google Cloud.

    final GoogleSignIn signIn = GoogleSignIn.instance;

    // At the start of your app, initialize the GoogleSignIn instance
    unawaited(
      signIn.initialize(clientId: iosClientId, serverClientId: webClientId),
    );

    // Perform the sign in
    final googleAccount = await signIn.authenticate();
    final googleAuthorization = await googleAccount.authorizationClient
        .authorizationForScopes([]);
    final googleAuthentication = googleAccount.authentication;
    final idToken = googleAuthentication.idToken;
    final accessToken = googleAuthorization?.accessToken;

    if (idToken == null) {
      throw 'No ID Token found.';
    }

    return await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  /// Sign out from the current session
  Future<void> signOut() async {
    return _supabase.auth.signOut();
  }

  /// Get the current user's email
  String? getCurrentUserEmail() {
    final session = _supabase.auth.currentSession;
    final user = session?.user;
    return user?.email;
  }
}
