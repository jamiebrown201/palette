import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette/app.dart';
import 'package:palette/core/analytics/analytics_service.dart';
import 'package:palette/core/analytics/session_tracker.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/core/constants/renter_constraints.dart';
import 'package:palette/core/feature_flags/experiment.dart';
import 'package:palette/core/feature_flags/feature_flag_service.dart';
import 'package:palette/core/observers/sentry_provider_observer.dart';
import 'package:palette/data/database/connection.dart';
import 'package:palette/data/repositories/colour_dna_repository.dart';
import 'package:palette/data/repositories/paint_colour_repository.dart';
import 'package:palette/data/repositories/product_repository.dart';
import 'package:palette/data/repositories/user_profile_repository.dart';
import 'package:palette/data/services/product_seed_data.dart';
import 'package:palette/data/services/seed_data_service.dart';
import 'package:palette/providers/analytics_provider.dart';
import 'package:palette/providers/app_providers.dart';
import 'package:palette/providers/database_providers.dart';
import 'package:palette/providers/feature_flag_provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  final db = await openDatabase();

  // Seed paint colour data on first launch.
  final paintRepo = PaintColourRepository(db);
  final seedService = SeedDataService(db, paintRepo);
  await seedService.seedIfNeeded();

  // Seed product catalogue on first launch.
  final productRepo = ProductRepository(db);
  await seedProducts(productRepo);

  // Load persisted user profile to restore state across restarts.
  final profileRepo = UserProfileRepository(db);
  final profile = await profileRepo.getOrCreate();

  // Load DNA result for tenure (renter vs owner).
  final dnaRepo = ColourDnaRepository(db);
  final dna =
      profile.colourDnaResultId != null
          ? await dnaRepo.getById(profile.colourDnaResultId!)
          : null;

  final constraints = RenterConstraints(
    isRenter: dna?.tenure == Tenure.renter,
    canPaint: profile.canPaint,
    canDrill: profile.canDrill,
    keepingFlooring: profile.keepingFlooring,
    isTemporaryHome: profile.isTemporaryHome,
    reversibleOnly: profile.reversibleOnly,
  );

  final analytics = AnalyticsService();
  final sessionTracker = SessionTracker(analytics);
  await sessionTracker.start();

  // Initialise A/B testing feature flags (spec 1E.2).
  final featureFlags = FeatureFlagService(analytics);
  await featureFlags.initialise(Experiments.all);

  const sentryDsn = String.fromEnvironment('SENTRY_DSN', defaultValue: '');

  void appRunner() => runApp(
    ProviderScope(
      observers: [SentryProviderObserver()],
      overrides: [
        paletteDatabaseProvider.overrideWithValue(db),
        analyticsProvider.overrideWithValue(analytics),
        featureFlagProvider.overrideWithValue(featureFlags),
        hasCompletedOnboardingProvider.overrideWith(
          (_) => profile.hasCompletedOnboarding,
        ),
        subscriptionTierProvider.overrideWith((_) => profile.subscriptionTier),
        colourBlindModeProvider.overrideWith((_) => profile.colourBlindMode),
        renterConstraintsProvider.overrideWith((_) => constraints),
      ],
      child: const PaletteApp(),
    ),
  );

  if (sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = sentryDsn;
        options.tracesSampleRate = 0.2;
        options.environment = kReleaseMode ? 'production' : 'development';
        options.sendDefaultPii = false;
      },
      appRunner: appRunner,
    );
  } else {
    if (kDebugMode) {
      debugPrint('SENTRY_DSN is empty — Sentry disabled');
    }
    appRunner();
  }
}
