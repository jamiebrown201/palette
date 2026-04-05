import 'package:sentry_flutter/sentry_flutter.dart';
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
    Sentry.addBreadcrumb(
      Breadcrumb(message: 'Google Sign-In starting', category: 'auth'),
    );
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: redirectUrl,
    );
  }

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    Sentry.addBreadcrumb(
      Breadcrumb(message: 'Email sign-in starting', category: 'auth'),
    );
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    Sentry.addBreadcrumb(
      Breadcrumb(message: 'Email sign-up starting', category: 'auth'),
    );
    return _client.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: redirectUrl,
    );
  }

  Future<void> resetPassword(String email) async {
    Sentry.addBreadcrumb(
      Breadcrumb(message: 'Password reset requested', category: 'auth'),
    );
    await _client.auth.resetPasswordForEmail(email, redirectTo: redirectUrl);
  }

  Future<void> signOut() async {
    Sentry.addBreadcrumb(
      Breadcrumb(message: 'Sign-out starting', category: 'auth'),
    );
    await _client.auth.signOut();
  }
}
