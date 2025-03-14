import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// A simple logger for the application that formats messages consistently
/// and handles different log levels.
class AppLogger {
  static final AppLogger _instance = AppLogger._internal();

  // Factory constructor
  factory AppLogger() {
    return _instance;
  }

  // Private constructor
  AppLogger._internal();

  final DateFormat _dateFormatter = DateFormat('yyyy-MM-ddTHH:mm:ss.SSSSSS');

  String _getTimestamp() {
    return _dateFormatter.format(DateTime.now());
  }

  void info(String message) {
    _log('INFO', message);
  }

  void warning(String message) {
    _log('WARNING', message);
  }

  void error(String message, {Object? error, StackTrace? stackTrace}) {
    String errorMsg = message;
    if (error != null) {
      errorMsg += '\nError: $error';
    }
    _log('ERROR', errorMsg);

    if (stackTrace != null) {
      _log('ERROR', 'Stack trace: $stackTrace');
    }
  }

  void _log(String level, String message) {
    if (kDebugMode) {
      print('${_getTimestamp()} [$level] $message');
    }
  }
}
