import "package:mocktail/mocktail.dart";
import "package:flutter_test/flutter_test.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "package:google_sign_in/google_sign_in.dart";

import 'package:valuables/auth/auth_service.dart';

class MockGoogleSignIn extends Mock implements GoogleSignIn {}
void main() {
  late MockGoogleSignIn mockGoogleSignIn;

  late AuthService authService;

  setUp((){
    authService = AuthService();
  });
}