import "package:mocktail/mocktail.dart";
import "package:flutter_test/flutter_test.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "package:google_sign_in/google_sign_in.dart";
import 'package:mock_supabase_http_client/mock_supabase_http_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  late MockSupabaseHttpClient mockSupabaseHttpClient;

  setUp(() async {
    mockAuthClient = MockGoTrueClient();
    mockGoogleSignIn = MockGoogleSignIn();
    mockSupabaseClient = MockSupabaseClient();
    mockSupabaseHttpClient = MockSupabaseHttpClient();

    authService = AuthService.setClients(
      supabase: mockSupabaseClient,
      googleSignIn: mockGoogleSignIn,
    );

    when(() => mockSupabaseClient.auth).thenReturn(mockAuthClient);

    registerFallbackValue(OAuthProvider.google);
  });

  group('Contructor test', () {
    SharedPreferences.setMockInitialValues({}); // Mock shared preferences

    // Use a local tearDown here if this is the only place using the real singleton
    tearDown(() async {
      try {
        await Supabase.instance.dispose();
      } catch (_) {}
    });

    test('AuthService initializes with default clients', () async {
      // We must initialize Supabase ONCE if the default constructor uses Supabase.instance
      // Use a try-catch or a check to prevent "Already Initialized" errors
      try {
        await Supabase.initialize(
          url: "https://fake.supabase.co",
          anonKey: "fake_anon_key",
          httpClient: mockSupabaseHttpClient,
          authOptions: const FlutterAuthClientOptions(
            localStorage: EmptyLocalStorage(),
          ),
        );
      } catch (_) {}

      final authService = AuthService();
      expect(authService.getGoogleSignInClient, isA<GoogleSignIn>());
      expect(authService.getSupabaseClient, isA<SupabaseClient>());
    });
  });

  group('Google Authentication', () {
    final cancelledCodes = [
      GoogleSignInExceptionCode.canceled,
      GoogleSignInExceptionCode.interrupted,
      GoogleSignInExceptionCode.uiUnavailable,
      GoogleSignInExceptionCode.unknownError,
    ];

    for (final code in cancelledCodes) {
      test(
        'throws "Sign-in cancelled." when error code is ${code.name}',
        () async {
          // Arrange
          when(() => mockGoogleSignIn.authenticate()).thenThrow(
            GoogleSignInException(
              code: code,
              description: 'Platform error details',
            ),
          );

          // Act & Assert
          if (code != GoogleSignInExceptionCode.unknownError) {
            expect(
              () => authService.signInWithGoogle(),
              throwsA(
                isA<Exception>().having(
                  (e) => e.toString(),
                  'message',
                  contains('Sign-in cancelled.'),
                ),
              ),
            );
          } else {
            expect(
              () => authService.signInWithGoogle(),
              throwsA(
                isA<Exception>().having(
                  (e) => e.toString(),
                  'message',
                  contains('Platform error details'),
                ),
              ),
            );
          }

          verifyNever(
            () => mockAuthClient.signInWithIdToken(
              provider: any(named: 'provider'),
              idToken: any(named: 'idToken'),
            ),
          );
        },
      );
    }

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

    test('Google Sign-In returns a null ID token', () async {
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
    });
  });

  group('Email and Password Authentication', () {
    test('Signin with email and password', () async {
      final mockAuthResponse = MockAuthResponse();
      final fakeEmail = "testing@example.com";
      final fakePassword = "password123";

      when(
        () => mockAuthClient.signInWithPassword(
          email: fakeEmail,
          password: fakePassword,
        ),
      ).thenAnswer((_) async => mockAuthResponse);

      final result = await authService.signInWithEmailPassword(
        fakeEmail,
        fakePassword,
      );

      expect(result, equals(mockAuthResponse));
    });

    test('Successfully sign up with email and password', () async {
      final mockResponse = MockAuthResponse();
      const tEmail = 'test@example.com';
      const tPassword = 'password123';

      // Stub the signUp call on the mockAuthClient (GoTrueClient)
      when(
        () => mockAuthClient.signUp(email: tEmail, password: tPassword),
      ).thenAnswer((_) async => mockResponse);

      final result = await authService.signUpWithEmailPassword(
        tEmail,
        tPassword,
      );

      expect(result, equals(mockResponse));

      // Verify that the auth client was actually called with the right data
      verify(
        () => mockAuthClient.signUp(email: tEmail, password: tPassword),
      ).called(1);
    });
  });
  test('Signout', () async {
    // 1. Create a mock user with Google metadata
    final mockUser = User(
      id: '123',
      appMetadata: {'provider': 'google'}, // This satisfies your isGoogle check
      userMetadata: {},
      aud: '',
      createdAt: '',
    );

    // 2. Tell the mock auth client to return this user
    when(() => mockAuthClient.currentUser).thenReturn(mockUser);

    // 3. Stub the sign-out methods
    when(() => mockGoogleSignIn.signOut()).thenAnswer((_) async => {});
    when(() => mockAuthClient.signOut()).thenAnswer((_) async {});

    // Act
    await authService.signOut();

    // Assert
    verify(() => mockGoogleSignIn.signOut()).called(1);
    verify(() => mockAuthClient.signOut()).called(1);
  });

  test('Get email of current user', () async {
    final mockUser = User(
      id: '123',
      appMetadata: {'provider': 'google'}, // This satisfies your isGoogle check
      email: 'test@example.com',
      userMetadata: {},
      aud: '',
      createdAt: '',
    );

    final mockSession = Session(
      accessToken: 'fake_access_token',
      tokenType: 'bearer',
      user: mockUser,
    );

    when(() => mockAuthClient.currentSession).thenReturn(mockSession);

    expect(authService.getCurrentUserEmail(), equals('test@example.com'));
  });
}
