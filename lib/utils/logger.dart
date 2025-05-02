import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// Centralized logging configuration for the app
class AppLogger {
  final Logger _logger;
  static bool _initialized = false;

  /// Create a logger with a specific name
  AppLogger(String name) : _logger = Logger(name) {
    _ensureInitialized();
  }

  /// Initialize the logging system once
  static void _ensureInitialized() {
    if (!_initialized) {
      Logger.root.level = kDebugMode ? Level.ALL : Level.INFO;
      Logger.root.onRecord.listen((record) {
        if (kDebugMode) {
          print(
              '${record.level.name}: ${record.time}: (${record.loggerName}) ${record.message}');
          if (record.error != null) {
            print('ERROR: ${record.error}');
          }
          if (record.stackTrace != null) {
            print('STACKTRACE: ${record.stackTrace}');
          }
        }
      });
      _initialized = true;
    }
  }

  /// Log a detailed message (for debugging purposes)
  void fine(String message) => _logger.fine(message);

  /// Log informational message
  void info(String message) => _logger.info(message);

  /// Log warning message
  void warning(String message) => _logger.warning(message);

  /// Log error message
  void severe(String message, [Object? error, StackTrace? stackTrace]) =>
      _logger.severe(message, error, stackTrace);
}
