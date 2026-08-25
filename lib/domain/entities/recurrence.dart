import 'package:flutter/foundation.dart';
import 'package:kairo/domain/entities/enums.dart';
import 'package:kairo/domain/entities/json_support.dart';

/// How a task repeats.
///
/// The rule is a value object with the scheduling logic attached, so "what is
/// the next occurrence" is answered in one place and is unit-testable without
/// touching a repository.
@immutable
class RecurrenceRule {
  const RecurrenceRule({
    required this.frequency,
    this.interval = 1,
    this.weekdays = const <int>[],
    this.dayOfMonth,
    this.until,
    this.maxOccurrences,
  });

  static const RecurrenceRule none = RecurrenceRule(
    frequency: RecurrenceFrequency.none,
  );

  final RecurrenceFrequency frequency;

  /// Repeat every [interval] units of [frequency]. "Every 2 weeks" is
  /// `weekly` with an interval of 2.
  final int interval;

  /// For weekly rules: [DateTime.monday]…[DateTime.sunday]. Empty means "the
  /// same weekday as the anchor date".
  final List<int> weekdays;

  /// For monthly rules: clamped to the last day of short months.
  final int? dayOfMonth;

  final DateTime? until;
  final int? maxOccurrences;

  bool get isEnabled => frequency != RecurrenceFrequency.none;

  /// The next due date strictly after [from], or null when the rule has ended.
  DateTime? nextOccurrence(DateTime from) {
    if (!isEnabled) return null;
    final DateTime anchor = DateTime(from.year, from.month, from.day);
    final DateTime? next = switch (frequency) {
      RecurrenceFrequency.none => null,
      RecurrenceFrequency.daily => anchor.add(Duration(days: interval)),
      RecurrenceFrequency.weekly => _nextWeekly(anchor),
      RecurrenceFrequency.monthly => _nextMonthly(anchor),
      RecurrenceFrequency.custom =>
        weekdays.isNotEmpty
            ? _nextWeekly(anchor)
            : anchor.add(Duration(days: interval)),
    };
    if (next == null) return null;
    if (until != null && next.isAfter(until!)) return null;
    return next;
  }

  DateTime _nextWeekly(DateTime anchor) {
    if (weekdays.isEmpty) return anchor.add(Duration(days: 7 * interval));
    final List<int> sorted = <int>[...weekdays]..sort();
    for (int offset = 1; offset <= 7; offset++) {
      final DateTime candidate = anchor.add(Duration(days: offset));
      if (sorted.contains(candidate.weekday)) return candidate;
    }
    // No weekday matched inside a week — jump by the interval and retry.
    return anchor.add(Duration(days: 7 * interval));
  }

  DateTime _nextMonthly(DateTime anchor) {
    final int targetDay = dayOfMonth ?? anchor.day;
    final int totalMonths = anchor.month - 1 + interval;
    final int year = anchor.year + (totalMonths / 12).floor();
    final int month = totalMonths % 12 + 1;
    final int lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, targetDay > lastDay ? lastDay : targetDay);
  }

  RecurrenceRule copyWith({
    RecurrenceFrequency? frequency,
    int? interval,
    List<int>? weekdays,
    int? dayOfMonth,
    bool clearDayOfMonth = false,
    DateTime? until,
    bool clearUntil = false,
    int? maxOccurrences,
  }) {
    return RecurrenceRule(
      frequency: frequency ?? this.frequency,
      interval: interval ?? this.interval,
      weekdays: weekdays ?? this.weekdays,
      dayOfMonth: clearDayOfMonth ? null : (dayOfMonth ?? this.dayOfMonth),
      until: clearUntil ? null : (until ?? this.until),
      maxOccurrences: maxOccurrences ?? this.maxOccurrences,
    );
  }

  JsonMap toJson() => <String, dynamic>{
    'frequency': frequency.name,
    'interval': interval,
    'weekdays': weekdays,
    'dayOfMonth': dayOfMonth,
    'until': writeDate(until),
    'maxOccurrences': maxOccurrences,
  };

  factory RecurrenceRule.fromJson(JsonMap json) => RecurrenceRule(
    frequency: enumFromName(
      RecurrenceFrequency.values,
      json['frequency'],
      RecurrenceFrequency.none,
    ),
    interval: readInt(json['interval'], 1).clamp(1, 365),
    weekdays: (json['weekdays'] as List<dynamic>? ?? const <dynamic>[])
        .map(readInt)
        .where((int v) => v >= 1 && v <= 7)
        .toList(),
    dayOfMonth: readIntOrNull(json['dayOfMonth']),
    until: readDate(json['until']),
    maxOccurrences: readIntOrNull(json['maxOccurrences']),
  );

  @override
  bool operator ==(Object other) =>
      other is RecurrenceRule &&
      other.frequency == frequency &&
      other.interval == interval &&
      other.dayOfMonth == dayOfMonth &&
      other.until == until &&
      other.weekdays.join(',') == weekdays.join(',');

  @override
  int get hashCode =>
      Object.hash(frequency, interval, dayOfMonth, until, weekdays.join(','));
}
