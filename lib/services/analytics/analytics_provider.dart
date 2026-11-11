import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'analytics_service.dart';

/// Provides the application-wide [AnalyticsService] instance.
///
/// Defaults to [ConsoleAnalyticsService] for development. Override this
/// provider at the [ProviderScope] level to inject a production
/// implementation (e.g. Firebase Analytics, Mixpanel).
///
/// ```dart
/// ProviderScope(
///   overrides: [
///     analyticsServiceProvider.overrideWithValue(FirebaseAnalyticsService()),
///   ],
///   child: MyApp(),
/// )
/// ```
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return ConsoleAnalyticsService();
});
