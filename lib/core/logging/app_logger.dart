import 'package:flutter/foundation.dart';

/// Minimal logger. Debug builds print to the console; release builds stay
/// silent until a crash-reporting service is wired into [_report] (1F).
abstract final class AppLogger {
  static void debug(String message) {
    if (kDebugMode) debugPrint('[debug] $message');
  }

  static void warning(String message) {
    if (kDebugMode) debugPrint('[warn] $message');
  }

  static void error(String message, Object error, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('[error] $message: $error');
      if (stackTrace != null) debugPrint(stackTrace.toString());
    }
    _report(message, error, stackTrace);
  }

  static void _report(String message, Object error, StackTrace? stackTrace) {
    // TODO(1F): forward to Crashlytics / Sentry.
  }
}
