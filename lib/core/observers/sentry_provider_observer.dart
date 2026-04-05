import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Catches all Riverpod provider errors and sends them to Sentry.
///
/// Background provider failures are logged silently — user-facing feedback
/// is the responsibility of the code that triggered the action.
class SentryProviderObserver extends ProviderObserver {
  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    Sentry.captureException(
      error,
      stackTrace: stackTrace,
      hint: Hint.withMap({
        'provider': provider.name ?? provider.runtimeType.toString(),
      }),
    );
  }
}
