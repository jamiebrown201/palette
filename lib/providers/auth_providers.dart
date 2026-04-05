import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette/data/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The Supabase client instance, available after [Supabase.initialize].
final supabaseClientProvider = Provider<SupabaseClient>(
  (_) => Supabase.instance.client,
);

/// Global auth service provider.
final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(ref.watch(supabaseClientProvider)),
);

/// Streams auth state changes (sign-in, sign-out, token refresh).
final authStateProvider = StreamProvider<AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.onAuthStateChange;
});

/// Whether the user is currently authenticated.
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.whenOrNull(data: (state) => state.session != null) ??
      // Fall back to checking the current session synchronously so the
      // router has a value before the stream emits its first event.
      ref.read(authServiceProvider).isAuthenticated;
});

/// The currently signed-in Supabase user, or null.
final currentUserProvider = Provider<User?>((ref) {
  // Re-evaluate whenever auth state changes.
  ref.watch(authStateProvider);
  return ref.read(authServiceProvider).currentUser;
});
