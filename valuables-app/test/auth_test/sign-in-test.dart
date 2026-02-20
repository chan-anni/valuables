import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

// TODO: Replace with your actual import path
import 'package:your_app/auth_service.dart';

// --- 1. Define the Mock Classes ---
class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}
class MockGoogleSignIn extends Mock implements GoogleSignIn {}
class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}
class MockGoogleSignInAuthentication extends Mock implements GoogleSignInAuthentication {}
class MockAuthResponse extends Mock implements AuthResponse {}

void main() {
  late MockSupabaseClient mockSupabaseClient;
  late MockGoTrueClient mockAuthClient; // Supabase's auth sub-client
  late MockGoogleSignIn mockGoogleSignIn;
  late AuthService authService;

  setUp(() {
    // Initialize mocks before each test
    mockSupabaseClient = MockSupabaseClient();
    mockAuthClient = MockGoTrueClient();
    mockGoogleSignIn = MockGoogleSignIn();

    // Link the mocked auth client to the mocked supabase client
    // When _supabase.auth is called, return our mockAuthClient
    when(() => mockSupabaseClient.auth).thenReturn(mockAuthClient);

    // Inject the mocks into the service
    authService = AuthService(
      supabase: mockSupabaseClient,
      googleSignIn: mockGoogleSignIn,
    );

    // Register fallback values if your methods use 'any()' matchers for custom enums
    registerFallbackValue(OAuthProvider.google);
  });

  group('AuthService - signInWithGoogle (Mocked)', () {
    test('completes successfully when Google returns a valid ID token', () async {
      // Arrange (Set up the fake responses)
      final mockAccount = MockGoogleSignInAccount();
      final mockAuth = MockGoogleSignInAuthentication();
      final mockResponse = MockAuthResponse();
      final fakeIdToken = 'fake_jwt_token_123';

      // 1. Mock the Google popup returning an account
      when(() => mockGoogleSignIn.authenticate()).thenAnswer((_) async => mockAccount);
      
      // 2. Mock the account returning authentication details
      when(() => mockAccount.authentication).thenAnswer((_) async => mockAuth);
      
      // 3. Mock the auth details containing an ID token
      when(() => mockAuth.idToken).thenReturn(fakeIdToken);

      // 4. Mock Supabase successfully consuming that token
      when(() => mockAuthClient.signInWithIdToken(
            provider: OAuthProvider.google,
            idToken: fakeIdToken,
          )).thenAnswer((_) async => mockResponse);

      // Act (Call the method)
      final result = await authService.signInWithGoogle();

      // Assert (Check the results)
      expect(result, equals(mockResponse));
      
      // Verify that the underlying methods were actually called
      verify(() => mockGoogleSignIn.authenticate()).called(1);
      verify(() => mockAuthClient.signInWithIdToken(
            provider: OAuthProvider.google,
            idToken: fakeIdToken,
          )).called(1);
    });

    test('throws Exception when Google Sign-In returns a null ID token', () async {
      // Arrange
      final mockAccount = MockGoogleSignInAccount();
      final mockAuth = MockGoogleSignInAuthentication();

      when(() => mockGoogleSignIn.authenticate()).thenAnswer((_) async => mockAccount);
      when(() => mockAccount.authentication).thenAnswer((_) async => mockAuth);
      
      // Simulate a missing ID token
      when(() => mockAuth.idToken).thenReturn(null); 

      // Act & Assert
      expect(
        () => authService.signInWithGoogle(),
        throwsA(isA<Exception>().having(
          (e) => e.toString(), 
          'message', 
          contains('did not return an ID token')
        )),
      );

      // Verify Supabase was NEVER called because it threw an error first
      verifyNever(() => mockAuthClient.signInWithIdToken(
            provider: any(named: 'provider'),
            idToken: any(named: 'idToken'),
          ));
    });
  });
}