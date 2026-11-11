import 'dart:ui';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'package:saiful_iptv_player/app/app.dart';
import 'package:saiful_iptv_player/app/config/app_config.dart';
import 'package:saiful_iptv_player/core/logging/app_logger.dart';
import 'package:saiful_iptv_player/data/local/secure_session_storage.dart';

final _log = AppLogger('Bootstrap');

/// Bootstraps the entire application.
///
/// Initializes framework error handling and launches the app in a
/// [ProviderScope]. Cloud and playback services remain opt-in until configured.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLogger.configure(verbose: AppConfig.instance.isDevelopment);
  _setupErrorHandling();

  final config = AppConfig.instance;
  if (!config.isCloudConfigured) {
    _log.warning('Cloud services are not configured for this build.');
  } else {
    final secureStorage = SecureSessionStorage();
    try {
      await supabase.Supabase.initialize(
        url: config.supabaseUrl,
        publishableKey: config.supabaseAnonKey,
        authOptions: supabase.FlutterAuthClientOptions(
          localStorage: secureStorage,
          pkceAsyncStorage: secureStorage,
        ),
        debug: false,
      );
      _log.info('Supabase initialized with secure session storage.');
    } catch (error, stackTrace) {
      _log.error(
        'Supabase initialization failed; continuing offline.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  runApp(
    const ProviderScope(
      child: SaifulIPTVApp(),
    ),
  );
}

/// Installs global error handlers for both Flutter framework errors and
/// uncaught asynchronous errors.
void _setupErrorHandling() {
  FlutterError.onError = (FlutterErrorDetails details) {
    _log.error('Flutter framework error', error: details.exception);
    if (kDebugMode) {
      FlutterError.presentError(details);
    }
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    _log.error('Uncaught platform error', error: error, stackTrace: stack);
    return false;
  };
}
