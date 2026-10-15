import 'package:budget_tracker/database/app_database.dart';
import 'package:budget_tracker/database/converters/transaction_type.dart';
import 'package:budget_tracker/database/database_provider.dart';
import 'package:budget_tracker/features/budget/providers/budget_provider.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() async {
    db = AppDatabase.inMemory();
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
      ],
    );

    // Seed test categories
    await db.categoryDao.insertCategory(
      CategoriesCompanion(
        id: const drift.Value('cat-food'),
        name: const drift.Value('Food & Dining'),
        icon: const drift.Value('restaurant'),
        color: const drift.Value(0xFF43A047),
        type: const drift.Value(TransactionType.expense),
        createdAt: drift.Value(DateTime.utc(2026, 10, 1)),
      ),
    );
    await db.categoryDao.insertCategory(
      CategoriesCompanion(
        id: const drift.Value('cat-transport'),
        name: const drift.Value('Transport'),
        icon: const drift.Value('directions_car'),
        color: const drift.Value(0xFF1E88E5),
        type: const drift.Value(TransactionType.expense),
        createdAt: drift.Value(DateTime.utc(2026, 10, 1)),
      ),
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  group('BudgetController', () {
    test('saveBudget creates new budget and inserts category limits', () async {
      final controller = container.read(budgetControllerProvider.notifier);

      final budget = await controller.saveBudget(
        yearMonth: '2026-10',
        totalLimit: 5000000,
        categoryLimits: {
          'cat-food': 2000000,
          'cat-transport': 1000000,
        },
      );

      expect(budget.id, isNotEmpty);
      expect(budget.yearMonth, '2026-10');
      expect(budget.totalLimit, 5000000);

      final storedBudget = await db.budgetDao.getBudgetForMonth('2026-10');
      expect(storedBudget, isNotNull);
      expect(storedBudget!.totalLimit, 5000000);

      final categoryLimits = await db.budgetDao.getBudgetCategories(budget.id);
      expect(categoryLimits.length, 2);
      expect(
        categoryLimits.map((c) => c.limitAmount).toSet(),
        {2000000, 1000000},
      );
    });

    test('saveBudget updates existing budget and replaces category limits', () async {
      final controller = container.read(budgetControllerProvider.notifier);

      final initial = await controller.saveBudget(
        yearMonth: '2026-10',
        totalLimit: 4000000,
        categoryLimits: {
          'cat-food': 1500000,
        },
      );

      final updated = await controller.saveBudget(
        yearMonth: '2026-10',
        totalLimit: 6000000,
        categoryLimits: {
          'cat-food': 2500000,
          'cat-transport': 1500000,
        },
      );

      expect(updated.id, initial.id); // Same budget ID preserved
      expect(updated.totalLimit, 6000000);

      final categoryLimits = await db.budgetDao.getBudgetCategories(updated.id);
      expect(categoryLimits.length, 2);
      expect(
        categoryLimits.map((c) => c.limitAmount).toSet(),
        {2500000, 1500000},
      );
    });

    test('deleteBudget deletes budget and all its category limits', () async {
      final controller = container.read(budgetControllerProvider.notifier);

      final budget = await controller.saveBudget(
        yearMonth: '2026-10',
        totalLimit: 3000000,
        categoryLimits: {
          'cat-food': 1000000,
        },
      );

      await controller.deleteBudget(budget.id);

      final fetched = await db.budgetDao.getBudgetForMonth('2026-10');
      expect(fetched, isNull);

      final categoryLimits = await db.budgetDao.getBudgetCategories(budget.id);
      expect(categoryLimits, isEmpty);
    });

    test('copyBudget rolls over budget from previous month', () async {
      final controller = container.read(budgetControllerProvider.notifier);

      await controller.saveBudget(
        yearMonth: '2026-10',
        totalLimit: 4500000,
        categoryLimits: {
          'cat-food': 2000000,
        },
      );

      final success = await controller.copyBudget(
        fromYearMonth: '2026-10',
        toYearMonth: '2026-11',
      );

      expect(success, isTrue);

      final nextMonthBudget = await db.budgetDao.getBudgetForMonth('2026-11');
      expect(nextMonthBudget, isNotNull);
      expect(nextMonthBudget!.totalLimit, 4500000);

      final nextMonthLimits =
          await db.budgetDao.getBudgetCategories(nextMonthBudget.id);
      expect(nextMonthLimits.length, 1);
      expect(nextMonthLimits.first.limitAmount, 2000000);
    });
  });

  group('monthlyBudgetPlanProvider', () {
    test('emits null when no budget exists for month', () async {
      final plan = await container.read(monthlyBudgetPlanProvider('2026-10').future);
      expect(plan, isNull);
    });

    test('emits aggregated MonthlyBudgetPlan when budget exists', () async {
      final controller = container.read(budgetControllerProvider.notifier);
      await controller.saveBudget(
        yearMonth: '2026-10',
        totalLimit: 5000000,
        categoryLimits: {
          'cat-food': 2000000,
          'cat-transport': 1000000,
        },
      );

      final plan = await container.read(monthlyBudgetPlanProvider('2026-10').future);
      expect(plan, isNotNull);
      expect(plan!.yearMonth, '2026-10');
      expect(plan.totalLimit, 5000000);
      expect(plan.totalAllocated, 3000000);
      expect(plan.unallocatedAmount, 2000000);
      expect(plan.isOverallocated, isFalse);
      expect(plan.categoryLimits.length, 2);
    });
  });
}
