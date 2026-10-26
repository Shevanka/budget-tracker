import 'package:budget_tracker/core/utils/year_month_utils.dart';
import 'package:budget_tracker/database/app_database.dart';
import 'package:budget_tracker/database/converters/transaction_type.dart';
import 'package:budget_tracker/database/database_provider.dart';
import 'package:budget_tracker/features/reports/domain/models/date_range_filter.dart';
import 'package:budget_tracker/features/reports/providers/reports_provider.dart';
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
        createdAt: drift.Value(DateTime.utc(2026, 1, 1)),
      ),
    );

    await db.categoryDao.insertCategory(
      CategoriesCompanion(
        id: const drift.Value('cat-transport'),
        name: const drift.Value('Transportation'),
        icon: const drift.Value('directions_bus'),
        color: const drift.Value(0xFF1E88E5),
        type: const drift.Value(TransactionType.expense),
        createdAt: drift.Value(DateTime.utc(2026, 1, 1)),
      ),
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  group('ReportsFilterNotifier Tests', () {
    test('initializes with current month and handles navigation', () {
      final notifier = container.read(reportsFilterProvider.notifier);
      expect(container.read(reportsFilterProvider).type, DateRangeType.month);
      expect(
        container.read(reportsFilterProvider).yearMonth,
        YearMonthUtils.currentYearMonth(),
      );

      notifier.setMonth('2026-05');
      expect(container.read(reportsFilterProvider).yearMonth, '2026-05');

      notifier.nextMonth();
      expect(container.read(reportsFilterProvider).yearMonth, '2026-06');

      notifier.previousMonth();
      expect(container.read(reportsFilterProvider).yearMonth, '2026-05');

      notifier.resetToCurrentMonth();
      expect(
        container.read(reportsFilterProvider).yearMonth,
        YearMonthUtils.currentYearMonth(),
      );

      notifier.setWeek();
      expect(container.read(reportsFilterProvider).type, DateRangeType.week);

      notifier.setCustom(DateTime(2026, 1, 1), DateTime(2026, 1, 10));
      expect(container.read(reportsFilterProvider).type, DateRangeType.custom);
    });
  });

  group('categorySpendingReportProvider Tests', () {
    test('emits empty report when no transactions exist in the period', () async {
      final filter = DateRangeFilter.forMonth('2026-10');
      final report = await container.read(categorySpendingReportProvider(filter).future);

      expect(report.isEmpty, isTrue);
      expect(report.items, isEmpty);
      expect(report.totalExpense, 0);
    });

    test('aggregates multiple category expenses and calculates percentages correctly',
        () async {
      final filter = DateRangeFilter.forMonth('2026-10');

      // Insert food expenses (total: 300,000)
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('tx-1'),
          amount: const drift.Value(200000),
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value('cat-food'),
          source: const drift.Value('Cash'),
          date: drift.Value(DateTime.utc(2026, 10, 5, 12, 0)),
          createdAt: drift.Value(DateTime.utc(2026, 10, 5, 12, 0)),
        ),
      );

      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('tx-2'),
          amount: const drift.Value(100000),
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value('cat-food'),
          source: const drift.Value('BCA'),
          date: drift.Value(DateTime.utc(2026, 10, 10, 12, 0)),
          createdAt: drift.Value(DateTime.utc(2026, 10, 10, 12, 0)),
        ),
      );

      // Insert transport expense (total: 100,000)
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('tx-3'),
          amount: const drift.Value(100000),
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value('cat-transport'),
          source: const drift.Value('GoPay'),
          date: drift.Value(DateTime.utc(2026, 10, 15, 8, 0)),
          createdAt: drift.Value(DateTime.utc(2026, 10, 15, 8, 0)),
        ),
      );

      // Insert income transaction (should be ignored for category spending)
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('tx-4'),
          amount: const drift.Value(5000000),
          type: const drift.Value(TransactionType.income),
          categoryId: const drift.Value('cat-food'),
          source: const drift.Value('Salary'),
          date: drift.Value(DateTime.utc(2026, 10, 1, 10, 0)),
          createdAt: drift.Value(DateTime.utc(2026, 10, 1, 10, 0)),
        ),
      );

      // Insert expense outside the date range (should be ignored)
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('tx-5'),
          amount: const drift.Value(900000),
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value('cat-food'),
          source: const drift.Value('Cash'),
          date: drift.Value(DateTime.utc(2026, 11, 2, 10, 0)),
          createdAt: drift.Value(DateTime.utc(2026, 11, 2, 10, 0)),
        ),
      );

      final report = await container.read(categorySpendingReportProvider(filter).future);

      expect(report.hasData, isTrue);
      expect(report.totalExpense, 400000);
      expect(report.items.length, 2);

      // Top category is Food & Dining with 300,000 (75%)
      final foodItem = report.items[0];
      expect(foodItem.category.name, 'Food & Dining');
      expect(foodItem.amount, 300000);
      expect(foodItem.percentage, 75.0);
      expect(foodItem.transactionCount, 2);

      // Second category is Transportation with 100,000 (25%)
      final transportItem = report.items[1];
      expect(transportItem.category.name, 'Transportation');
      expect(transportItem.amount, 100000);
      expect(transportItem.percentage, 25.0);
      expect(transportItem.transactionCount, 1);
    });

    test('handles soft-deleted/inactive categories in reports', () async {
      final filter = DateRangeFilter.forMonth('2026-10');

      await db.categoryDao.insertCategory(
        CategoriesCompanion(
          id: const drift.Value('cat-archived'),
          name: const drift.Value('Archived Hobby'),
          icon: const drift.Value('palette'),
          color: const drift.Value(0xFF8E24AA),
          type: const drift.Value(TransactionType.expense),
          isActive: const drift.Value(false),
          createdAt: drift.Value(DateTime.utc(2026, 1, 1)),
        ),
      );

      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('tx-archived'),
          amount: const drift.Value(50000),
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value('cat-archived'),
          source: const drift.Value('Cash'),
          date: drift.Value(DateTime.utc(2026, 10, 12, 10, 0)),
          createdAt: drift.Value(DateTime.utc(2026, 10, 12, 10, 0)),
        ),
      );

      final report = await container.read(categorySpendingReportProvider(filter).future);

      expect(report.items.length, 1);
      expect(report.items[0].category.name, 'Archived Hobby');
      expect(report.items[0].amount, 50000);
      expect(report.items[0].percentage, 100.0);
    });
  });

  group('spendingOverTimeProvider Tests', () {
    test('emits zero-filled daily report when no transactions exist in month', () async {
      final filter = DateRangeFilter.forMonth('2026-10');
      final report = await container.read(spendingOverTimeProvider(filter).future);

      expect(report.isEmpty, isTrue);
      // October has 31 days
      expect(report.items.length, 31);
      expect(report.totalExpense, 0);
      expect(report.items.every((d) => d.amount == 0), isTrue);
    });

    test('aggregates multiple expenses by calendar day and computes stats', () async {
      final filter = DateRangeFilter.forMonth('2026-10');

      // 2 expenses on Oct 5 (100k + 200k = 300k)
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('tx-d1-1'),
          amount: const drift.Value(100000),
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value('cat-food'),
          source: const drift.Value('Cash'),
          date: drift.Value(DateTime.utc(2026, 10, 5, 8, 0)),
          createdAt: drift.Value(DateTime.utc(2026, 10, 5, 8, 0)),
        ),
      );

      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('tx-d1-2'),
          amount: const drift.Value(200000),
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value('cat-food'),
          source: const drift.Value('BCA'),
          date: drift.Value(DateTime.utc(2026, 10, 5, 18, 0)),
          createdAt: drift.Value(DateTime.utc(2026, 10, 5, 18, 0)),
        ),
      );

      // 1 expense on Oct 20 (150k)
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('tx-d2-1'),
          amount: const drift.Value(150000),
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value('cat-transport'),
          source: const drift.Value('GoPay'),
          date: drift.Value(DateTime.utc(2026, 10, 20, 14, 0)),
          createdAt: drift.Value(DateTime.utc(2026, 10, 20, 14, 0)),
        ),
      );

      // Income transaction on Oct 5 (should be ignored)
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('tx-income'),
          amount: const drift.Value(1000000),
          type: const drift.Value(TransactionType.income),
          categoryId: const drift.Value('cat-food'),
          source: const drift.Value('Bonus'),
          date: drift.Value(DateTime.utc(2026, 10, 5, 9, 0)),
          createdAt: drift.Value(DateTime.utc(2026, 10, 5, 9, 0)),
        ),
      );

      final report = await container.read(spendingOverTimeProvider(filter).future);

      expect(report.hasData, isTrue);
      expect(report.totalExpense, 450000);
      expect(report.items.length, 31);

      // Oct 5 (index 4) should have 300,000 and 2 transactions
      final oct5 = report.items[4];
      expect(oct5.date.day, 5);
      expect(oct5.amount, 300000);
      expect(oct5.transactionCount, 2);

      // Oct 20 (index 19) should have 150,000 and 1 transaction
      final oct20 = report.items[19];
      expect(oct20.date.day, 20);
      expect(oct20.amount, 150000);
      expect(oct20.transactionCount, 1);

      // Peak / highest spending day should be Oct 5
      expect(report.highestSpendingDay, equals(oct5));
      expect(report.maxDailyExpense, 300000);
      expect(report.averageDailyExpense, (450000 / 31).round());
    });
  });
}
