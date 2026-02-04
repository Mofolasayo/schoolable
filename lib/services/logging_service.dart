import 'package:flutter/foundation.dart';

class AppLogger {
  static void log(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('error') ||
        lower.contains('failed') ||
        lower.contains('critical') ||
        lower.contains('auth required') ||
        lower.contains('not authenticated') ||
        lower.contains('cannot')) {
      error(message);
      return;
    }
    if (lower.contains('warn') ||
        lower.contains('no token') ||
        lower.contains('missing') ||
        lower.contains('unknown')) {
      warn(message);
      return;
    }
    info(message);
  }

  static void info(String message) {
    _log('INFO', message);
  }

  static void warn(String message) {
    _log('WARN', message);
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    _log('ERROR', message);
    if (error != null) {
      debugPrint('ERROR: $error');
    }
    if (stackTrace != null) {
      debugPrint(stackTrace.toString());
    }
  }

  static void _log(String level, String message) {
    debugPrint('[$level] $message');
  }
}
