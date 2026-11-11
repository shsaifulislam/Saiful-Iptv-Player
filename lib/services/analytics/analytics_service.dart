/// Abstract analytics interface for the Saiful IPTV Player.
///
/// Implementations may target Firebase Analytics, Mixpanel, Amplitude,
/// a custom backend, or simply log to console during development.
/// Using an abstract interface allows swapping providers without touching
/// feature code.
abstract class AnalyticsService {
  /// Tracks a discrete event identified by [name] with optional [parameters].
  ///
  /// Example:
  /// ```dart
  /// analytics.trackEvent(AnalyticsEvents.playbackStart, {
  ///   AnalyticsParams.contentId: channel.id,
  ///   AnalyticsParams.contentType: 'live',
  /// });
  /// ```
  Future<void> trackEvent(
    String name, [
    Map<String, Object>? parameters,
  ]);

  /// Records a screen / page view for [screenName].
  ///
  /// Useful for funnel analysis and understanding navigation patterns.
  Future<void> trackScreen(String screenName);

  /// Sets a persistent user property that is attached to every subsequent
  /// event.
  ///
  /// Example: `setUserProperty('subscription_tier', 'premium')`.
  Future<void> setUserProperty(String name, String value);

  /// Convenience method for tracking playback events with standard metadata.
  ///
  /// [eventName] is one of the `playback_*` constants from
  /// [AnalyticsEvents]. [contentId] identifies the channel / VOD.
  /// [contentType] is `live`, `vod`, or `series`.
  /// [durationSeconds] is the elapsed playback time when the event fires.
  /// [extra] allows attaching additional context.
  Future<void> trackPlayback({
    required String eventName,
    required String contentId,
    required String contentType,
    int? durationSeconds,
    Map<String, Object>? extra,
  });

  /// Tracks a non-fatal application error.
  ///
  /// [message] is a human-readable description; [errorCode] is an optional
  /// machine-readable code; [stackTrace] provides debugging context.
  Future<void> trackError({
    required String message,
    String? errorCode,
    String? stackTrace,
  });

  /// Sets the user ID for analytics attribution.
  ///
  /// Pass `null` to clear (e.g. on sign-out).
  Future<void> setUserId(String? userId);

  /// Flushes any buffered events to the analytics backend.
  Future<void> flush();
}

/// Development / debug implementation that logs analytics events to the
/// console.
///
/// Use this in debug builds to verify event instrumentation without sending
/// data to a remote service.
class ConsoleAnalyticsService implements AnalyticsService {
  @override
  Future<void> trackEvent(
    String name, [
    Map<String, Object>? parameters,
  ]) async {
    // ignore: avoid_print
    print('[Analytics] event: $name ${parameters ?? ''}');
  }

  @override
  Future<void> trackScreen(String screenName) async {
    // ignore: avoid_print
    print('[Analytics] screen: $screenName');
  }

  @override
  Future<void> setUserProperty(String name, String value) async {
    // ignore: avoid_print
    print('[Analytics] user_property: $name = $value');
  }

  @override
  Future<void> trackPlayback({
    required String eventName,
    required String contentId,
    required String contentType,
    int? durationSeconds,
    Map<String, Object>? extra,
  }) async {
    // ignore: avoid_print
    print(
      '[Analytics] playback: $eventName '
      'content=$contentId type=$contentType '
      'duration=${durationSeconds ?? 'n/a'} '
      '${extra ?? ''}',
    );
  }

  @override
  Future<void> trackError({
    required String message,
    String? errorCode,
    String? stackTrace,
  }) async {
    // ignore: avoid_print
    print('[Analytics] error: $message code=$errorCode');
  }

  @override
  Future<void> setUserId(String? userId) async {
    // ignore: avoid_print
    print('[Analytics] userId: $userId');
  }

  @override
  Future<void> flush() async {
    // No-op for console implementation.
  }
}
