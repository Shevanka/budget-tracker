import 'package:budget_tracker/features/dashboard/domain/models/financial_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MonthlyFinancialSummary', () {
    test('calculate returns correct netBalance and properties', () {
      final summary = MonthlyFinancialSummary.calculate(
        yearMonth: '2026-10',
        totalIncome: 5000000,
        totalExpense: 3200000,
        transactionCount: 8,
      );

      expect(summary.yearMonth, '2026-10');
      expect(summary.totalIncome, 5000000);
      expect(summary.totalExpense, 3200000);
      expect(summary.netBalance, 1800000);
      expect(summary.transactionCount, 8);
      expect(summary.isPositiveOrZero, isTrue);
      expect(summary.hasActivity, isTrue);
    });

    test('calculate detects deficit correctly when expense exceeds income', () {
      final summary = MonthlyFinancialSummary.calculate(
        yearMonth: '2026-10',
        totalIncome: 2000000,
        totalExpense: 3500000,
      );

      expect(summary.netBalance, -1500000);
      expect(summary.isPositiveOrZero, isFalse);
      expect(summary.hasActivity, isTrue);
    });

    test('hasActivity is false when totals and count are zero', () {
      final summary = MonthlyFinancialSummary.calculate(
        yearMonth: '2026-10',
        totalIncome: 0,
        totalExpense: 0,
        transactionCount: 0,
      );

      expect(summary.netBalance, 0);
      expect(summary.isPositiveOrZero, isTrue);
      expect(summary.hasActivity, isFalse);
    });

    test('equality and hashCode work properly', () {
      final a = MonthlyFinancialSummary.calculate(
        yearMonth: '2026-10',
        totalIncome: 1000,
        totalExpense: 500,
      );
      final b = MonthlyFinancialSummary.calculate(
        yearMonth: '2026-10',
        totalIncome: 1000,
        totalExpense: 500,
      );
      final c = MonthlyFinancialSummary.calculate(
        yearMonth: '2026-10',
        totalIncome: 2000,
        totalExpense: 500,
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });
}
