/// Supported client build environments.
enum AppEnvironment {
  development,
  production,
}

/// Client-safe values supplied at build/run time with `--dart-define`.
///
/// Dart defines are compiled into the client and must never contain secrets.
class AppConfig {
    const AppConfig({
        required this.environment,
        this.supabaseUrl = '',
        this.supabaseAnonKey = '',
        this.apiBaseUrl = '',
        this.apiTimeout = const Duration(seconds: 15),
        this.enableAnalytics = false,
    });

    static const _environmentName = String.fromEnvironment(
        'APP_ENV',
        defaultValue: 'development',
    );

    static final AppConfig instance = AppConfig.fromEnvironment();

    factory AppConfig.fromEnvironment() => AppConfig(
                environment: _environmentName == 'production'
                        ? AppEnvironment.production
                        : AppEnvironment.development,
                supabaseUrl: const String.fromEnvironment(
                    'SUPABASE_URL',
                    defaultValue: 'https://innrxslvwzazxaivcvam.supabase.co',
                ),
                supabaseAnonKey: const String.fromEnvironment(
                    'SUPABASE_ANON_KEY',
                    defaultValue: 'sb_publishable_6v8Vx68uKZT2QV0NZhmB8Q_bhZweUx9',
                ),
                apiBaseUrl: const String.fromEnvironment('API_BASE_URL'),
                apiTimeout: Duration(
                    milliseconds: const int.fromEnvironment(
                        'API_TIMEOUT_MS',
                        defaultValue: 15000,
                    ),
                ),
                enableAnalytics: const bool.fromEnvironment('ENABLE_ANALYTICS'),
            );

    final AppEnvironment environment;
    final String supabaseUrl;
    final String supabaseAnonKey;
    final String apiBaseUrl;
    final Duration apiTimeout;
    final bool enableAnalytics;

    bool get isDevelopment => environment == AppEnvironment.development;

    bool get isProduction => environment == AppEnvironment.production;

    bool get isCloudConfigured {
        final uri = Uri.tryParse(supabaseUrl);
        return uri != null &&
                uri.scheme == 'https' &&
                uri.host.isNotEmpty &&
                supabaseAnonKey.isNotEmpty;
    }

}
