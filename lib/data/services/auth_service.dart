import 'package:supabase_flutter/supabase_flutter.dart';

/// Wraps Supabase auth operations for use throughout the app.
class AuthService {
  AuthService(this._client);

  final SupabaseClient _client;

  /// Must match the intent filter in AndroidManifest.xml and the redirect URL
  /// configured in Supabase Dashboard > Auth > URL Configuration.
  static const redirectUrl = 'com.paletteapp.palette://login-callback';

  Session? get currentSession => _client.auth.currentSession;

  User? get currentUser => _client.auth.currentUser;

  bool get isAuthenticated => currentSession != null;

  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: redirectUrl,
    );
  }

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    return _client.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: redirectUrl,
    );
  }

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email, redirectTo: redirectUrl);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
