/// API-related constants including base URLs, endpoints, timeouts, and headers.
library;

/// Constants for all remote API communication.
abstract final class ApiConstants {
  // ── Base URLs ───────────────────────────────────────────────────────

  /// Supabase project URL (loaded from env at runtime; this is a fallback).
  static const String supabaseUrl = 'https://your-project.supabase.co';

  /// Supabase anonymous key placeholder.
  static const String supabaseAnonKey = 'your-anon-key';

  /// Base URL for the IPTV metadata API (if applicable).
  static const String iptvApiBaseUrl = 'https://api.saiful-iptv.example.com/v1';

  // ── Endpoints ───────────────────────────────────────────────────────

  /// Authentication endpoints.
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String refreshTokenEndpoint = '/auth/refresh';
  static const String logoutEndpoint = '/auth/logout';
  static const String profileEndpoint = '/auth/profile';

  /// Playlist endpoints.
  static const String playlistsEndpoint = '/playlists';
  static const String playlistParseEndpoint = '/playlists/parse';

  /// Channel / stream endpoints.
  static const String channelsEndpoint = '/channels';
  static const String categoriesEndpoint = '/categories';

  /// EPG endpoints.
  static const String epgEndpoint = '/epg';
  static const String epgRefreshEndpoint = '/epg/refresh';

  /// Sync endpoints.
  static const String syncEndpoint = '/sync';
  static const String syncStatusEndpoint = '/sync/status';

  // ── Timeouts ────────────────────────────────────────────────────────

  /// Default connection timeout in milliseconds.
  static const int connectTimeoutMs = 15000;

  /// Default receive timeout in milliseconds.
  static const int receiveTimeoutMs = 30000;

  /// Default send timeout in milliseconds.
  static const int sendTimeoutMs = 15000;

  /// Stream URL validation timeout in milliseconds.
  static const int streamCheckTimeoutMs = 10000;

  /// EPG download timeout in milliseconds.
  static const int epgDownloadTimeoutMs = 60000;

  // ── Headers ─────────────────────────────────────────────────────────

  /// Default `Content-Type` header value.
  static const String contentTypeJson = 'application/json';

  /// Default `Accept` header value.
  static const String acceptJson = 'application/json';

  /// Custom user-agent string.
  static const String userAgent = 'SaifulIPTVPlayer/1.0.0';

  /// Header key for the authorization bearer token.
  static const String authHeaderKey = 'Authorization';

  /// Header key for the API key.
  static const String apiKeyHeaderKey = 'X-API-Key';

  // ── Retry Configuration ─────────────────────────────────────────────

  /// Maximum number of automatic retries for failed requests.
  static const int maxRetries = 3;

  /// Base delay between retries in milliseconds (exponential back-off).
  static const int retryBaseDelayMs = 1000;
}
