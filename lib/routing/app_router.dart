import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:palette/features/capture/screens/capture_screen.dart';
import 'package:palette/features/colour_wheel/screens/colour_wheel_screen.dart';
import 'package:palette/features/colour_wheel/screens/white_finder_screen.dart';
import 'package:palette/features/dev/screens/qa_mode_screen.dart';
import 'package:palette/features/explore/screens/explore_screen.dart';
import 'package:palette/features/explore/screens/paint_library_screen.dart';
import 'package:palette/features/home/screens/home_screen.dart';
import 'package:palette/features/onboarding/screens/onboarding_screen.dart';
import 'package:palette/features/palette/screens/palette_screen.dart';
import 'package:palette/features/profile/screens/profile_screen.dart';
import 'package:palette/features/red_thread/screens/red_thread_screen.dart';
import 'package:palette/features/rooms/screens/room_detail_screen.dart';
import 'package:palette/features/rooms/screens/room_list_screen.dart';
import 'package:palette/features/subscription/screens/paywall_screen.dart';
import 'package:palette/providers/app_providers.dart';
import 'package:palette/routing/app_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _homeNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _roomsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'rooms');
final _captureNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'capture');
final _exploreNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'explore');
final _profileNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'profile');

final routerProvider = Provider<GoRouter>((ref) {
  final hasCompletedOnboarding = ref.watch(hasCompletedOnboardingProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    // Gracefully handle unknown routes (e.g. malformed deep links)
    errorBuilder: (context, state) => const HomeScreen(),
    redirect: (context, state) {
      // Normalise trailing slashes from deep links
      final loc = state.matchedLocation;
      if (loc.length > 1 && loc.endsWith('/')) {
        return loc.substring(0, loc.length - 1);
      }

      final isOnboarding = loc == '/onboarding';
      final isDev = loc == '/dev';
      if (!hasCompletedOnboarding && !isOnboarding && !isDev) {
        return '/onboarding';
      }
      if (hasCompletedOnboarding && isOnboarding) {
        return '/home';
      }
      return null;
    },
    routes: [
      // Full-screen routes (outside tab shell)
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/palette',
        builder: (context, state) => const PaletteScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/paywall',
        builder: (context, state) => const PaywallScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/red-thread',
        builder: (context, state) => const RedThreadScreen(),
      ),
      if (kDebugMode)
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: '/dev',
          builder: (context, state) => const QaModeScreen(),
        ),

      // Tab-based navigation
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          // Tab 0: Home
          StatefulShellBranch(
            navigatorKey: _homeNavigatorKey,
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),

          // Tab 1: My Rooms
          StatefulShellBranch(
            navigatorKey: _roomsNavigatorKey,
            routes: [
              GoRoute(
                path: '/rooms',
                builder: (context, state) => const RoomListScreen(),
                routes: [
                  GoRoute(
                    path: ':roomId',
                    builder: (context, state) => RoomDetailScreen(
                      roomId: state.pathParameters['roomId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Tab 2: Capture
          StatefulShellBranch(
            navigatorKey: _captureNavigatorKey,
            routes: [
              GoRoute(
                path: '/capture',
                builder: (context, state) => const CaptureScreen(),
              ),
            ],
          ),

          // Tab 3: Explore
          StatefulShellBranch(
            navigatorKey: _exploreNavigatorKey,
            routes: [
              GoRoute(
                path: '/explore',
                builder: (context, state) => const ExploreScreen(),
                routes: [
                  GoRoute(
                    path: 'wheel',
                    builder: (context, state) => const ColourWheelScreen(),
                  ),
                  GoRoute(
                    path: 'white-finder',
                    builder: (context, state) => WhiteFinderScreen(
                      roomId: state.uri.queryParameters['roomId'],
                    ),
                  ),
                  GoRoute(
                    path: 'paint-library',
                    builder: (context, state) => const PaintLibraryScreen(),
                  ),
                ],
              ),
            ],
          ),

          // Tab 4: Profile
          StatefulShellBranch(
            navigatorKey: _profileNavigatorKey,
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
