import 'package:budget_tracker/database/app_database.dart';
import 'package:budget_tracker/database/tables/tables.dart';
import 'package:budget_tracker/features/budget/domain/models/budget_status.dart';
import 'package:budget_tracker/features/budget/domain/services/budget_service.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late BudgetService budgetService;

  setUp(() {
    db = AppDatabase.inMemory();
    budgetService = BudgetService(
      budgetDao: db.budgetDao,
      transactionDao: db.transactionDao,
      categoryDao: db.categoryDao,
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedTestData() async {
    // Insert categories
    await db.categoryDao.insertCategory(
      CategoriesCompanion(
        id: const drift.Value('cat-food'),
        name: const drift.Value('Food & Dining'),
        icon: const drift.Value('restaurant'),
        color: const drift.Value(0xFF43A047),
        sortOrder: const drift.Value(1),
        createdAt: drift.Value(DateTime.utc(2026, 1, 1)),
      ),
    );

    await db.categoryDao.insertCategory(
      CategoriesCompanion(
        id: const drift.Value('cat-transport'),
        name: const drift.Value('Transportation'),
        icon: const drift.Value('directions_car'),
        color: const drift.Value(0xFF1E88E5),
        sortOrder: const drift.Value(2),
        createdAt: drift.Value(DateTime.utc(2026, 1, 1)),
      ),
    );

    await db.categoryDao.insertCategory(
      CategoriesCompanion(
        id: const drift.Value('cat-entertainment'),
        name: const drift.Value('Entertainment'),
        icon: const drift.Value('movie'),
        color: const drift.Value(0xFF9C27B0),
        sortOrder: const drift.Value(3),
        createdAt: drift.Value(DateTime.utc(2026, 1, 1)),
      ),
    );

    // Insert budget for 2026-10 (total: 3,000,000; food: 1,000,000; transport: 500,000)
    await db.budgetDao.insertBudgetWithCategories(
      BudgetsCompanion(
        id: const drift.Value('b-2026-10'),
        yearMonth: const drift.Value('2026-10'),
        totalLimit: const drift.Value(3000000),
        createdAt: drift.Value(DateTime.utc(2026, 10, 1)),
      ),
      [
        const BudgetCategoriesCompanion(
          id: drift.Value('bc-food'),
          budgetId: drift.Value('b-2026-10'),
          categoryId: drift.Value('cat-food'),
          limitAmount: drift.Value(1000000),
        ),
        const BudgetCategoriesCompanion(
          id: drift.Value('bc-transport'),
          budgetId: drift.Value('b-2026-10'),
          categoryId: drift.Value('cat-transport'),
          limitAmount: drift.Value(500000),
        ),
      ],
    );

    // Insert transactions for 2026-10:
    // Food: 500,000 + 350,000 = 850,000 (85% -> warning)
    await db.transactionDao.insertTransaction(
      TransactionsCompanion(
        id: const drift.Value('tx-1'),
        amount: const drift.Value(500000),
        type: const drift.Value(TransactionType.expense),
        categoryId: const drift.Value('cat-food'),
        source: const drift.Value('BCA'),
        date: drift.Value(DateTime.utc(2026, 10, 5, 12, 0)),
        createdAt: drift.Value(DateTime.utc(2026, 10, 5, 12, 0)),
      ),
    );
    await db.transactionDao.insertTransaction(
      TransactionsCompanion(
        id: const drift.Value('tx-2'),
        amount: const drift.Value(350000),
        type: const drift.Value(TransactionType.expense),
        categoryId: const drift.Value('cat-food'),
        source: const drift.Value('Cash'),
        date: drift.Value(DateTime.utc(2026, 10, 12, 18, 0)),
        createdAt: drift.Value(DateTime.utc(2026, 10, 12, 18, 0)),
      ),
    );

    // Transport: 150,000 (30% -> safe)
    await db.transactionDao.insertTransaction(
      TransactionsCompanion(
        id: const drift.Value('tx-3'),
        amount: const drift.Value(150000),
        type: const drift.Value(TransactionType.expense),
        categoryId: const drift.Value('cat-transport'),
        source: const drift.Value('GoPay'),
        date: drift.Value(DateTime.utc(2026, 10, 15, 9, 0)),
        createdAt: drift.Value(DateTime.utc(2026, 10, 15, 9, 0)),
      ),
    );

    // Entertainment (unbudgeted): 200,000
    await db.transactionDao.insertTransaction(
      TransactionsCompanion(
        id: const drift.Value('tx-4'),
        amount: const drift.Value(200000),
        type: const drift.Value(TransactionType.expense),
        categoryId: const drift.Value('cat-entertainment'),
        source: const drift.Value('OVO'),
        date: drift.Value(DateTime.utc(2026, 10, 20, 20, 0)),
        createdAt: drift.Value(DateTime.utc(2026, 10, 20, 20, 0)),
      ),
    );

    // Income (should not affect spent): 10,000,000
    await db.transactionDao.insertTransaction(
      TransactionsCompanion(
        id: const drift.Value('tx-inc'),
        amount: const drift.Value(10000000),
        type: const drift.Value(TransactionType.income),
        categoryId: const drift.Value('cat-food'),
        source: const drift.Value('Payroll'),
        date: drift.Value(DateTime.utc(2026, 10, 1, 8, 0)),
        createdAt: drift.Value(DateTime.utc(2026, 10, 1, 8, 0)),
      ),
    );

    // Outside month transaction: 2026-09
    await db.transactionDao.insertTransaction(
      TransactionsCompanion(
        id: const drift.Value('tx-sept'),
        amount: const drift.Value(900000),
        type: const drift.Value(TransactionType.expense),
        categoryId: const drift.Value('cat-food'),
        source: const drift.Value('BCA'),
        date: drift.Value(DateTime.utc(2026, 9, 30, 23, 0)),
        createdAt: drift.Value(DateTime.utc(2026, 9, 30, 23, 0)),
      ),
    );
  }

  group('BudgetService getCategoryBudgetStatus', () {
    test('returns null if category is not found', () async {
      final status = await budgetService.getCategoryBudgetStatus('2026-10', 'cat-unknown');
      expect(status, isNull);
    });

    test('calculates correct status for category with budget and expenses', () async {
      await seedTestData();

      final foodStatus = await budgetService.getCategoryBudgetStatus('2026-10', 'cat-food');
      expect(foodStatus, isNotNull);
      expect(foodStatus!.limit, 1000000);
      expect(foodStatus.spent, 850000);
      expect(foodStatus.remaining, 150000);
      expect(foodStatus.percentage, 85);
      expect(foodStatus.statusLevel, BudgetStatusLevel.warning);
      expect(foodStatus.isNearLimit, isTrue);
      expect(foodStatus.isExceeded, isFalse);

      final transportStatus =
          await budgetService.getCategoryBudgetStatus('2026-10', 'cat-transport');
      expect(transportStatus, isNotNull);
      expect(transportStatus!.limit, 500000);
      expect(transportStatus.spent, 150000);
      expect(transportStatus.remaining, 350000);
      expect(transportStatus.percentage, 30);
      expect(transportStatus.statusLevel, BudgetStatusLevel.safe);
      expect(transportStatus.isNearLimit, isFalse);
    });

    test('calculates unbudgeted category with limit=0', () async {
      await seedTestData();

      final entertainmentStatus =
          await budgetService.getCategoryBudgetStatus('2026-10', 'cat-entertainment');
      expect(entertainmentStatus, isNotNull);
      expect(entertainmentStatus!.limit, 0);
      expect(entertainmentStatus.spent, 200000);
      expect(entertainmentStatus.remaining, -200000);
      expect(entertainmentStatus.hasLimit, isFalse);
      expect(entertainmentStatus.statusLevel, BudgetStatusLevel.safe);
    });
  });

  group('BudgetService getMonthlyBudgetStatus', () {
    test('calculates complete monthly status with breakdown and unbudgeted total', () async {
      await seedTestData();

      final status = await budgetService.getMonthlyBudgetStatus('2026-10');

      expect(status.yearMonth, '2026-10');
      expect(status.totalLimit, 3000000);
      // Spent: 850,000 (food) + 150,000 (transport) + 200,000 (ent) = 1,200,000
      expect(status.totalSpent, 1200000);
      expect(status.totalRemaining, 1800000);
      expect(status.percentage, 40);
      expect(status.statusLevel, BudgetStatusLevel.safe);
      expect(status.hasBudget, isTrue);
      expect(status.unbudgetedSpent, 200000);

      // Verify categoryStatuses includes food, transport, and entertainment
      expect(status.categoryStatuses.length, 3);

      // Food has limit and is highest spent among budgeted -> index 0
      expect(status.categoryStatuses[0].category.id, 'cat-food');
      expect(status.categoryStatuses[0].spent, 850000);

      // Transport has limit -> index 1
      expect(status.categoryStatuses[1].category.id, 'cat-transport');
      expect(status.categoryStatuses[1].spent, 150000);

      // Entertainment has no limit -> sorted last
      expect(status.categoryStatuses[2].category.id, 'cat-entertainment');
      expect(status.categoryStatuses[2].spent, 200000);
      expect(status.categoryStatuses[2].hasLimit, isFalse);
    });

    test('handles month with no budget record created', () async {
      await seedTestData();

      final status = await budgetService.getMonthlyBudgetStatus('2026-09');

      expect(status.yearMonth, '2026-09');
      expect(status.totalLimit, 0);
      expect(status.totalSpent, 900000); // 900,000 from tx-sept
      expect(status.totalRemaining, -900000);
      expect(status.percentage, 0);
      expect(status.hasBudget, isFalse);
      expect(status.unbudgetedSpent, 900000);
      expect(status.statusLevel, BudgetStatusLevel.safe);
    });
  });

  group('BudgetService reactive streams', () {
    test('watchMonthlyBudgetStatus emits updates when transactions change', () async {
      await seedTestData();

      final stream = budgetService.watchMonthlyBudgetStatus('2026-10');
      final expectation = expectLater(
        stream,
        emitsInOrder([
          predicate<MonthlyBudgetStatus>((s) => s.totalSpent == 1200000),
          predicate<MonthlyBudgetStatus>((s) => s.totalSpent == 1700000),
        ]),
      );

      // Insert an additional transaction of 500,000
      await Future.delayed(const Duration(milliseconds: 50));
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('tx-new-live'),
          amount: const drift.Value(500000),
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value('cat-food'),
          source: const drift.Value('BCA'),
          date: drift.Value(DateTime.utc(2026, 10, 25, 10, 0)),
          createdAt: drift.Value(DateTime.utc(2026, 10, 25, 10, 0)),
        ),
      );

      await expectation;
    });

    test('watchCategoryBudgetStatus emits updates when category transactions change', () async {
      await seedTestData();

      final stream = budgetService.watchCategoryBudgetStatus('2026-10', 'cat-food');
      final expectation = expectLater(
        stream,
        emitsInOrder([
          predicate<CategoryBudgetStatus?>((s) => s != null && s.spent == 850000),
          predicate<CategoryBudgetStatus?>((s) => s != null && s.spent == 1150000 && s.isExceeded),
        ]),
      );

      // Insert another food expense of 300,000 which will exceed limit (850,000 + 300,000 = 1,150,000 > 1,000,000)
      await Future.delayed(const Duration(milliseconds: 50));
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('tx-food-exceed'),
          amount: const drift.Value(300000),
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value('cat-food'),
          source: const drift.Value('Cash'),
          date: drift.Value(DateTime.utc(2026, 10, 26, 14, 0)),
          createdAt: drift.Value(DateTime.utc(2026, 10, 26, 14, 0)),
        ),
      );

      await expectation;
    });
  });

  group('BudgetService monthly rollover', () {
    test('getPreviousAvailableBudget returns immediate previous month budget', () async {
      await seedTestData(); // has budget for 2026-10

      final prev = await budgetService.getPreviousAvailableBudget('2026-11');
      expect(prev, isNotNull);
      expect(prev!.yearMonth, '2026-10');
      expect(prev.totalLimit, 3000000);
    });

    test('getPreviousAvailableBudget falls back to latest preceding budget when month skipped',
        () async {
      await seedTestData(); // has budget for 2026-10

      // Request for 2026-12 (November has no budget, should fall back to October)
      final prevWithFallback =
          await budgetService.getPreviousAvailableBudget('2026-12', fallbackToLatest: true);
      expect(prevWithFallback, isNotNull);
      expect(prevWithFallback!.yearMonth, '2026-10');

      final prevWithoutFallback =
          await budgetService.getPreviousAvailableBudget('2026-12', fallbackToLatest: false);
      expect(prevWithoutFallback, isNull);
    });

    test('getPreviousAvailableBudget returns null if no earlier budgets exist', () async {
      await seedTestData(); // earliest budget is 2026-10

      final prev = await budgetService.getPreviousAvailableBudget('2026-09');
      expect(prev, isNull);
    });

    test('ensureMonthlyBudgetRollover returns existing budget if already present', () async {
      await seedTestData(); // has budget for 2026-10 with totalLimit 3,000,000

      final budget = await budgetService.ensureMonthlyBudgetRollover('2026-10');
      expect(budget, isNotNull);
      expect(budget!.id, 'b-2026-10');
      expect(budget.totalLimit, 3000000);
    });

    test('ensureMonthlyBudgetRollover copies budget and category limits to new month', () async {
      await seedTestData(); // has budget for 2026-10 with 2 categories: food (1M) and transport (500k)

      // Ensure budget for 2026-11 (currently has no budget)
      final initialCheck = await db.budgetDao.getBudgetForMonth('2026-11');
      expect(initialCheck, isNull);

      final rolledOver = await budgetService.ensureMonthlyBudgetRollover('2026-11');
      expect(rolledOver, isNotNull);
      expect(rolledOver!.yearMonth, '2026-11');
      expect(rolledOver.totalLimit, 3000000);

      // Verify category limits were copied with new IDs
      final limits = await db.budgetDao.getBudgetCategories(rolledOver.id);
      expect(limits.length, 2);

      final foodLimit = limits.firstWhere((c) => c.categoryId == 'cat-food');
      expect(foodLimit.limitAmount, 1000000);
      expect(foodLimit.id, isNot('bc-food')); // Fresh UUID

      final transportLimit = limits.firstWhere((c) => c.categoryId == 'cat-transport');
      expect(transportLimit.limitAmount, 500000);
      expect(transportLimit.id, isNot('bc-transport'));
    });

    test('ensureMonthlyBudgetRollover returns null when no previous budget exists', () async {
      // 2026-08 has no previous budget in seed data
      final result = await budgetService.ensureMonthlyBudgetRollover('2026-08');
      expect(result, isNull);
    });
  });
}

