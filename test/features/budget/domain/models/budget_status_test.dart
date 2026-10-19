import 'package:budget_tracker/database/app_database.dart';
import 'package:budget_tracker/database/converters/transaction_type.dart';
import 'package:budget_tracker/features/budget/domain/models/budget_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final sampleCategory = Category(
    id: 'cat-food',
    name: 'Food & Dining',
    icon: 'restaurant',
    color: 0xFF43A047,
    type: TransactionType.expense,
    sortOrder: 1,
    isDefault: true,
    isActive: true,
    createdAt: DateTime.utc(2026, 1, 1),
  );

  group('CategoryBudgetStatus', () {
    test('calculate returns safe status when spending is below 80%', () {
      final status = CategoryBudgetStatus.calculate(
        category: sampleCategory,
        limit: 1000000,
        spent: 500000,
      );

      expect(status.limit, 1000000);
      expect(status.spent, 500000);
      expect(status.remaining, 500000);
      expect(status.percentage, 50);
      expect(status.ratio, 0.5);
      expect(status.statusLevel, BudgetStatusLevel.safe);
      expect(status.hasLimit, isTrue);
      expect(status.isExceeded, isFalse);
      expect(status.isNearLimit, isFalse);
    });

    test('calculate returns warning status when spending is between 80% and 99%', () {
      final status80 = CategoryBudgetStatus.calculate(
        category: sampleCategory,
        limit: 1000000,
        spent: 800000,
      );

      expect(status80.percentage, 80);
      expect(status80.statusLevel, BudgetStatusLevel.warning);
      expect(status80.isNearLimit, isTrue);
      expect(status80.isExceeded, isFalse);

      final status95 = CategoryBudgetStatus.calculate(
        category: sampleCategory,
        limit: 1000000,
        spent: 950000,
      );

      expect(status95.percentage, 95);
      expect(status95.statusLevel, BudgetStatusLevel.warning);
      expect(status95.isNearLimit, isTrue);
      expect(status95.isExceeded, isFalse);
    });

    test('calculate returns danger status when spending reaches or exceeds 100%', () {
      final status100 = CategoryBudgetStatus.calculate(
        category: sampleCategory,
        limit: 1000000,
        spent: 1000000,
      );

      expect(status100.remaining, 0);
      expect(status100.percentage, 100);
      expect(status100.statusLevel, BudgetStatusLevel.danger);
      expect(status100.isExceeded, isFalse); // spent is exactly limit, not > limit
      expect(status100.isNearLimit, isFalse);

      final statusExceeded = CategoryBudgetStatus.calculate(
        category: sampleCategory,
        limit: 1000000,
        spent: 1200000,
      );

      expect(statusExceeded.remaining, -200000);
      expect(statusExceeded.percentage, 120);
      expect(statusExceeded.statusLevel, BudgetStatusLevel.danger);
      expect(statusExceeded.isExceeded, isTrue);
      expect(statusExceeded.isNearLimit, isFalse);
    });

    test('calculate handles zero limit gracefully (unbudgeted category)', () {
      final status = CategoryBudgetStatus.calculate(
        category: sampleCategory,
        limit: 0,
        spent: 150000,
      );

      expect(status.limit, 0);
      expect(status.spent, 150000);
      expect(status.remaining, -150000);
      expect(status.percentage, 0);
      expect(status.ratio, 0.0);
      expect(status.statusLevel, BudgetStatusLevel.safe);
      expect(status.hasLimit, isFalse);
      expect(status.isExceeded, isFalse);
      expect(status.isNearLimit, isFalse);
    });

    test('calculate handles zero spent', () {
      final status = CategoryBudgetStatus.calculate(
        category: sampleCategory,
        limit: 500000,
        spent: 0,
      );

      expect(status.limit, 500000);
      expect(status.spent, 0);
      expect(status.remaining, 500000);
      expect(status.percentage, 0);
      expect(status.ratio, 0.0);
      expect(status.statusLevel, BudgetStatusLevel.safe);
    });
  });

  group('MonthlyBudgetStatus', () {
    test('calculate returns correct totals and safe level', () {
      final catStatus = CategoryBudgetStatus.calculate(
        category: sampleCategory,
        limit: 1000000,
        spent: 400000,
      );

      final monthly = MonthlyBudgetStatus.calculate(
        yearMonth: '2026-10',
        totalLimit: 5000000,
        totalSpent: 1500000,
        categoryStatuses: [catStatus],
        unbudgetedSpent: 100000,
      );

      expect(monthly.yearMonth, '2026-10');
      expect(monthly.totalLimit, 5000000);
      expect(monthly.totalSpent, 1500000);
      expect(monthly.totalRemaining, 3500000);
      expect(monthly.percentage, 30);
      expect(monthly.ratio, 0.3);
      expect(monthly.statusLevel, BudgetStatusLevel.safe);
      expect(monthly.hasBudget, isTrue);
      expect(monthly.isExceeded, isFalse);
      expect(monthly.isNearLimit, isFalse);
      expect(monthly.unbudgetedSpent, 100000);
      expect(monthly.categoryStatuses.length, 1);
    });

    test('calculate returns warning level when totalSpent is 80-99%', () {
      final monthly = MonthlyBudgetStatus.calculate(
        yearMonth: '2026-10',
        totalLimit: 1000000,
        totalSpent: 850000,
        categoryStatuses: [],
        unbudgetedSpent: 0,
      );

      expect(monthly.percentage, 85);
      expect(monthly.statusLevel, BudgetStatusLevel.warning);
      expect(monthly.isNearLimit, isTrue);
      expect(monthly.isExceeded, isFalse);
    });

    test('calculate returns danger level when totalSpent exceeds limit', () {
      final monthly = MonthlyBudgetStatus.calculate(
        yearMonth: '2026-10',
        totalLimit: 1000000,
        totalSpent: 1100000,
        categoryStatuses: [],
        unbudgetedSpent: 0,
      );

      expect(monthly.totalRemaining, -100000);
      expect(monthly.percentage, 110);
      expect(monthly.statusLevel, BudgetStatusLevel.danger);
      expect(monthly.isExceeded, isTrue);
      expect(monthly.isNearLimit, isFalse);
    });

    test('calculate handles zero totalLimit', () {
      final monthly = MonthlyBudgetStatus.calculate(
        yearMonth: '2026-10',
        totalLimit: 0,
        totalSpent: 500000,
        categoryStatuses: [],
        unbudgetedSpent: 500000,
      );

      expect(monthly.totalLimit, 0);
      expect(monthly.percentage, 0);
      expect(monthly.ratio, 0.0);
      expect(monthly.statusLevel, BudgetStatusLevel.safe);
      expect(monthly.hasBudget, isFalse);
      expect(monthly.isExceeded, isFalse);
    });
  });
}
