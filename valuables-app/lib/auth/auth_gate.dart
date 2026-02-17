/// Observe the login state and redirect the user to the Profile or Login page
/// based the status.
library;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:valuables/pages/login_page.dart';
import 'package:valuables/pages/profile_page.dart';

class AuthGate extends StatelessWidget {
  /// Optional stream to override the default Supabase auth state stream.
  /// When null, defaults to Supabase.instance.client.auth.onAuthStateChange.
  /// Pass a custom stream in tests to avoid requiring a live Supabase instance.
  final Stream<AuthState>? authStateStream;

  /// Optional widget overrides for the logged-in and logged-out states.
  /// When null, defaults to ProfilePage and LoginPage respectively.
  /// Pass lightweight stub widgets in tests to avoid Supabase dependencies
  /// that live inside the real page widgets.
  final Widget? loggedInWidget;
  final Widget? loggedOutWidget;

  const AuthGate({
    super.key,
    this.authStateStream,
    this.loggedInWidget,
    this.loggedOutWidget,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: authStateStream ??
          Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final session = snapshot.hasData ? snapshot.data!.session : null;

        if (session != null) {
          return loggedInWidget ?? const ProfilePage();
        } else {
          return loggedOutWidget ?? const LoginPage();
        }
      },
    );
  }
}
