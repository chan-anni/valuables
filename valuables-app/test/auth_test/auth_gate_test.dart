import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:valuables/auth/auth_gate.dart';

void main() {
  final mockSession = Session(
    accessToken: 'fake-access-token',
    tokenType: 'bearer',
    user: const User(
      id: 'admin',
      appMetadata: {},
      userMetadata: {},
      aud: 'authenticated',
      createdAt: '2025-01-01T00:00:00.000Z',
      email: 'test@example.com',
    ),
  );
  group('AuthGate Redirects Handling', () {
    Widget buildTestGate(Stream<AuthState> stream) {
      return MaterialApp(
        home: AuthGate(
          // Artificial stream so the test controls exactly
          // what AuthState events the StreamBuilder receives. No live
          // Supabase connection is needed.
          authStateStream: stream,

          // Stub widgets stand in for LoginPage / ProfilePage so the
          // test never reaches code that requires Supabase.instance.
          loggedOutWidget: const Scaffold(body: Text('StubLoginPage')),
          loggedInWidget: const Scaffold(body: Text('StubProfilePage')),
        ),
      );
    }

    testWidgets('shows loading indicator while waiting for auth stream',
        (tester) async {
      // Dummy stream controller to simulate the auth stream.
      final controller = StreamController<AuthState>();

      await tester.pumpWidget(buildTestGate(controller.stream));

      // While the stream has not yet emitted, AuthGate should show a loading indicator.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Neither the logged-in nor logged-out stub should be shown.
      expect(find.text('StubLoginPage'), findsNothing);
      expect(find.text('StubProfilePage'), findsNothing);

      // Clean up the stream controller to avoid resource leaks.
      await controller.close();
    });

    testWidgets('shows LoginPage when auth stream emits a null session',
        (tester) async {
      // Dummy stream controller to simulate the auth stream.
      final controller = StreamController<AuthState>();

      await tester.pumpWidget(buildTestGate(controller.stream));

      // Push an AuthState with a null session to simulate a signed-out user.
      controller.add(const AuthState(AuthChangeEvent.signedOut, null));

      await tester.pumpAndSettle();

      // AuthGate should return to the login page.
      expect(find.text('StubLoginPage'), findsOneWidget);
      expect(find.text('StubProfilePage'), findsNothing);

      // The loading indicator should no longer be visible.
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await controller.close();
    });

    testWidgets('shows LoginPage on initialSession with no session',
        (tester) async {
      // Dummy stream controller to simulate the auth stream.
      final controller = StreamController<AuthState>();

      await tester.pumpWidget(buildTestGate(controller.stream));

      // Emit an initial session with a null session to simulate a signed-out user.
      controller.add(const AuthState(AuthChangeEvent.initialSession, null));
      await tester.pumpAndSettle();

      // The login page should be shown.
      expect(find.text('StubLoginPage'), findsOneWidget);
      expect(find.text('StubProfilePage'), findsNothing);

      await controller.close();
    });

    testWidgets('transitions from waiting to logged-out on first event',
        (tester) async {
      // Dummy stream controller to simulate the auth stream.
      final controller = StreamController<AuthState>();

      await tester.pumpWidget(buildTestGate(controller.stream));

      // Initially waiting — loading indicator should be shown.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Now the stream emits a signed-out state.
      controller.add(const AuthState(AuthChangeEvent.signedOut, null));
      await tester.pumpAndSettle();

      // Loading indicator gone, logged-out stub visible.
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('StubLoginPage'), findsOneWidget);

      await controller.close();
    });

    testWidgets('successful login redirect user to profile page',
        (tester) async {
      // Dummy stream controller to simulate the auth stream.
      final controller = StreamController<AuthState>();

      await tester.pumpWidget(buildTestGate(controller.stream));

      // Initially waiting — loading indicator should be shown.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Now the stream emits a signed-in state with a mock session.
      controller.add(AuthState(AuthChangeEvent.signedIn, mockSession));
      await tester.pumpAndSettle();

      // Loading indicator gone, should show the profile page.
      expect(find.byType(CircularProgressIndicator), findsNothing);

      expect(find.text('StubProfilePage'), findsOneWidget);

      await controller.close();
    });
  });
}
