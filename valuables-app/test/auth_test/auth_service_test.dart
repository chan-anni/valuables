import "dart:nativewrappers/_internal/vm_shared/lib/compact_hash.dart";

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

void main() {
  late MockGoogleSignIn mockGoogleSignIn;
  late SupabaseClient mockSupabaseClient;
  late AuthService authService;

  mockGoogleSignIn = MockGoogleSignIn();
  mockSupabaseClient = MockSupabaseClient();

  setUp(() {
    authService = AuthService.setClients(
      supabase: mockSupabaseClient,
      googleSignIn: mockGoogleSignIn,
    );
  });

  group('Sign in with Google', () {
    test('Successfully sign in with Google Account', () {
      final mockAccount = MockGoogleSignInAccount();
      final mockAuth = MockGoogleSignInAuthentication();
      final mockResponse = MockAuthResponse();
      final fakeIdToken = 'fake_jwt_id_token';

      when(
        () => mockGoogleSignIn.authenticate(),
      ).thenAnswer((_) async => mockAccount);
    });
  });
}
