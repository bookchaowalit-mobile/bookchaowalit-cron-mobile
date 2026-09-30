import 'package:cron/logic/cron_expression.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CronExpression.parse', () {
    test('expands wildcards, ranges, lists and steps', () {
      final cron = CronExpression.parse('*/20 9-11 1,15 * MON-FRI');
      expect(cron.minutes, {0, 20, 40});
      expect(cron.hours, {9, 10, 11});
      expect(cron.daysOfMonth, {1, 15});
      expect(cron.months.length, 12);
      expect(cron.daysOfWeek, {1, 2, 3, 4, 5});
    });

    test('accepts names, macros and Sunday as 7', () {
      expect(CronExpression.parse('0 12 * JAN,dec SUN').months, {1, 12});
      expect(CronExpression.parse('0 0 * * 7').daysOfWeek, {0});
      expect(CronExpression.parse('@daily').describe(), 'At 00:00');
    });

    test('rejects invalid expressions with a readable message', () {
      expect(
        () => CronExpression.parse('60 * * * *'),
        throwsA(
          isA<CronFormatException>().having(
            (e) => e.message,
            'message',
            contains('between 0 and 59'),
          ),
        ),
      );
      expect(
        () => CronExpression.parse('* * *'),
        throwsA(isA<CronFormatException>()),
      );
      expect(
        () => CronExpression.parse('*/0 * * * *'),
        throwsA(isA<CronFormatException>()),
      );
      expect(
        () => CronExpression.parse('0 5-2 * * *'),
        throwsA(isA<CronFormatException>()),
      );
      expect(
          () => CronExpression.parse(''), throwsA(isA<CronFormatException>()));
    });
  });

  group('nextRuns', () {
    test('steps through quarter hours', () {
      final runs = CronExpression.parse(
        '*/15 * * * *',
      ).nextRuns(DateTime(2026, 10, 1, 10, 7, 30), count: 4);
      expect(runs, [
        DateTime(2026, 10, 1, 10, 15),
        DateTime(2026, 10, 1, 10, 30),
        DateTime(2026, 10, 1, 10, 45),
        DateTime(2026, 10, 1, 11, 0),
      ]);
    });

    test('skips weekends for weekday schedules', () {
      // 2026-10-03 is a Saturday.
      final runs = CronExpression.parse(
        '0 9 * * 1-5',
      ).nextRuns(DateTime(2026, 10, 3, 12), count: 2);
      expect(runs, [DateTime(2026, 10, 5, 9), DateTime(2026, 10, 6, 9)]);
    });

    test('is strictly after the start minute', () {
      final runs = CronExpression.parse(
        '0 9 * * *',
      ).nextRuns(DateTime(2026, 10, 1, 9, 0), count: 1);
      expect(runs.single, DateTime(2026, 10, 2, 9));
    });

    test('finds leap days and gives up on impossible dates', () {
      expect(
        CronExpression.parse(
          '0 0 29 2 *',
        ).nextRuns(DateTime(2026, 1, 1), count: 1).single,
        DateTime(2028, 2, 29),
      );
      expect(
          CronExpression.parse('0 0 30 2 *').nextRuns(DateTime(2026)), isEmpty);
    });

    test('day-of-month and day-of-week are OR-ed when both are set', () {
      final cron = CronExpression.parse('0 0 1 * MON');
      expect(cron.matches(DateTime(2026, 10, 1)), isTrue); // the 1st
      expect(cron.matches(DateTime(2026, 10, 5)), isTrue); // a Monday
      expect(cron.matches(DateTime(2026, 10, 6)), isFalse);
    });
  });

  group('describe', () {
    test('produces readable summaries', () {
      expect(CronExpression.parse('0 9 * * 1-5').describe(),
          'At 09:00, on Mon-Fri');
      expect(
          CronExpression.parse('*/15 * * * *').describe(), 'Every 15 minutes');
      expect(
        CronExpression.parse('0 */2 * * *').describe(),
        'At minute 0, every 2 hours',
      );
      expect(
        CronExpression.parse('30 2 1 JAN,JUL *').describe(),
        'At 02:30, on day 1 of the month, in Jan, Jul',
      );
    });
  });

  test('compressRanges groups runs of three or more', () {
    expect(compressRanges([1, 2, 3, 5, 7, 8]), '1-3, 5, 7, 8');
  });
}
