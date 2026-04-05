import 'package:flutter_test/flutter_test.dart';

/// Tests the auth redirect truth table without requiring GoRouter or Supabase.
///
/// The redirect logic in app_router.dart follows this truth table:
///   | Onboarded | Authenticated | Redirect       |
///   |-----------|---------------|----------------|
///   | No        | No            | /onboarding    |
///   | Yes       | No            | /auth          |
///   | No        | Yes           | /onboarding    |
///   | Yes       | Yes           | Allow through  |
///   | *         | *             | /dev bypasses  |
///
/// We extract the pure logic and test it without framework dependencies.

String? authRedirect({
  required String location,
  required bool hasCompletedOnboarding,
  required bool isAuthenticated,
}) {
  // Normalise trailing slashes
  if (location.length > 1 && location.endsWith('/')) {
    return location.substring(0, location.length - 1);
  }

  final isOnboarding = location == '/onboarding';
  final isAuth = location == '/auth' || location.startsWith('/auth/');
  final isDev = location == '/dev' || location.startsWith('/dev/');

  if (isDev) return null;

  if (!hasCompletedOnboarding && !isOnboarding) {
    return '/onboarding';
  }

  if (hasCompletedOnboarding && !isAuthenticated && !isAuth) {
    return '/auth';
  }

  if (isAuthenticated && isAuth) {
    return '/home';
  }

  if (hasCompletedOnboarding && isAuthenticated && isOnboarding) {
    return '/home';
  }

  return null;
}

void main() {
  group('Auth redirect logic', () {
    test('not onboarded, not authenticated → /onboarding', () {
      expect(
        authRedirect(
          location: '/home',
          hasCompletedOnboarding: false,
          isAuthenticated: false,
        ),
        '/onboarding',
      );
    });

    test('onboarded, not authenticated → /auth', () {
      expect(
        authRedirect(
          location: '/home',
          hasCompletedOnboarding: true,
          isAuthenticated: false,
        ),
        '/auth',
      );
    });

    test('not onboarded, authenticated → /onboarding', () {
      expect(
        authRedirect(
          location: '/home',
          hasCompletedOnboarding: false,
          isAuthenticated: true,
        ),
        '/onboarding',
      );
    });

    test('onboarded, authenticated → allow through (null)', () {
      expect(
        authRedirect(
          location: '/home',
          hasCompletedOnboarding: true,
          isAuthenticated: true,
        ),
        isNull,
      );
    });

    test('onboarded, authenticated, on /onboarding → /home', () {
      expect(
        authRedirect(
          location: '/onboarding',
          hasCompletedOnboarding: true,
          isAuthenticated: true,
        ),
        '/home',
      );
    });

    test('authenticated, on /auth → /home', () {
      expect(
        authRedirect(
          location: '/auth',
          hasCompletedOnboarding: true,
          isAuthenticated: true,
        ),
        '/home',
      );
    });

    test('authenticated, on /auth/email → /home', () {
      expect(
        authRedirect(
          location: '/auth/email',
          hasCompletedOnboarding: true,
          isAuthenticated: true,
        ),
        '/home',
      );
    });

    test('/dev bypasses auth regardless of state', () {
      expect(
        authRedirect(
          location: '/dev',
          hasCompletedOnboarding: false,
          isAuthenticated: false,
        ),
        isNull,
      );
    });

    test('/dev/feedback-stats bypasses auth', () {
      expect(
        authRedirect(
          location: '/dev/feedback-stats',
          hasCompletedOnboarding: false,
          isAuthenticated: false,
        ),
        isNull,
      );
    });

    test('not onboarded on /onboarding → allow through (null)', () {
      expect(
        authRedirect(
          location: '/onboarding',
          hasCompletedOnboarding: false,
          isAuthenticated: false,
        ),
        isNull,
      );
    });

    test('onboarded, not authenticated on /auth → allow through (null)', () {
      expect(
        authRedirect(
          location: '/auth',
          hasCompletedOnboarding: true,
          isAuthenticated: false,
        ),
        isNull,
      );
    });

    test('trailing slash is normalised', () {
      expect(
        authRedirect(
          location: '/home/',
          hasCompletedOnboarding: true,
          isAuthenticated: true,
        ),
        '/home',
      );
    });

    test('deep route when not authenticated → /auth', () {
      expect(
        authRedirect(
          location: '/rooms/abc123',
          hasCompletedOnboarding: true,
          isAuthenticated: false,
        ),
        '/auth',
      );
    });

    test('deep route when not onboarded → /onboarding', () {
      expect(
        authRedirect(
          location: '/rooms/abc123',
          hasCompletedOnboarding: false,
          isAuthenticated: false,
        ),
        '/onboarding',
      );
    });
  });
}
