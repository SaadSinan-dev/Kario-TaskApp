import 'package:intl/intl.dart';
import 'package:kairo/l10n/generated/app_localizations.dart';

/// Date helpers shared by the calendar, timeline, task list and analytics.
///
/// Everything here is pure and timezone-naive on purpose: Kairo stores due
/// dates as calendar days, so "due Friday" doesn't shift when a user travels.
abstract final class Dates {
  /// Strips the time component, giving a comparable calendar day.
  static DateTime dayOf(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static DateTime today() => dayOf(DateTime.now());

  static bool isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static bool isSameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  static bool isToday(DateTime value) => isSameDay(value, DateTime.now());

  static bool isPast(DateTime value) => dayOf(value).isBefore(today());

  static int daysBetween(DateTime from, DateTime to) =>
      dayOf(to).difference(dayOf(from)).inDays;

  /// Start of the week containing [value]. [weekStartsOn] uses
  /// [DateTime.monday]…[DateTime.sunday].
  static DateTime startOfWeek(
    DateTime value, {
    int weekStartsOn = DateTime.monday,
  }) {
    final DateTime day = dayOf(value);
    final int diff = (day.weekday - weekStartsOn + 7) % 7;
    return day.subtract(Duration(days: diff));
  }

  static DateTime endOfWeek(
    DateTime value, {
    int weekStartsOn = DateTime.monday,
  }) => startOfWeek(
    value,
    weekStartsOn: weekStartsOn,
  ).add(const Duration(days: 6));

  static DateTime startOfMonth(DateTime value) =>
      DateTime(value.year, value.month);

  static DateTime endOfMonth(DateTime value) =>
      DateTime(value.year, value.month + 1, 0);

  static DateTime addMonths(DateTime value, int months) {
    final int total = value.month - 1 + months;
    final int year = value.year + (total / 12).floor();
    final int month = total % 12 + 1;
    final int lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, value.day > lastDay ? lastDay : value.day);
  }

  /// The 42 cells (6 weeks) a month grid always renders, so the calendar never
  /// changes height as the user pages through months.
  static List<DateTime> monthGrid(
    DateTime month, {
    int weekStartsOn = DateTime.monday,
  }) {
    final DateTime first = startOfWeek(
      startOfMonth(month),
      weekStartsOn: weekStartsOn,
    );
    return <DateTime>[
      for (int i = 0; i < 42; i++) first.add(Duration(days: i)),
    ];
  }

  static List<DateTime> weekDays(
    DateTime anchor, {
    int weekStartsOn = DateTime.monday,
  }) {
    final DateTime first = startOfWeek(anchor, weekStartsOn: weekStartsOn);
    return <DateTime>[for (int i = 0; i < 7; i++) first.add(Duration(days: i))];
  }

  static List<DateTime> range(DateTime from, DateTime to) {
    final int count = daysBetween(from, to);
    return <DateTime>[
      for (int i = 0; i <= count; i++) dayOf(from).add(Duration(days: i)),
    ];
  }

  // --- Formatting -----------------------------------------------------------

  static final DateFormat _dayMonth = DateFormat('d MMM');
  static final DateFormat _dayMonthYear = DateFormat('d MMM yyyy');
  static final DateFormat _weekdayShort = DateFormat('EEE');
  static final DateFormat _weekdayLong = DateFormat('EEEE');
  static final DateFormat _monthYear = DateFormat('MMMM yyyy');
  static final DateFormat _monthShort = DateFormat('MMM');
  static final DateFormat _time = DateFormat('HH:mm');

  static String dayMonth(DateTime v) => _dayMonth.format(v);
  static String dayMonthYear(DateTime v) => _dayMonthYear.format(v);
  static String weekdayShort(DateTime v) => _weekdayShort.format(v);
  static String weekdayLong(DateTime v) => _weekdayLong.format(v);
  static String monthYear(DateTime v) => _monthYear.format(v);
  static String monthShort(DateTime v) => _monthShort.format(v);
  static String time(DateTime v) => _time.format(v);

  /// Human due-date label: "Today", "Tomorrow", "3 Mar", or the year when the
  /// date is outside the current one.
  static String dueLabel(DateTime? due, AppL10n l10n) {
    if (due == null) return l10n.timeNoDate;
    final DateTime now = today();
    final int delta = daysBetween(now, due);
    if (delta == 0) return l10n.timeToday;
    if (delta == 1) return l10n.timeTomorrow;
    if (delta == -1) return l10n.timeYesterday;
    if (due.year == now.year) return dayMonth(due);
    return dayMonthYear(due);
  }

  /// Relative timestamp for activity feeds and comments.
  static String relative(DateTime value, AppL10n l10n) {
    final Duration delta = DateTime.now().difference(value);
    if (delta.inMinutes < 1) return l10n.timeJustNow;
    if (delta.inMinutes < 60) return l10n.timeMinutesAgo(delta.inMinutes);
    if (delta.inHours < 24) return l10n.timeHoursAgo(delta.inHours);
    if (delta.inDays < 7) return l10n.timeDaysAgo(delta.inDays);
    return value.year == DateTime.now().year
        ? dayMonth(value)
        : dayMonthYear(value);
  }

  /// "2h 30m" style duration used for estimates and focus totals.
  static String duration(int minutes) {
    if (minutes <= 0) return '0m';
    final int hours = minutes ~/ 60;
    final int rest = minutes % 60;
    if (hours == 0) return '${rest}m';
    if (rest == 0) return '${hours}h';
    return '${hours}h ${rest}m';
  }

  /// mm:ss for the focus timer.
  static String clock(Duration remaining) {
    final int total = remaining.inSeconds.clamp(0, 86400);
    final String m = (total ~/ 60).toString().padLeft(2, '0');
    final String s = (total % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
