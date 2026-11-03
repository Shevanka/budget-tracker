import 'package:budget_tracker/core/utils/year_month_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('YearMonthUtils', () {
    test('parse correctly parses valid year-month strings', () {
      final (year, month) = YearMonthUtils.parse('2026-10');
      expect(year, 2026);
      expect(month, 10);
    });

    test('parse throws FormatException on invalid format or month', () {
      expect(() => YearMonthUtils.parse('2026'), throwsFormatException);
      expect(() => YearMonthUtils.parse('2026-13'), throwsFormatException);
      expect(() => YearMonthUtils.parse('2026-00'), throwsFormatException);
      expect(() => YearMonthUtils.parse('invalid'), throwsFormatException);
    });

    test('toYearMonth formats DateTime correctly', () {
      expect(
        YearMonthUtils.toYearMonth(DateTime(2026, 5, 20)),
        '2026-05',
      );
      expect(
        YearMonthUtils.toYearMonth(DateTime(2026, 11, 1)),
        '2026-11',
      );
    });

    test('currentYearMonth returns valid YYYY-MM format', () {
      final current = YearMonthUtils.currentYearMonth();
      expect(RegExp(r'^\d{4}-\d{2}$').hasMatch(current), isTrue);
    });

    test('getStartOfMonth returns start of month in UTC', () {
      final start = YearMonthUtils.getStartOfMonth('2026-10');
      expect(start, equals(DateTime.utc(2026, 10, 1, 0, 0, 0)));
      expect(start.isUtc, isTrue);
    });

    test('getEndOfMonth returns end of month in UTC', () {
      final end = YearMonthUtils.getEndOfMonth('2026-10');
      expect(end, equals(DateTime.utc(2026, 10, 31, 23, 59, 59, 999)));
      expect(end.isUtc, isTrue);

      final leapFebEnd = YearMonthUtils.getEndOfMonth('2024-02');
      expect(leapFebEnd, equals(DateTime.utc(2024, 2, 29, 23, 59, 59, 999)));
    });

    test('previousYearMonth transitions months and years correctly', () {
      expect(YearMonthUtils.previousYearMonth('2026-10'), '2026-09');
      expect(YearMonthUtils.previousYearMonth('2026-01'), '2025-12');
    });

    test('nextYearMonth transitions months and years correctly', () {
      expect(YearMonthUtils.nextYearMonth('2026-10'), '2026-11');
      expect(YearMonthUtils.nextYearMonth('2026-12'), '2027-01');
    });

    test('formatDisplay formats human-readable string', () {
      expect(YearMonthUtils.formatDisplay('2026-10'), 'October 2026');
      expect(YearMonthUtils.formatDisplay('invalid'), 'invalid');
    });
  });
}
