import 'package:flutter_test/flutter_test.dart';
import 'package:kairo/core/utils/date_utils.dart';
import 'package:kairo/core/utils/fuzzy_match.dart';
import 'package:kairo/core/utils/validators.dart';
import 'package:kairo/domain/entities/enums.dart';
import 'package:kairo/domain/entities/recurrence.dart';
import 'package:kairo/domain/entities/user.dart';

/// Value-object behaviour: recurrence scheduling, date maths, fuzzy matching
/// and the estimate parser. All pure, all cheap to test, all easy to get
/// subtly wrong.
void main() {
  group('RecurrenceRule.nextOccurrence', () {
    test('daily advances by the interval', () {
      const RecurrenceRule rule = RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        interval: 3,
      );
      expect(rule.nextOccurrence(DateTime(2026, 3, 10)), DateTime(2026, 3, 13));
    });

    test('weekly without weekdays advances a whole week', () {
      const RecurrenceRule rule = RecurrenceRule(
        frequency: RecurrenceFrequency.weekly,
      );
      expect(rule.nextOccurrence(DateTime(2026, 3, 10)), DateTime(2026, 3, 17));
    });

    test('weekly with weekdays picks the next matching day', () {
      // 10 March 2026 is a Tuesday; the next Thursday is the 12th.
      const RecurrenceRule rule = RecurrenceRule(
        frequency: RecurrenceFrequency.weekly,
        weekdays: <int>[DateTime.tuesday, DateTime.thursday],
      );
      expect(rule.nextOccurrence(DateTime(2026, 3, 10)), DateTime(2026, 3, 12));
    });

    test('monthly clamps to the last day of a shorter month', () {
      const RecurrenceRule rule = RecurrenceRule(
        frequency: RecurrenceFrequency.monthly,
      );
      // 31 January + 1 month has no 31st, so it lands on 28 February.
      expect(rule.nextOccurrence(DateTime(2026, 1, 31)), DateTime(2026, 2, 28));
    });

    test('stops once the rule passes its end date', () {
      final RecurrenceRule rule = RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        until: DateTime(2026, 3, 11),
      );
      expect(rule.nextOccurrence(DateTime(2026, 3, 10)), isNotNull);
      expect(rule.nextOccurrence(DateTime(2026, 3, 11)), isNull);
    });

    test('a disabled rule never produces an occurrence', () {
      expect(RecurrenceRule.none.nextOccurrence(DateTime(2026, 3, 10)), isNull);
      expect(RecurrenceRule.none.isEnabled, isFalse);
    });
  });

  group('Dates', () {
    test('startOfWeek honours the configured first day', () {
      final DateTime wednesday = DateTime(2026, 3, 11);
      expect(Dates.startOfWeek(wednesday), DateTime(2026, 3, 9));
      expect(
        Dates.startOfWeek(wednesday, weekStartsOn: DateTime.sunday),
        DateTime(2026, 3, 8),
      );
    });

    test('monthGrid always returns six weeks', () {
      expect(Dates.monthGrid(DateTime(2026, 2)).length, 42);
      expect(Dates.monthGrid(DateTime(2026, 8)).length, 42);
    });

    test('addMonths clamps the day of month', () {
      expect(Dates.addMonths(DateTime(2026, 1, 31), 1), DateTime(2026, 2, 28));
    });

    test('duration renders hours and minutes', () {
      expect(Dates.duration(0), '0m');
      expect(Dates.duration(45), '45m');
      expect(Dates.duration(60), '1h');
      expect(Dates.duration(150), '2h 30m');
    });

    test('clock pads to mm:ss', () {
      expect(Dates.clock(const Duration(minutes: 25)), '25:00');
      expect(Dates.clock(const Duration(seconds: 9)), '00:09');
      expect(Dates.clock(Duration.zero), '00:00');
    });
  });

  group('Fuzzy', () {
    test('a contiguous substring outranks a scattered match', () {
      final int direct = Fuzzy.match('onboarding flow', 'onboard').score;
      final int scattered = Fuzzy.match(
        'open notebook and read',
        'onboard',
      ).score;
      expect(direct, greaterThan(scattered));
    });

    test('returns the matched positions for highlighting', () {
      final FuzzyMatch match = Fuzzy.match('Pricing page', 'pri');
      expect(match.isMatch, isTrue);
      expect(match.positions, <int>[0, 1, 2]);
    });

    test('a missing character means no match', () {
      expect(Fuzzy.match('pricing', 'zzz').isMatch, isFalse);
    });

    test('an empty query matches everything', () {
      expect(Fuzzy.match('anything', '').isMatch, isTrue);
    });
  });

  group('Validators.parseEstimateMinutes', () {
    test('reads plain hours', () {
      expect(Validators.parseEstimateMinutes('2'), 120);
      expect(Validators.parseEstimateMinutes('1.5'), 90);
    });

    test('reads explicit units', () {
      expect(Validators.parseEstimateMinutes('3h'), 180);
      expect(Validators.parseEstimateMinutes('45m'), 45);
    });

    test('rejects nonsense', () {
      expect(Validators.parseEstimateMinutes(''), isNull);
      expect(Validators.parseEstimateMinutes('soon'), isNull);
      expect(Validators.parseEstimateMinutes('-2'), isNull);
    });
  });

  group('User', () {
    test('derives initials from one or two names', () {
      expect(
        const User(id: '1', name: 'Jordan Avery', email: 'j@k.app').initials,
        'JA',
      );
      expect(
        const User(id: '2', name: 'Priya', email: 'p@k.app').initials,
        'PR',
      );
      expect(const User(id: '3', name: '', email: 'x@k.app').initials, '?');
    });

    test('firstName takes the leading token', () {
      expect(
        const User(id: '1', name: 'Tomás Ferreira', email: 't@k.app').firstName,
        'Tomás',
      );
    });
  });
}
