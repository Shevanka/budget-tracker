import 'package:budget_tracker/core/utils/year_month_utils.dart';
import 'package:budget_tracker/features/reports/domain/models/date_range_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DateRangeFilter Model Tests', () {
    test('forMonth creates start and end UTC timestamps with label', () {
      final filter = DateRangeFilter.forMonth('2026-10');

      expect(filter.type, DateRangeType.month);
      expect(filter.yearMonth, '2026-10');
      expect(filter.startDate, DateTime.utc(2026, 10, 1, 0, 0, 0));
      expect(filter.endDate, DateTime.utc(2026, 10, 31, 23, 59, 59, 999));
      expect(filter.label, YearMonthUtils.formatDisplay('2026-10'));
    });

    test('currentMonth initializes with currentYearMonth', () {
      final filter = DateRangeFilter.currentMonth();

      expect(filter.type, DateRangeType.month);
      expect(filter.yearMonth, YearMonthUtils.currentYearMonth());
    });

    test('currentWeek initializes with week type and Monday to Sunday span', () {
      final filter = DateRangeFilter.currentWeek();

      expect(filter.type, DateRangeType.week);
      expect(filter.label, 'This Week');
      expect(filter.startDate.weekday, DateTime.monday);
      expect(filter.endDate.weekday, DateTime.sunday);
      expect(filter.endDate.isAfter(filter.startDate), isTrue);
    });

    test('custom initializes with custom type and given dates', () {
      final start = DateTime(2026, 5, 10);
      final end = DateTime(2026, 5, 20);
      final filter = DateRangeFilter.custom(
        start: start,
        end: end,
        label: 'Vacation',
      );

      expect(filter.type, DateRangeType.custom);
      expect(filter.startDate, DateTime.utc(2026, 5, 10));
      expect(filter.endDate, DateTime.utc(2026, 5, 20, 23, 59, 59, 999));
      expect(filter.label, 'Vacation');
    });

    test('copyWith updates specified fields', () {
      final filter = DateRangeFilter.forMonth('2026-10');
      final updated = filter.copyWith(label: 'Custom October');

      expect(updated.label, 'Custom October');
      expect(updated.yearMonth, '2026-10');
      expect(updated.type, DateRangeType.month);
    });

    test('equality and hashCode work properly', () {
      final filter1 = DateRangeFilter.forMonth('2026-10');
      final filter2 = DateRangeFilter.forMonth('2026-10');
      final filter3 = DateRangeFilter.forMonth('2026-11');

      expect(filter1, equals(filter2));
      expect(filter1.hashCode, equals(filter2.hashCode));
      expect(filter1, isNot(equals(filter3)));
    });
  });
}
