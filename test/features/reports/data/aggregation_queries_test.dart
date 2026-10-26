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

    await db.categoryDao.insertCategory(
      CategoriesCompanion(
        id: const drift.Value('cat-utilities'),
        name: const drift.Value('Utilities'),
        icon: const drift.Value('bolt'),
        color: const drift.Value(0xFFFB8C00),
        type: const drift.Value(TransactionType.expense),
        createdAt: drift.Value(DateTime.utc(2026, 1, 1)),
      ),
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  group('Boundary Conditions & Date Filtering Tests', () {
    test('accurately includes transactions on exact millisecond boundaries', () async {
      final filter = DateRangeFilter.forMonth('2026-10');
      // filter.startDate is 2026-10-01 00:00:00.000Z
      // filter.endDate is 2026-10-31 23:59:59.999Z

      // Transaction exactly at start millisecond (inclusive)
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('tx-start'),
          amount: const drift.Value(100000),
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value('cat-food'),
          source: const drift.Value('Cash'),
          date: drift.Value(DateTime.utc(2026, 10, 1, 0, 0, 0, 0)),
          createdAt: drift.Value(DateTime.utc(2026, 10, 1, 0, 0, 0, 0)),
        ),
      );

      // Transaction exactly at end millisecond (inclusive)
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('tx-end'),
          amount: const drift.Value(200000),
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value('cat-transport'),
          source: const drift.Value('BCA'),
          date: drift.Value(DateTime.utc(2026, 10, 31, 23, 59, 59, 999)),
          createdAt: drift.Value(DateTime.utc(2026, 10, 31, 23, 59, 59, 999)),
        ),
      );

      // Transaction 1 ms before start boundary (must be excluded)
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('tx-before'),
          amount: const drift.Value(500000),
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value('cat-food'),
          source: const drift.Value('Cash'),
          date: drift.Value(DateTime.utc(2026, 9, 30, 23, 59, 59, 999)),
          createdAt: drift.Value(DateTime.utc(2026, 9, 30, 23, 59, 59, 999)),
        ),
      );

      // Transaction 1 ms after end boundary (must be excluded)
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('tx-after'),
          amount: const drift.Value(500000),
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value('cat-food'),
          source: const drift.Value('Cash'),
          date: drift.Value(DateTime.utc(2026, 11, 1, 0, 0, 0, 0)),
          createdAt: drift.Value(DateTime.utc(2026, 11, 1, 0, 0, 0, 0)),
        ),
      );

      final categoryReport = await container.read(categorySpendingReportProvider(filter).future);
      expect(categoryReport.totalExpense, 300000);
      expect(categoryReport.items.length, 2);

      final overTimeReport = await container.read(spendingOverTimeProvider(filter).future);
      expect(overTimeReport.totalExpense, 300000);
      // Day 1 has 100,000
      expect(overTimeReport.items.first.amount, 100000);
      // Day 31 has 200,000
      expect(overTimeReport.items.last.amount, 200000);
    });

    test('strictly excludes income transactions from expense aggregation', () async {
      final filter = DateRangeFilter.forMonth('2026-10');

      // Expense
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('tx-exp'),
          amount: const drift.Value(150000),
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value('cat-food'),
          source: const drift.Value('Cash'),
          date: drift.Value(DateTime.utc(2026, 10, 10)),
          createdAt: drift.Value(DateTime.utc(2026, 10, 10)),
        ),
      );

      // Income (should be ignored)
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('tx-inc'),
          amount: const drift.Value(10000000),
          type: const drift.Value(TransactionType.income),
          categoryId: const drift.Value('cat-food'),
          source: const drift.Value('Salary'),
          date: drift.Value(DateTime.utc(2026, 10, 10)),
          createdAt: drift.Value(DateTime.utc(2026, 10, 10)),
        ),
      );

      final categoryReport = await container.read(categorySpendingReportProvider(filter).future);
      expect(categoryReport.totalExpense, 150000);
      expect(categoryReport.items.first.amount, 150000);

      final overTimeReport = await container.read(spendingOverTimeProvider(filter).future);
      expect(overTimeReport.totalExpense, 150000);
    });
  });

  group('Category Breakdown Aggregation Tests', () {
    test('calculates exact category percentages and orders by highest amount', () async {
      final filter = DateRangeFilter.forMonth('2026-10');

      // Food: 500,000 (50%)
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('tx-f1'),
          amount: const drift.Value(300000),
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value('cat-food'),
          source: const drift.Value('BCA'),
          date: drift.Value(DateTime.utc(2026, 10, 2)),
          createdAt: drift.Value(DateTime.utc(2026, 10, 2)),
        ),
      );
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('tx-f2'),
          amount: const drift.Value(200000),
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value('cat-food'),
          source: const drift.Value('Cash'),
          date: drift.Value(DateTime.utc(2026, 10, 3)),
          createdAt: drift.Value(DateTime.utc(2026, 10, 3)),
        ),
      );

      // Transport: 300,000 (30%)
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('tx-t1'),
          amount: const drift.Value(300000),
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value('cat-transport'),
          source: const drift.Value('GoPay'),
          date: drift.Value(DateTime.utc(2026, 10, 5)),
          createdAt: drift.Value(DateTime.utc(2026, 10, 5)),
        ),
      );

      // Utilities: 200,000 (20%)
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('tx-u1'),
          amount: const drift.Value(200000),
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value('cat-utilities'),
          source: const drift.Value('BCA'),
          date: drift.Value(DateTime.utc(2026, 10, 12)),
          createdAt: drift.Value(DateTime.utc(2026, 10, 12)),
        ),
      );

      final report = await container.read(categorySpendingReportProvider(filter).future);

      expect(report.totalExpense, 1000000);
      expect(report.items.length, 3);

      // Item 0: Food
      expect(report.items[0].category.id, 'cat-food');
      expect(report.items[0].amount, 500000);
      expect(report.items[0].percentage, 50.0);
      expect(report.items[0].transactionCount, 2);

      // Item 1: Transport
      expect(report.items[1].category.id, 'cat-transport');
      expect(report.items[1].amount, 300000);
      expect(report.items[1].percentage, 30.0);
      expect(report.items[1].transactionCount, 1);

      // Item 2: Utilities
      expect(report.items[2].category.id, 'cat-utilities');
      expect(report.items[2].amount, 200000);
      expect(report.items[2].percentage, 20.0);
      expect(report.items[2].transactionCount, 1);

      // Top category getter
      expect(report.topCategory, equals(report.items[0]));
    });

    test('supports single-day custom date range', () async {
      final day = DateTime(2026, 8, 15);
      final filter = DateRangeFilter.custom(start: day, end: day);

      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('tx-single-day-1'),
          amount: const drift.Value(75000),
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value('cat-food'),
          source: const drift.Value('Cash'),
          date: drift.Value(DateTime.utc(2026, 8, 15, 10, 0)),
          createdAt: drift.Value(DateTime.utc(2026, 8, 15, 10, 0)),
        ),
      );
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('tx-single-day-2'),
          amount: const drift.Value(25000),
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value('cat-transport'),
          source: const drift.Value('GoPay'),
          date: drift.Value(DateTime.utc(2026, 8, 15, 16, 30)),
          createdAt: drift.Value(DateTime.utc(2026, 8, 15, 16, 30)),
        ),
      );

      final catReport = await container.read(categorySpendingReportProvider(filter).future);
      expect(catReport.totalExpense, 100000);
      expect(catReport.items.length, 2);

      final overTimeReport = await container.read(spendingOverTimeProvider(filter).future);
      expect(overTimeReport.totalExpense, 100000);
      expect(overTimeReport.items.length, 1);
      expect(overTimeReport.items.first.amount, 100000);
      expect(overTimeReport.items.first.transactionCount, 2);
    });

    test('supports multi-month custom date range', () async {
      // Q1: Jan 1 to Mar 31 (90 days in 2026)
      final filter = DateRangeFilter.custom(
        start: DateTime(2026, 1, 1),
        end: DateTime(2026, 3, 31),
        label: 'Q1 2026',
      );

      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('tx-q1-jan'),
          amount: const drift.Value(100000),
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value('cat-food'),
          source: const drift.Value('BCA'),
          date: drift.Value(DateTime.utc(2026, 1, 15)),
          createdAt: drift.Value(DateTime.utc(2026, 1, 15)),
        ),
      );
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('tx-q1-feb'),
          amount: const drift.Value(200000),
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value('cat-food'),
          source: const drift.Value('BCA'),
          date: drift.Value(DateTime.utc(2026, 2, 10)),
          createdAt: drift.Value(DateTime.utc(2026, 2, 10)),
        ),
      );
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('tx-q1-mar'),
          amount: const drift.Value(300000),
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value('cat-food'),
          source: const drift.Value('BCA'),
          date: drift.Value(DateTime.utc(2026, 3, 20)),
          createdAt: drift.Value(DateTime.utc(2026, 3, 20)),
        ),
      );

      final report = await container.read(categorySpendingReportProvider(filter).future);
      expect(report.totalExpense, 600000);
      expect(report.items.length, 1);
      expect(report.items.first.amount, 600000);
      expect(report.items.first.transactionCount, 3);

      final overTime = await container.read(spendingOverTimeProvider(filter).future);
      // Jan (31) + Feb (28) + Mar (31) = 90 days
      expect(overTime.items.length, 90);
      expect(overTime.totalExpense, 600000);
    });
  });

  group('Time-Series Spending Over Time Aggregation Tests', () {
    test('generates correct contiguous daily buckets for leap year February', () async {
      // 2024 is a leap year (29 days in Feb)
      final filter = DateRangeFilter.forMonth('2024-02');
      final report = await container.read(spendingOverTimeProvider(filter).future);

      expect(report.items.length, 29);
      expect(report.items.first.date, DateTime.utc(2024, 2, 1));
      expect(report.items.last.date, DateTime.utc(2024, 2, 29));
    });

    test('generates correct contiguous daily buckets for non-leap year February', () async {
      // 2026 is a standard year (28 days in Feb)
      final filter = DateRangeFilter.forMonth('2026-02');
      final report = await container.read(spendingOverTimeProvider(filter).future);

      expect(report.items.length, 28);
      expect(report.items.first.date, DateTime.utc(2026, 2, 1));
      expect(report.items.last.date, DateTime.utc(2026, 2, 28));
    });

    test('generates contiguous daily buckets spanning year-end transition', () async {
      // Dec 28, 2025 to Jan 4, 2026 (8 days)
      final filter = DateRangeFilter.custom(
        start: DateTime(2025, 12, 28),
        end: DateTime(2026, 1, 4),
      );

      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('tx-ny-1'),
          amount: const drift.Value(50000),
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value('cat-food'),
          source: const drift.Value('Cash'),
          date: drift.Value(DateTime.utc(2025, 12, 31, 22, 0)),
          createdAt: drift.Value(DateTime.utc(2025, 12, 31, 22, 0)),
        ),
      );
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('tx-ny-2'),
          amount: const drift.Value(150000),
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value('cat-food'),
          source: const drift.Value('Cash'),
          date: drift.Value(DateTime.utc(2026, 1, 1, 10, 0)),
          createdAt: drift.Value(DateTime.utc(2026, 1, 1, 10, 0)),
        ),
      );

      final report = await container.read(spendingOverTimeProvider(filter).future);
      expect(report.items.length, 8);
      expect(report.totalExpense, 200000);

      // Dec 31 (index 3)
      expect(report.items[3].date, DateTime.utc(2025, 12, 31));
      expect(report.items[3].amount, 50000);

      // Jan 1 (index 4)
      expect(report.items[4].date, DateTime.utc(2026, 1, 1));
      expect(report.items[4].amount, 150000);
    });

    test('tie-breaking in highest spending day picks first peak day and computes max/average', () async {
      final filter = DateRangeFilter.forMonth('2026-10');

      // Day 5 has 300,000
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('tx-peak-1'),
          amount: const drift.Value(300000),
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value('cat-food'),
          source: const drift.Value('Cash'),
          date: drift.Value(DateTime.utc(2026, 10, 5)),
          createdAt: drift.Value(DateTime.utc(2026, 10, 5)),
        ),
      );

      // Day 20 also has 300,000 (tied peak)
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('tx-peak-2'),
          amount: const drift.Value(300000),
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value('cat-transport'),
          source: const drift.Value('Cash'),
          date: drift.Value(DateTime.utc(2026, 10, 20)),
          createdAt: drift.Value(DateTime.utc(2026, 10, 20)),
        ),
      );

      final report = await container.read(spendingOverTimeProvider(filter).future);

      expect(report.totalExpense, 600000);
      expect(report.maxDailyExpense, 300000);
      expect(report.averageDailyExpense, (600000 / 31).round());

      // Highest day tie-breaking selects first encountered peak day
      expect(report.highestSpendingDay, isNotNull);
      expect(report.highestSpendingDay!.amount, 300000);
      expect(report.highestSpendingDay!.date.day, 5);
    });
  });

  group('Stress & Consistency Tests', () {
    test('aggregates 100+ transactions consistently across reports and time-series', () async {
      final filter = DateRangeFilter.forMonth('2026-10');

      var expectedTotal = 0;
      var expectedFood = 0;
      var expectedTransport = 0;
      var expectedUtilities = 0;

      // Insert 124 transactions (4 per day for 31 days)
      for (var day = 1; day <= 31; day++) {
        final amount1 = 10000 * day;
        final amount2 = 5000 * day;
        final amount3 = 2000 * day;

        // Tx 1: Food
        await db.transactionDao.insertTransaction(
          TransactionsCompanion(
            id: drift.Value('tx-stress-f-$day'),
            amount: drift.Value(amount1),
            type: const drift.Value(TransactionType.expense),
            categoryId: const drift.Value('cat-food'),
            source: const drift.Value('BCA'),
            date: drift.Value(DateTime.utc(2026, 10, day, 9, 0)),
            createdAt: drift.Value(DateTime.utc(2026, 10, day, 9, 0)),
          ),
        );
        expectedFood += amount1;

        // Tx 2: Transport
        await db.transactionDao.insertTransaction(
          TransactionsCompanion(
            id: drift.Value('tx-stress-t-$day'),
            amount: drift.Value(amount2),
            type: const drift.Value(TransactionType.expense),
            categoryId: const drift.Value('cat-transport'),
            source: const drift.Value('GoPay'),
            date: drift.Value(DateTime.utc(2026, 10, day, 13, 0)),
            createdAt: drift.Value(DateTime.utc(2026, 10, day, 13, 0)),
          ),
        );
        expectedTransport += amount2;

        // Tx 3: Utilities
        await db.transactionDao.insertTransaction(
          TransactionsCompanion(
            id: drift.Value('tx-stress-u-$day'),
            amount: drift.Value(amount3),
            type: const drift.Value(TransactionType.expense),
            categoryId: const drift.Value('cat-utilities'),
            source: const drift.Value('Cash'),
            date: drift.Value(DateTime.utc(2026, 10, day, 18, 0)),
            createdAt: drift.Value(DateTime.utc(2026, 10, day, 18, 0)),
          ),
        );
        expectedUtilities += amount3;

        // Tx 4: Income on every day (must be excluded from expense totals)
        await db.transactionDao.insertTransaction(
          TransactionsCompanion(
            id: drift.Value('tx-stress-inc-$day'),
            amount: const drift.Value(1000000),
            type: const drift.Value(TransactionType.income),
            categoryId: const drift.Value('cat-food'),
            source: const drift.Value('Salary'),
            date: drift.Value(DateTime.utc(2026, 10, day, 8, 0)),
            createdAt: drift.Value(DateTime.utc(2026, 10, day, 8, 0)),
          ),
        );
      }

      expectedTotal = expectedFood + expectedTransport + expectedUtilities;

      // 1. Check Category Spending Report
      final categoryReport = await container.read(categorySpendingReportProvider(filter).future);
      expect(categoryReport.totalExpense, expectedTotal);
      expect(categoryReport.items.length, 3);

      final foodItem = categoryReport.items.firstWhere((i) => i.category.id == 'cat-food');
      final transportItem = categoryReport.items.firstWhere((i) => i.category.id == 'cat-transport');
      final utilitiesItem = categoryReport.items.firstWhere((i) => i.category.id == 'cat-utilities');

      expect(foodItem.amount, expectedFood);
      expect(foodItem.transactionCount, 31);
      expect(transportItem.amount, expectedTransport);
      expect(transportItem.transactionCount, 31);
      expect(utilitiesItem.amount, expectedUtilities);
      expect(utilitiesItem.transactionCount, 31);

      // Percentage sum must be ~100.0%
      final percentageSum = foodItem.percentage + transportItem.percentage + utilitiesItem.percentage;
      expect((percentageSum - 100.0).abs() < 0.05, isTrue);

      // 2. Check Spending Over Time Report
      final overTimeReport = await container.read(spendingOverTimeProvider(filter).future);
      expect(overTimeReport.totalExpense, expectedTotal);
      expect(overTimeReport.items.length, 31);

      // Each day's sum must match amount1 + amount2 + amount3 for that day
      for (var day = 1; day <= 31; day++) {
        final daySpending = overTimeReport.items[day - 1];
        final expectedDayTotal = (10000 * day) + (5000 * day) + (2000 * day);
        expect(daySpending.amount, expectedDayTotal);
        expect(daySpending.transactionCount, 3);
      }

      // Mathematical consistency: sum of all daily spending items equals category report total
      final sumOfDailyItems = overTimeReport.items.fold<int>(0, (sum, item) => sum + item.amount);
      expect(sumOfDailyItems, expectedTotal);
    });
  });
}
