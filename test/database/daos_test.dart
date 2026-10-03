import 'package:budget_tracker/database/app_database.dart';
import 'package:budget_tracker/database/tables/tables.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.inMemory();
  });

  tearDown(() async {
    await db.close();
  });

  group('CategoryDao', () {
    test('insert and retrieve active categories', () async {
      await db.categoryDao.insertCategory(
        CategoriesCompanion(
          id: const drift.Value('cat-1'),
          name: const drift.Value('Food'),
          icon: const drift.Value('restaurant'),
          color: const drift.Value(0xFF43A047),
          sortOrder: const drift.Value(1),
          createdAt: drift.Value(DateTime.utc(2026, 10, 1)),
        ),
      );

      await db.categoryDao.insertCategory(
        CategoriesCompanion(
          id: const drift.Value('cat-2'),
          name: const drift.Value('Transport'),
          icon: const drift.Value('directions_car'),
          color: const drift.Value(0xFF1E88E5),
          sortOrder: const drift.Value(2),
          createdAt: drift.Value(DateTime.utc(2026, 10, 1)),
        ),
      );

      final active = await db.categoryDao.getActiveCategories();
      expect(active.length, 2);
      expect(active.first.name, 'Food');
      expect(active.last.name, 'Transport');
    });

    test('soft delete category marks isActive as false', () async {
      await db.categoryDao.insertCategory(
        CategoriesCompanion(
          id: const drift.Value('cat-1'),
          name: const drift.Value('Bills'),
          icon: const drift.Value('receipt'),
          color: const drift.Value(0xFFE53935),
          createdAt: drift.Value(DateTime.utc(2026, 10, 1)),
        ),
      );

      expect(await db.categoryDao.countActiveCategories(), 1);

      await db.categoryDao.softDeleteCategory('cat-1');

      final active = await db.categoryDao.getActiveCategories();
      expect(active, isEmpty);

      final all = await db.categoryDao.getAllCategories();
      expect(all.length, 1);
      expect(all.first.isActive, isFalse);
    });

    test('seedCategories inserts multiple categories', () async {
      final entries = [
        CategoriesCompanion(
          id: const drift.Value('cat-1'),
          name: const drift.Value('Food'),
          icon: const drift.Value('restaurant'),
          color: const drift.Value(0xFF43A047),
          createdAt: drift.Value(DateTime.utc(2026, 10, 1)),
        ),
        CategoriesCompanion(
          id: const drift.Value('cat-2'),
          name: const drift.Value('Shopping'),
          icon: const drift.Value('shopping_cart'),
          color: const drift.Value(0xFFFB8C00),
          createdAt: drift.Value(DateTime.utc(2026, 10, 1)),
        ),
      ];

      await db.categoryDao.seedCategories(entries);
      expect(await db.categoryDao.countActiveCategories(), 2);
    });
  });

  group('TransactionDao', () {
    setUp(() async {
      // Seed a category for foreign key references
      await db.categoryDao.insertCategory(
        CategoriesCompanion(
          id: const drift.Value('cat-food'),
          name: const drift.Value('Food'),
          icon: const drift.Value('restaurant'),
          color: const drift.Value(0xFF43A047),
          createdAt: drift.Value(DateTime.utc(2026, 10, 1)),
        ),
      );
      await db.categoryDao.insertCategory(
        CategoriesCompanion(
          id: const drift.Value('cat-transport'),
          name: const drift.Value('Transport'),
          icon: const drift.Value('directions_car'),
          color: const drift.Value(0xFF1E88E5),
          createdAt: drift.Value(DateTime.utc(2026, 10, 1)),
        ),
      );
    });

    test('insert, get, and delete transaction', () async {
      final entry = TransactionsCompanion(
        id: const drift.Value('tx-1'),
        amount: const drift.Value(50000), // Rp 50.000
        type: const drift.Value(TransactionType.expense),
        categoryId: const drift.Value('cat-food'),
        source: const drift.Value('Cash'),
        date: drift.Value(DateTime.utc(2026, 10, 3, 12, 0)),
        createdAt: drift.Value(DateTime.utc(2026, 10, 3, 12, 0)),
      );

      await db.transactionDao.insertTransaction(entry);

      final retrieved = await db.transactionDao.getTransactionById('tx-1');
      expect(retrieved, isNotNull);
      expect(retrieved!.amount, 50000);
      expect(retrieved.type, TransactionType.expense);

      await db.transactionDao.deleteTransaction('tx-1');
      expect(await db.transactionDao.getTransactionById('tx-1'), isNull);
    });

    test('date range query and aggregations (sum expense and income)', () async {
      final start = DateTime.utc(2026, 10, 1);
      final end = DateTime.utc(2026, 10, 31, 23, 59, 59);

      // Expense 1: Food 50,000
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('tx-1'),
          amount: const drift.Value(50000),
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value('cat-food'),
          source: const drift.Value('GoPay'),
          date: drift.Value(DateTime.utc(2026, 10, 5)),
          createdAt: drift.Value(DateTime.utc(2026, 10, 5)),
        ),
      );

      // Expense 2: Food 75,000
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('tx-2'),
          amount: const drift.Value(75000),
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value('cat-food'),
          source: const drift.Value('BCA'),
          date: drift.Value(DateTime.utc(2026, 10, 10)),
          createdAt: drift.Value(DateTime.utc(2026, 10, 10)),
        ),
      );

      // Expense 3: Transport 25,000
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('tx-3'),
          amount: const drift.Value(25000),
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value('cat-transport'),
          source: const drift.Value('OVO'),
          date: drift.Value(DateTime.utc(2026, 10, 15)),
          createdAt: drift.Value(DateTime.utc(2026, 10, 15)),
        ),
      );

      // Income 1: Salary 5,000,000
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('tx-4'),
          amount: const drift.Value(5000000),
          type: const drift.Value(TransactionType.income),
          categoryId: const drift.Value('cat-food'),
          source: const drift.Value('Mandiri'),
          date: drift.Value(DateTime.utc(2026, 10, 1)),
          createdAt: drift.Value(DateTime.utc(2026, 10, 1)),
        ),
      );

      // Outside range expense: 100,000
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('tx-old'),
          amount: const drift.Value(100000),
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value('cat-food'),
          source: const drift.Value('Cash'),
          date: drift.Value(DateTime.utc(2026, 9, 20)),
          createdAt: drift.Value(DateTime.utc(2026, 9, 20)),
        ),
      );

      final inRange = await db.transactionDao.getTransactionsByDateRange(start, end);
      expect(inRange.length, 4);

      final totalSpent = await db.transactionDao.getTotalSpent(start, end);
      expect(totalSpent, 150000); // 50000 + 75000 + 25000

      final totalIncome = await db.transactionDao.getTotalIncome(start, end);
      expect(totalIncome, 5000000);

      final foodSpent = await db.transactionDao.getTotalSpentForCategory('cat-food', start, end);
      expect(foodSpent, 125000); // 50000 + 75000

      final transportSpent = await db.transactionDao.getTotalSpentForCategory('cat-transport', start, end);
      expect(transportSpent, 25000);
    });

    test('watchRecentTransactions returns up to limit in descending order', () async {
      for (int i = 1; i <= 7; i++) {
        await db.transactionDao.insertTransaction(
          TransactionsCompanion(
            id: drift.Value('tx-$i'),
            amount: drift.Value(i * 10000),
            type: const drift.Value(TransactionType.expense),
            categoryId: const drift.Value('cat-food'),
            source: const drift.Value('Cash'),
            date: drift.Value(DateTime.utc(2026, 10, i)),
            createdAt: drift.Value(DateTime.utc(2026, 10, i)),
          ),
        );
      }

      final recent = await db.transactionDao.watchRecentTransactions(limit: 5).first;
      expect(recent.length, 5);
      expect(recent.first.id, 'tx-7');
      expect(recent.last.id, 'tx-3');
    });

    test('rejects non-positive amount (amount <= 0) via CHECK constraint', () async {
      expect(
        () => db.transactionDao.insertTransaction(
          TransactionsCompanion(
            id: const drift.Value('tx-zero'),
            amount: const drift.Value(0),
            type: const drift.Value(TransactionType.expense),
            categoryId: const drift.Value('cat-food'),
            source: const drift.Value('Cash'),
            date: drift.Value(DateTime.utc(2026, 10, 1)),
            createdAt: drift.Value(DateTime.utc(2026, 10, 1)),
          ),
        ),
        throwsA(isA<Exception>()),
      );

      expect(
        () => db.transactionDao.insertTransaction(
          TransactionsCompanion(
            id: const drift.Value('tx-neg'),
            amount: const drift.Value(-50000),
            type: const drift.Value(TransactionType.expense),
            categoryId: const drift.Value('cat-food'),
            source: const drift.Value('Cash'),
            date: drift.Value(DateTime.utc(2026, 10, 1)),
            createdAt: drift.Value(DateTime.utc(2026, 10, 1)),
          ),
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('enforces UTC normalization at DAO boundary for insert and queries', () async {
      final localDate = DateTime(2026, 10, 15, 18, 30);
      expect(localDate.isUtc, isFalse);

      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('tx-local-tz'),
          amount: const drift.Value(75000),
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value('cat-food'),
          source: const drift.Value('BCA'),
          date: drift.Value(localDate),
          createdAt: drift.Value(localDate),
        ),
      );

      final fetched = await db.transactionDao.getTransactionById('tx-local-tz');
      expect(fetched, isNotNull);
      expect(fetched!.date.isUtc, isTrue);
      expect(fetched.date, equals(localDate.toUtc()));
      expect(fetched.createdAt.isUtc, isTrue);

      final localStart = DateTime(2026, 10, 15, 0, 0);
      final localEnd = DateTime(2026, 10, 15, 23, 59, 59);
      final results = await db.transactionDao.getTransactionsByDateRange(localStart, localEnd);
      expect(results.any((tx) => tx.id == 'tx-local-tz'), isTrue);
    });
  });

  group('BudgetDao', () {
    setUp(() async {
      await db.categoryDao.insertCategory(
        CategoriesCompanion(
          id: const drift.Value('cat-food'),
          name: const drift.Value('Food'),
          icon: const drift.Value('restaurant'),
          color: const drift.Value(0xFF43A047),
          createdAt: drift.Value(DateTime.utc(2026, 10, 1)),
        ),
      );
      await db.categoryDao.insertCategory(
        CategoriesCompanion(
          id: const drift.Value('cat-bills'),
          name: const drift.Value('Bills'),
          icon: const drift.Value('receipt'),
          color: const drift.Value(0xFFE53935),
          createdAt: drift.Value(DateTime.utc(2026, 10, 1)),
        ),
      );
    });

    test('insert and fetch budget with category limits', () async {
      final budget = BudgetsCompanion(
        id: const drift.Value('b-2026-10'),
        yearMonth: const drift.Value('2026-10'),
        totalLimit: const drift.Value(3000000),
        createdAt: drift.Value(DateTime.utc(2026, 10, 1)),
      );

      const categories = [
        BudgetCategoriesCompanion(
          id: drift.Value('bc-1'),
          budgetId: drift.Value('b-2026-10'),
          categoryId: drift.Value('cat-food'),
          limitAmount: drift.Value(1500000),
        ),
        BudgetCategoriesCompanion(
          id: drift.Value('bc-2'),
          budgetId: drift.Value('b-2026-10'),
          categoryId: drift.Value('cat-bills'),
          limitAmount: drift.Value(1000000),
        ),
      ];

      await db.budgetDao.insertBudgetWithCategories(budget, categories);

      final fetched = await db.budgetDao.getBudgetForMonth('2026-10');
      expect(fetched, isNotNull);
      expect(fetched!.totalLimit, 3000000);

      final limits = await db.budgetDao.getBudgetCategories('b-2026-10');
      expect(limits.length, 2);
    });

    test('monthly rollover copy copies budget and category limits', () async {
      final budget = BudgetsCompanion(
        id: const drift.Value('b-2026-10'),
        yearMonth: const drift.Value('2026-10'),
        totalLimit: const drift.Value(2500000),
        createdAt: drift.Value(DateTime.utc(2026, 10, 1)),
      );

      const categories = [
        BudgetCategoriesCompanion(
          id: drift.Value('bc-10-1'),
          budgetId: drift.Value('b-2026-10'),
          categoryId: drift.Value('cat-food'),
          limitAmount: drift.Value(1500000),
        ),
      ];

      await db.budgetDao.insertBudgetWithCategories(budget, categories);

      int counter = 0;
      final copied = await db.budgetDao.copyBudget(
        fromYearMonth: '2026-10',
        toYearMonth: '2026-11',
        newBudgetId: 'b-2026-11',
        newCategoryLimitId: () => 'bc-11-${++counter}',
        createdAt: DateTime.utc(2026, 11, 1),
      );

      expect(copied, isTrue);

      final nextMonthBudget = await db.budgetDao.getBudgetForMonth('2026-11');
      expect(nextMonthBudget, isNotNull);
      expect(nextMonthBudget!.totalLimit, 2500000);

      final nextMonthLimits = await db.budgetDao.getBudgetCategories('b-2026-11');
      expect(nextMonthLimits.length, 1);
      expect(nextMonthLimits.first.categoryId, 'cat-food');
      expect(nextMonthLimits.first.limitAmount, 1500000);
    });

    test('unique yearMonth rejects duplicate budget insertion', () async {
      await db.budgetDao.insertBudgetWithCategories(
        BudgetsCompanion(
          id: const drift.Value('b-1'),
          yearMonth: const drift.Value('2026-10'),
          totalLimit: const drift.Value(1000000),
          createdAt: drift.Value(DateTime.utc(2026, 10, 1)),
        ),
        [],
      );

      expect(
        () => db.budgetDao.insertBudgetWithCategories(
          BudgetsCompanion(
            id: const drift.Value('b-2'),
            yearMonth: const drift.Value('2026-10'), // Duplicate yearMonth
            totalLimit: const drift.Value(2000000),
            createdAt: drift.Value(DateTime.utc(2026, 10, 1)),
          ),
          [],
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('rejects negative totalLimit via CHECK constraint', () async {
      expect(
        () => db.budgetDao.insertBudgetWithCategories(
          BudgetsCompanion(
            id: const drift.Value('b-neg'),
            yearMonth: const drift.Value('2026-12'),
            totalLimit: const drift.Value(-100000),
            createdAt: drift.Value(DateTime.utc(2026, 10, 1)),
          ),
          [],
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('rejects negative category limitAmount via CHECK constraint', () async {
      expect(
        () => db.budgetDao.insertBudgetWithCategories(
          BudgetsCompanion(
            id: const drift.Value('b-valid'),
            yearMonth: const drift.Value('2026-12'),
            totalLimit: const drift.Value(500000),
            createdAt: drift.Value(DateTime.utc(2026, 10, 1)),
          ),
          [
            const BudgetCategoriesCompanion(
              id: drift.Value('bc-neg'),
              budgetId: drift.Value('b-valid'),
              categoryId: drift.Value('cat-food'),
              limitAmount: drift.Value(-50000),
            ),
          ],
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('NotificationLogDao', () {
    test('insert unparsed log and mark as parsed', () async {
      await db.categoryDao.insertCategory(
        CategoriesCompanion(
          id: const drift.Value('cat-food'),
          name: const drift.Value('Food'),
          icon: const drift.Value('restaurant'),
          color: const drift.Value(0xFF43A047),
          createdAt: drift.Value(DateTime.utc(2026, 10, 1)),
        ),
      );

      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('tx-confirmed-1'),
          amount: const drift.Value(45000),
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value('cat-food'),
          source: const drift.Value('BCA'),
          date: drift.Value(DateTime.utc(2026, 10, 3, 14, 30)),
          createdAt: drift.Value(DateTime.utc(2026, 10, 3, 14, 30)),
        ),
      );

      final log = NotificationLogsCompanion(
        id: const drift.Value('log-1'),
        appPackage: const drift.Value('com.bca'),
        title: const drift.Value('m-BCA: Transfer Berhasil'),
        body: const drift.Value('Pembelian di RESTO SEDAP Rp 45.000'),
        receivedAt: drift.Value(DateTime.utc(2026, 10, 3, 14, 30)),
      );

      await db.notificationLogDao.insertLog(log);

      final unparsed = await db.notificationLogDao.getUnparsedLogs();
      expect(unparsed.length, 1);
      expect(unparsed.first.parsed, isFalse);
      expect(unparsed.first.body, contains('RESTO SEDAP'));

      await db.notificationLogDao.markAsParsed('log-1', 'tx-confirmed-1');

      final remaining = await db.notificationLogDao.getUnparsedLogs();
      expect(remaining, isEmpty);

      final updated = await db.notificationLogDao.getLogById('log-1');
      expect(updated!.parsed, isTrue);
      expect(updated.transactionId, 'tx-confirmed-1');
    });

    test('foreign key constraint prevents linking non-existent transaction', () async {
      final log = NotificationLogsCompanion(
        id: const drift.Value('log-invalid'),
        appPackage: const drift.Value('com.bca'),
        receivedAt: drift.Value(DateTime.utc(2026, 10, 3)),
      );
      await db.notificationLogDao.insertLog(log);

      expect(
        () => db.notificationLogDao.markAsParsed('log-invalid', 'non-existent-tx'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
