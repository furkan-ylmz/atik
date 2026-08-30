import 'package:flutter/foundation.dart';

class AppLogger {
  AppLogger._();

  static void info(String message, [String? tag]) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag] ' : '[INFO] ';
      debugPrint('$prefix$message');
    }
  }

  static void error(String message, [Object? error, StackTrace? stackTrace, String? tag]) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag ERROR] ' : '[ERROR] ';
      debugPrint('$prefix$message');
      if (error != null) {
        debugPrint('$prefix Details: $error');
      }
      if (stackTrace != null) {
        debugPrint('$prefix StackTrace: $stackTrace');
      }
    }
  }
}
