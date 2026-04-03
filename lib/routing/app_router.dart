import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:palette/core/analytics/analytics_observer.dart';
import 'package:palette/features/assistant/screens/assistant_screen.dart';
import 'package:palette/features/capture/screens/capture_screen.dart';
import 'package:palette/features/colour_wheel/screens/colour_wheel_screen.dart';
import 'package:palette/features/colour_wheel/screens/white_finder_screen.dart';
import 'package:palette/features/dev/screens/feedback_stats_screen.dart';
import 'package:palette/features/dev/screens/qa_mode_screen.dart';
import 'package:palette/features/explore/screens/explore_screen.dart';
import 'package:palette/features/explore/screens/paint_library_screen.dart';
import 'package:palette/features/home/screens/home_screen.dart';
import 'package:palette/features/moodboards/screens/moodboard_detail_screen.dart';
import 'package:palette/features/moodboards/screens/moodboard_list_screen.dart';
import 'package:palette/features/onboarding/screens/onboarding_screen.dart';
import 'package:palette/features/palette/screens/palette_screen.dart';
import 'package:palette/features/partner/screens/partner_screen.dart';
import 'package:palette/features/profile/screens/profile_screen.dart';
import 'package:palette/features/red_thread/screens/red_thread_screen.dart';
import 'package:palette/features/rooms/screens/create_room_screen.dart';
import 'package:palette/features/rooms/screens/design_diary_screen.dart';
import 'package:palette/features/rooms/screens/lighting_planner_screen.dart';
import 'package:palette/features/rooms/screens/renovation_guide_screen.dart';
import 'package:palette/features/rooms/screens/room_audit_screen.dart';
import 'package:palette/features/rooms/screens/room_detail_screen.dart';
import 'package:palette/features/rooms/screens/room_list_screen.dart';
import 'package:palette/features/samples/screens/sample_list_screen.dart';
import 'package:palette/features/shopping_list/screens/shopping_list_screen.dart';
import 'package:palette/features/subscription/screens/paywall_screen.dart';
import 'package:palette/features/visualiser/screens/visualiser_screen.dart';
import 'package:palette/providers/analytics_provider.dart';
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
    observers: [AnalyticsObserver(ref.read(analyticsProvider))],
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
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/rooms/create',
        pageBuilder:
            (context, state) => const MaterialPage(
              fullscreenDialog: true,
              child: CreateRoomScreen(),
            ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/shopping-list',
        builder: (context, state) => const ShoppingListScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/samples',
        builder: (context, state) => const SampleListScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/partner',
        builder: (context, state) => const PartnerScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/assistant',
        builder: (context, state) {
          final prompt = state.uri.queryParameters['prompt'];
          final sanitised =
              prompt != null && prompt.length <= 500
                  ? prompt.replaceAll(RegExp(r'[\x00-\x1F]'), '')
                  : null;
          return AssistantScreen(initialPrompt: sanitised);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/lighting-planner',
        builder:
            (context, state) => LightingPlannerScreen(
              roomId: state.uri.queryParameters['roomId'] ?? '',
            ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/room-audit',
        builder:
            (context, state) => RoomAuditScreen(
              roomId: state.uri.queryParameters['roomId'] ?? '',
            ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/renovation-guide',
        builder:
            (context, state) => RenovationGuideScreen(
              roomId: state.uri.queryParameters['roomId'] ?? '',
            ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/design-diary',
        builder:
            (context, state) => DesignDiaryScreen(
              roomId: state.uri.queryParameters['roomId'] ?? '',
            ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/visualiser',
        builder:
            (context, state) => VisualiserScreen(
              roomId: state.uri.queryParameters['roomId'],
              initialColourHex: state.uri.queryParameters['colour'],
            ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/moodboards',
        builder:
            (context, state) => MoodboardListScreen(
              roomId: state.uri.queryParameters['roomId'],
            ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/moodboards/:moodboardId',
        builder:
            (context, state) => MoodboardDetailScreen(
              moodboardId: state.pathParameters['moodboardId']!,
            ),
      ),
      if (kDebugMode) ...[
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: '/dev',
          builder: (context, state) => const QaModeScreen(),
        ),
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: '/dev/feedback-stats',
          builder: (context, state) => const FeedbackStatsScreen(),
        ),
      ],

      // Tab-based navigation
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: _rootNavigatorKey,
        builder:
            (context, state, navigationShell) =>
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
                    builder:
                        (context, state) => RoomDetailScreen(
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
                    builder:
                        (context, state) => WhiteFinderScreen(
                          roomId: state.uri.queryParameters['roomId'],
                        ),
                  ),
                  GoRoute(
                    path: 'paint-library',
                    builder:
                        (context, state) => PaintLibraryScreen(
                          roomId: state.uri.queryParameters['roomId'],
                        ),
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
