import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

class AppLogger {
  AppLogger(String name) : _logger = Logger(name);

  static final RegExp _secretPattern = RegExp(
    r'\b(password|token|api[_-]?key|authorization)\s*[:=]\s*[^\s,&]+',
    caseSensitive: false,
  );
  static StreamSubscription<LogRecord>? _subscription;

  final Logger _logger;

  static void configure({required bool verbose}) {
    if (_subscription != null) return;

    Logger.root.level = verbose ? Level.ALL : Level.WARNING;
    _subscription = Logger.root.onRecord.listen((record) {
      debugPrint(
        '[${record.level.name}] ${record.loggerName}: '
        '${_redact(record.message)}',
      );
    });
  }

  void info(String message) => _logger.info(_redact(message));

  void warning(String message) => _logger.warning(_redact(message));

  void error(String message, {Object? error, StackTrace? stackTrace}) {
    final type = error == null ? '' : ' (${error.runtimeType})';
    _logger.severe(_redact('$message$type'));
  }

  static String _redact(String value) => value.replaceAllMapped(
        _secretPattern,
        (match) => '${match[1]}=[REDACTED]',
      );
}

final appLoggerProvider = Provider<AppLogger>((ref) => AppLogger('App'));