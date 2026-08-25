import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

enum LogLevel { trace, debug, info, warn, error }

/// A tiny structured logger.
///
/// Deliberately not a package: the app only needs levelled, tagged output that
/// disappears in release builds and can be swapped for a real sink (Sentry,
/// Crashlytics, a backend endpoint) by replacing [AppLogger.sink].
class AppLogger {
  const AppLogger(this.tag);

  final String tag;

  /// Where records go. Replace once at startup to ship logs somewhere real.
  static void Function(LogRecord record) sink = _developerSink;

  /// Records below this level are dropped. Release builds stay quiet unless a
  /// warning or error occurs.
  static LogLevel minimumLevel = kReleaseMode ? LogLevel.warn : LogLevel.debug;

  void trace(String message, {Map<String, Object?>? data}) =>
      _log(LogLevel.trace, message, data: data);

  void debug(String message, {Map<String, Object?>? data}) =>
      _log(LogLevel.debug, message, data: data);

  void info(String message, {Map<String, Object?>? data}) =>
      _log(LogLevel.info, message, data: data);

  void warn(String message, {Map<String, Object?>? data, Object? error}) =>
      _log(LogLevel.warn, message, data: data, error: error);

  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? data,
  }) => _log(
    LogLevel.error,
    message,
    data: data,
    error: error,
    stackTrace: stackTrace,
  );

  void _log(
    LogLevel level,
    String message, {
    Map<String, Object?>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (level.index < minimumLevel.index) return;
    sink(
      LogRecord(
        level: level,
        tag: tag,
        message: message,
        data: data,
        error: error,
        stackTrace: stackTrace,
        time: DateTime.now(),
      ),
    );
  }

  static void _developerSink(LogRecord record) {
    final String payload = record.data == null || record.data!.isEmpty
        ? record.message
        : '${record.message} ${record.data}';
    developer.log(
      payload,
      name: 'kairo.${record.tag}',
      level: switch (record.level) {
        LogLevel.trace => 300,
        LogLevel.debug => 500,
        LogLevel.info => 800,
        LogLevel.warn => 900,
        LogLevel.error => 1000,
      },
      error: record.error,
      stackTrace: record.stackTrace,
      time: record.time,
    );
  }
}

@immutable
class LogRecord {
  const LogRecord({
    required this.level,
    required this.tag,
    required this.message,
    required this.time,
    this.data,
    this.error,
    this.stackTrace,
  });

  final LogLevel level;
  final String tag;
  final String message;
  final DateTime time;
  final Map<String, Object?>? data;
  final Object? error;
  final StackTrace? stackTrace;
}
