import 'dart:async';

import 'package:flutter/foundation.dart';

/// Collapses a burst of calls into one, [delay] after the last call.
///
/// Used by global search and by inline editing, so a request is issued per
/// pause in typing rather than per keystroke.
class Debouncer {
  Debouncer({this.delay = const Duration(milliseconds: 280)});

  final Duration delay;
  Timer? _timer;

  bool get isPending => _timer?.isActive ?? false;

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// Runs immediately and cancels anything pending — used when the user
  /// presses Enter and expects a result now.
  void flush(VoidCallback action) {
    _timer?.cancel();
    action();
  }

  void cancel() => _timer?.cancel();

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}

/// Guarantees at most one call per [interval] while still delivering the last
/// value. Used for continuous gestures such as timeline scrubbing.
class Throttler {
  Throttler({this.interval = const Duration(milliseconds: 80)});

  final Duration interval;
  DateTime? _lastRun;
  Timer? _trailing;

  void run(VoidCallback action) {
    final DateTime now = DateTime.now();
    if (_lastRun == null || now.difference(_lastRun!) >= interval) {
      _lastRun = now;
      action();
      return;
    }
    _trailing?.cancel();
    _trailing = Timer(interval, () {
      _lastRun = DateTime.now();
      action();
    });
  }

  void dispose() => _trailing?.cancel();
}
