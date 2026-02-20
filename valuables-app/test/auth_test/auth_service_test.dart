import "package:mocktail/mocktail.dart";
import "package:flutter_test/flutter_test.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "package:google_sign_in/google_sign_in.dart";

import 'package:valuables/auth/auth_service.dart';

class MockGoogleSignIn extends Mock implements GoogleSignIn {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}

class MockGoogleSignInAuthentication extends Mock
    implements GoogleSignInAuthentication {}

class MockAuthResponse extends Mock implements AuthResponse {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  late MockGoogleSignIn mockGoogleSignIn;
  late SupabaseClient mockSupabaseClient;
  late AuthService authService;
  late GoTrueClient mockAuthClient;

  setUp(() {
    mockAuthClient = MockGoTrueClient();
    mockGoogleSignIn = MockGoogleSignIn();
    mockSupabaseClient = MockSupabaseClient();

    authService = AuthService.setClients(
      supabase: mockSupabaseClient,
      googleSignIn: mockGoogleSignIn,
    );

    when(() => mockSupabaseClient.auth).thenReturn(mockAuthClient);

    registerFallbackValue(OAuthProvider.google);
  });

  group('Sign in with Google', () {
    test('Successfully sign in with Google Account', () async {
      final mockAccount = MockGoogleSignInAccount();
      final mockAuth = MockGoogleSignInAuthentication();
      final mockResponse = MockAuthResponse();
      final fakeIdToken = 'fake_jwt_id_token';

      when(
        () => mockGoogleSignIn.authenticate(),
      ).thenAnswer((_) async => mockAccount);

      when(() => mockAccount.authentication).thenAnswer((_) => mockAuth);

      when(() => mockAuth.idToken).thenAnswer((_) => fakeIdToken);

      when(
        () => mockAuthClient.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: fakeIdToken,
        ),
      ).thenAnswer((_) async => mockResponse);

      final result = await authService.signInWithGoogle();

      expect(result, equals(mockResponse));

      verify(() => mockGoogleSignIn.authenticate()).called(1);
      verify(
        () => mockAuthClient.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: fakeIdToken,
        ),
      ).called(1);
    });

    test(
      'throws Exception when Google Sign-In returns a null ID token',
      () async {
        // Arrange
        final mockAccount = MockGoogleSignInAccount();
        final mockAuth = MockGoogleSignInAuthentication();

        when(
          () => mockGoogleSignIn.authenticate(),
        ).thenAnswer((_) async => mockAccount);
        when(() => mockAccount.authentication).thenAnswer((_) => mockAuth);

        // Simulate a missing ID token
        when(() => mockAuth.idToken).thenReturn(null);

        // Act & Assert
        expect(
          () => authService.signInWithGoogle(),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('did not return an ID token'),
            ),
          ),
        );

        // Verify Supabase was NEVER called because it threw an error first
        verifyNever(
          () => mockAuthClient.signInWithIdToken(
            provider: any(named: 'provider'),
            idToken: any(named: 'idToken'),
          ),
        );
      },
    );

    test('Throws error when the signing return null', () async {
      final mockAccount = MockGoogleSignInAccount();
      final mockAuth = MockGoogleSignInAuthentication();

      when(
        () => mockGoogleSignIn.authenticate(),
      ).thenAnswer((_) async => mockAccount);

      when(() => mockAccount.authentication).thenAnswer((_) => mockAuth);

      when(() => mockAuth.idToken).thenReturn(null);

      expect(
        () => authService.signInWithGoogle(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('did not return an ID token'),
          ),
        ),
      );

      verifyNever(
        () => mockAuthClient.signInWithIdToken(
          provider: any(named: 'provider'),
          idToken: any(named: 'idToken'),
        ),
      );
    });
  });
}
