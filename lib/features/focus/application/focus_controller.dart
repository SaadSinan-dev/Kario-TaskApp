import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairo/app/providers.dart';
import 'package:kairo/app/session.dart';
import 'package:kairo/core/utils/id_generator.dart';
import 'package:kairo/domain/entities/enums.dart';
import 'package:kairo/domain/entities/focus_session.dart';
import 'package:kairo/domain/entities/preferences.dart';

/// Everything the focus screen renders from.
@immutable
class FocusState {
  const FocusState({
    required this.phase,
    required this.remaining,
    required this.round,
    required this.settings,
    required this.status,
    this.taskId,
    this.startedAt,
  });

  final FocusPhase phase;
  final Duration remaining;

  /// Which pomodoro of the current set this is, 1-based.
  final int round;

  final FocusSettings settings;
  final FocusStatus status;
  final String? taskId;
  final DateTime? startedAt;

  bool get isRunning => status == FocusStatus.running;
  bool get isPaused => status == FocusStatus.paused;

  Duration get total => Duration(minutes: settings.minutesFor(phase));

  /// 0…1 elapsed.
  double get progress {
    final int totalSeconds = total.inSeconds;
    if (totalSeconds == 0) return 0;
    return (1 - remaining.inSeconds / totalSeconds).clamp(0, 1);
  }

  FocusState copyWith({
    FocusPhase? phase,
    Duration? remaining,
    int? round,
    FocusSettings? settings,
    FocusStatus? status,
    String? taskId,
    bool clearTask = false,
    DateTime? startedAt,
    bool clearStartedAt = false,
  }) {
    return FocusState(
      phase: phase ?? this.phase,
      remaining: remaining ?? this.remaining,
      round: round ?? this.round,
      settings: settings ?? this.settings,
      status: status ?? this.status,
      taskId: clearTask ? null : (taskId ?? this.taskId),
      startedAt: clearStartedAt ? null : (startedAt ?? this.startedAt),
    );
  }
}

enum FocusStatus { idle, running, paused }

/// The Pomodoro engine.
///
/// A single one-second ticker drives the countdown; phase transitions, round
/// counting and session recording all happen here rather than in the widget, so
/// the timer keeps its state while the user navigates away and comes back.
class FocusController extends Notifier<FocusState> {
  Timer? _ticker;

  @override
  FocusState build() {
    final FocusSettings settings = ref.watch(
      preferencesProvider.select((UserPreferences p) => p.focus),
    );
    ref.onDispose(() => _ticker?.cancel());

    // Preserve the running countdown when settings change mid-session; only a
    // fresh idle timer adopts the new duration.
    final FocusState? previous = stateOrNull;
    if (previous != null && previous.status != FocusStatus.idle) {
      return previous.copyWith(settings: settings);
    }

    return FocusState(
      phase: FocusPhase.focus,
      remaining: Duration(minutes: settings.focusMinutes),
      round: 1,
      settings: settings,
      status: FocusStatus.idle,
      taskId: previous?.taskId,
    );
  }

  void selectTask(String taskId) => state = state.copyWith(taskId: taskId);

  void clearTask() => state = state.copyWith(clearTask: true);

  void start() {
    if (state.isRunning) return;
    state = state.copyWith(
      status: FocusStatus.running,
      startedAt: state.startedAt ?? DateTime.now(),
    );
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void pause() {
    if (!state.isRunning) return;
    _ticker?.cancel();
    state = state.copyWith(status: FocusStatus.paused);
  }

  /// Ends the session early and records what actually elapsed.
  void stop() {
    _ticker?.cancel();
    _record(completed: false);
    state = state.copyWith(
      status: FocusStatus.idle,
      remaining: Duration(minutes: state.settings.minutesFor(state.phase)),
      clearStartedAt: true,
    );
  }

  /// Jumps to the next phase without recording a completed session.
  void skip() {
    _ticker?.cancel();
    _advance(recordCompletion: false);
  }

  void switchPhase(FocusPhase phase) {
    _ticker?.cancel();
    state = state.copyWith(
      phase: phase,
      remaining: Duration(minutes: state.settings.minutesFor(phase)),
      status: FocusStatus.idle,
      clearStartedAt: true,
    );
  }

  void _tick() {
    final Duration next = state.remaining - const Duration(seconds: 1);
    if (next.inSeconds <= 0) {
      _ticker?.cancel();
      _advance(recordCompletion: true);
      return;
    }
    state = state.copyWith(remaining: next);
  }

  /// Focus → break → focus, with a long break after the configured number of
  /// rounds.
  void _advance({required bool recordCompletion}) {
    if (recordCompletion) _record(completed: true);

    final FocusSettings settings = state.settings;
    late final FocusPhase nextPhase;
    late final int nextRound;

    if (state.phase == FocusPhase.focus) {
      final bool longBreakDue =
          state.round % settings.roundsBeforeLongBreak == 0;
      nextPhase = longBreakDue ? FocusPhase.longBreak : FocusPhase.shortBreak;
      nextRound = state.round;
    } else {
      nextPhase = FocusPhase.focus;
      nextRound = state.phase == FocusPhase.longBreak ? 1 : state.round + 1;
    }

    state = state.copyWith(
      phase: nextPhase,
      round: nextRound,
      remaining: Duration(minutes: settings.minutesFor(nextPhase)),
      status: FocusStatus.idle,
      clearStartedAt: true,
    );

    if (settings.autoStartBreaks && nextPhase.isBreak) start();
  }

  void _record({required bool completed}) {
    final DateTime? startedAt = state.startedAt;
    if (startedAt == null) return;

    final int elapsed = state.total.inMinutes - state.remaining.inMinutes;
    if (elapsed <= 0) return;

    final String? workspaceId = ref.read(activeWorkspaceIdProvider);
    if (workspaceId == null) return;

    ref
        .read(focusRepositoryProvider)
        .recordSession(
          FocusSession(
            id: Ids.session(),
            workspaceId: workspaceId,
            phase: state.phase,
            taskId: state.taskId,
            startedAt: startedAt,
            plannedMinutes: state.total.inMinutes,
            actualMinutes: elapsed,
            wasCompleted: completed,
          ),
        );
  }
}

final NotifierProvider<FocusController, FocusState> focusControllerProvider =
    NotifierProvider<FocusController, FocusState>(FocusController.new);
