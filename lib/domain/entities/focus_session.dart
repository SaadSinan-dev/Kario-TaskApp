import 'package:kairo/domain/entities/enums.dart';
import 'package:kairo/domain/entities/json_support.dart';
import 'package:meta/meta.dart';

/// One completed (or abandoned) stretch of focused work.
@immutable
class FocusSession {
  const FocusSession({
    required this.id,
    required this.workspaceId,
    required this.phase,
    required this.startedAt,
    required this.plannedMinutes,
    required this.actualMinutes,
    this.taskId,
    this.wasCompleted = true,
  });

  final String id;
  final String workspaceId;
  final FocusPhase phase;
  final String? taskId;
  final DateTime startedAt;

  /// What the timer was set to.
  final int plannedMinutes;

  /// What actually elapsed before the session ended.
  final int actualMinutes;

  /// False when the user ended the session early.
  final bool wasCompleted;

  JsonMap toJson() => <String, dynamic>{
    'id': id,
    'workspaceId': workspaceId,
    'phase': phase.name,
    'taskId': taskId,
    'startedAt': writeDate(startedAt),
    'plannedMinutes': plannedMinutes,
    'actualMinutes': actualMinutes,
    'wasCompleted': wasCompleted,
  };

  factory FocusSession.fromJson(JsonMap json) => FocusSession(
    id: readString(json['id']),
    workspaceId: readString(json['workspaceId']),
    phase: enumFromName(FocusPhase.values, json['phase'], FocusPhase.focus),
    taskId: json['taskId'] as String?,
    startedAt: readDateOr(json['startedAt'], DateTime.now()),
    plannedMinutes: readInt(json['plannedMinutes'], 25),
    actualMinutes: readInt(json['actualMinutes']),
    wasCompleted: readBool(json['wasCompleted'], true),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is FocusSession && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// User-configurable Pomodoro timings.
@immutable
class FocusSettings {
  const FocusSettings({
    this.focusMinutes = 25,
    this.shortBreakMinutes = 5,
    this.longBreakMinutes = 15,
    this.roundsBeforeLongBreak = 4,
    this.autoStartBreaks = true,
    this.ambientMotion = true,
  });

  final int focusMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;
  final int roundsBeforeLongBreak;
  final bool autoStartBreaks;

  /// The slow gradient drift behind the timer. Disabled automatically when the
  /// platform asks for reduced motion.
  final bool ambientMotion;

  int minutesFor(FocusPhase phase) => switch (phase) {
    FocusPhase.focus => focusMinutes,
    FocusPhase.shortBreak => shortBreakMinutes,
    FocusPhase.longBreak => longBreakMinutes,
  };

  FocusSettings copyWith({
    int? focusMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    int? roundsBeforeLongBreak,
    bool? autoStartBreaks,
    bool? ambientMotion,
  }) {
    return FocusSettings(
      focusMinutes: focusMinutes ?? this.focusMinutes,
      shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
      longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
      roundsBeforeLongBreak:
          roundsBeforeLongBreak ?? this.roundsBeforeLongBreak,
      autoStartBreaks: autoStartBreaks ?? this.autoStartBreaks,
      ambientMotion: ambientMotion ?? this.ambientMotion,
    );
  }

  JsonMap toJson() => <String, dynamic>{
    'focusMinutes': focusMinutes,
    'shortBreakMinutes': shortBreakMinutes,
    'longBreakMinutes': longBreakMinutes,
    'roundsBeforeLongBreak': roundsBeforeLongBreak,
    'autoStartBreaks': autoStartBreaks,
    'ambientMotion': ambientMotion,
  };

  factory FocusSettings.fromJson(JsonMap json) => FocusSettings(
    focusMinutes: readInt(json['focusMinutes'], 25).clamp(5, 120),
    shortBreakMinutes: readInt(json['shortBreakMinutes'], 5).clamp(1, 30),
    longBreakMinutes: readInt(json['longBreakMinutes'], 15).clamp(5, 60),
    roundsBeforeLongBreak: readInt(
      json['roundsBeforeLongBreak'],
      4,
    ).clamp(2, 8),
    autoStartBreaks: readBool(json['autoStartBreaks'], true),
    ambientMotion: readBool(json['ambientMotion'], true),
  );
}
