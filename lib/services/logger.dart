import 'dart:developer' as developer;

class Logger {
  static const String _tag = 'WUNEO';

  static void debug(String message) {
    developer.log(message, name: _tag, level: 500);
  }

  static void info(String message) {
    developer.log(message, name: _tag, level: 800);
  }

  static void warning(String message) {
    developer.log(message, name: _tag, level: 900);
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: _tag,
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }

  // For development only - will be stripped in release builds
  static void dev(String message) {
    assert(() {
      developer.log(message, name: '$_tag-DEV');
      return true;
    }());
  }
}
