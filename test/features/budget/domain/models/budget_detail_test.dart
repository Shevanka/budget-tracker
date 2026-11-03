import 'package:budget_tracker/database/app_database.dart';
import 'package:budget_tracker/database/converters/transaction_type.dart';
import 'package:budget_tracker/features/budget/domain/models/budget_detail.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final foodCategory = Category(
    id: 'cat-food',
    name: 'Food & Dining',
    icon: 'restaurant',
    color: 0xFF43A047,
    type: TransactionType.expense,
    isDefault: true,
    isActive: true,
    sortOrder: 0,
    createdAt: DateTime.utc(2026, 10, 1),
  );

  final transportCategory = Category(
    id: 'cat-transport',
    name: 'Transportation',
    icon: 'directions_car',
    color: 0xFF1E88E5,
    type: TransactionType.expense,
    isDefault: true,
    isActive: true,
    sortOrder: 1,
    createdAt: DateTime.utc(2026, 10, 1),
  );

  group('MonthlyBudgetPlan domain model', () {
    test('calculates allocations, unallocated amount, and ratio accurately', () {
      final plan = MonthlyBudgetPlan(
        yearMonth: '2026-10',
        totalLimit: 5000000,
        categoryLimits: [
          CategoryLimitItem(category: foodCategory, limitAmount: 2000000),
          CategoryLimitItem(category: transportCategory, limitAmount: 1000000),
        ],
      );

      expect(plan.totalAllocated, 3000000);
      expect(plan.unallocatedAmount, 2000000);
      expect(plan.isOverallocated, isFalse);
      expect(plan.allocationRatio, 0.6);
    });

    test('detects overallocated status when category limits exceed total', () {
      final plan = MonthlyBudgetPlan(
        yearMonth: '2026-10',
        totalLimit: 3000000,
        categoryLimits: [
          CategoryLimitItem(category: foodCategory, limitAmount: 2500000),
          CategoryLimitItem(category: transportCategory, limitAmount: 1000000),
        ],
      );

      expect(plan.totalAllocated, 3500000);
      expect(plan.unallocatedAmount, -500000);
      expect(plan.isOverallocated, isTrue);
      expect(plan.allocationRatio, closeTo(1.166, 0.01));
    });

    test('handles zero total budget gracefully', () {
      const plan = MonthlyBudgetPlan(
        yearMonth: '2026-10',
        totalLimit: 0,
        categoryLimits: [],
      );

      expect(plan.totalAllocated, 0);
      expect(plan.unallocatedAmount, 0);
      expect(plan.isOverallocated, isFalse);
      expect(plan.allocationRatio, 0.0);
    });
  });
}
