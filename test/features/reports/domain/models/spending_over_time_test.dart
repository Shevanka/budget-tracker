import 'package:budget_tracker/features/reports/domain/models/spending_over_time.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DailySpending Model Tests', () {
    test('instantiates and formats properties correctly', () {
      final date = DateTime.utc(2026, 10, 15);
      final daily = DailySpending(
        date: date,
        amount: 250000,
        transactionCount: 3,
      );

      expect(daily.amount, 250000);
      expect(daily.transactionCount, 3);
      expect(daily.dayOfMonth, '15');
      expect(daily.formattedDate, '15 Oct');
      expect(daily.toString(), contains('15 Oct'));
      expect(daily.toString(), contains('250000'));
    });

    test('equality and hashCode work properly', () {
      final d1 = DailySpending(date: DateTime.utc(2026, 10, 15), amount: 100);
      final d2 = DailySpending(date: DateTime.utc(2026, 10, 15), amount: 100);
      final d3 = DailySpending(date: DateTime.utc(2026, 10, 16), amount: 100);

      expect(d1, equals(d2));
      expect(d1.hashCode, equals(d2.hashCode));
      expect(d1, isNot(equals(d3)));
    });
  });

  group('SpendingOverTimeReport Model Tests', () {
    test('computes isEmpty, hasData, highestSpendingDay, max, and average', () {
      final start = DateTime.utc(2026, 10, 1);
      final end = DateTime.utc(2026, 10, 3);

      final emptyReport = SpendingOverTimeReport(
        items: [
          DailySpending(date: DateTime.utc(2026, 10, 1), amount: 0),
          DailySpending(date: DateTime.utc(2026, 10, 2), amount: 0),
          DailySpending(date: DateTime.utc(2026, 10, 3), amount: 0),
        ],
        totalExpense: 0,
        startDate: start,
        endDate: end,
      );

      expect(emptyReport.isEmpty, isTrue);
      expect(emptyReport.hasData, isFalse);
      expect(emptyReport.highestSpendingDay, isNull);
      expect(emptyReport.maxDailyExpense, 0);
      expect(emptyReport.averageDailyExpense, 0);

      final day1 = DailySpending(date: DateTime.utc(2026, 10, 1), amount: 100000);
      final day2 = DailySpending(date: DateTime.utc(2026, 10, 2), amount: 300000);
      final day3 = DailySpending(date: DateTime.utc(2026, 10, 3), amount: 50000);

      final populatedReport = SpendingOverTimeReport(
        items: [day1, day2, day3],
        totalExpense: 450000,
        startDate: start,
        endDate: end,
      );

      expect(populatedReport.isEmpty, isFalse);
      expect(populatedReport.hasData, isTrue);
      expect(populatedReport.highestSpendingDay, equals(day2));
      expect(populatedReport.maxDailyExpense, 300000);
      expect(populatedReport.averageDailyExpense, 150000);
    });

    test('equality and hashCode work properly', () {
      final start = DateTime.utc(2026, 10, 1);
      final end = DateTime.utc(2026, 10, 2);
      final day = DailySpending(date: start, amount: 50000);

      final r1 = SpendingOverTimeReport(
        items: [day],
        totalExpense: 50000,
        startDate: start,
        endDate: end,
      );

      final r2 = SpendingOverTimeReport(
        items: [day],
        totalExpense: 50000,
        startDate: start,
        endDate: end,
      );

      expect(r1, equals(r2));
      expect(r1.hashCode, equals(r2.hashCode));
    });
  });
}
