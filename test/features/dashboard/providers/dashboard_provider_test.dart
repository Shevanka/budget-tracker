import 'package:budget_tracker/core/utils/year_month_utils.dart';
import 'package:budget_tracker/database/app_database.dart';
import 'package:budget_tracker/database/converters/transaction_type.dart';
import 'package:budget_tracker/database/database_provider.dart';
import 'package:budget_tracker/features/dashboard/providers/dashboard_provider.dart';
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

    // Seed test category
    await db.categoryDao.insertCategory(
      CategoriesCompanion(
        id: const drift.Value('cat-1'),
        name: const drift.Value('General'),
        icon: const drift.Value('category'),
        color: const drift.Value(0xFF43A047),
        type: const drift.Value(TransactionType.expense),
        createdAt: drift.Value(DateTime.utc(2026, 1, 1)),
      ),
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  group('SelectedDashboardMonthNotifier', () {
    test('initializes to current yearMonth and responds to navigation methods', () {
      final notifier = container.read(selectedDashboardMonthProvider.notifier);
      expect(
        container.read(selectedDashboardMonthProvider),
        YearMonthUtils.currentYearMonth(),
      );

      notifier.setMonth('2026-05');
      expect(container.read(selectedDashboardMonthProvider), '2026-05');

      notifier.nextMonth();
      expect(container.read(selectedDashboardMonthProvider), '2026-06');

      notifier.previousMonth();
      expect(container.read(selectedDashboardMonthProvider), '2026-05');

      notifier.resetToCurrentMonth();
      expect(
        container.read(selectedDashboardMonthProvider),
        YearMonthUtils.currentYearMonth(),
      );
    });
  });

  group('monthlyFinancialSummaryProvider', () {
    test('emits zeros when no transactions exist in the month', () async {
      final summary =
          await container.read(monthlyFinancialSummaryProvider('2026-10').future);

      expect(summary.yearMonth, '2026-10');
      expect(summary.totalIncome, 0);
      expect(summary.totalExpense, 0);
      expect(summary.netBalance, 0);
      expect(summary.transactionCount, 0);
      expect(summary.hasActivity, isFalse);
    });

    test('calculates income, expense, and net balance correctly within date range', () async {
      // 1. Income: 5,000,000 (October 2026)
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('tx-inc-1'),
          amount: const drift.Value(5000000),
          type: const drift.Value(TransactionType.income),
          categoryId: const drift.Value('cat-1'),
          source: const drift.Value('Payroll'),
          date: drift.Value(DateTime.utc(2026, 10, 1, 9, 0)),
          createdAt: drift.Value(DateTime.utc(2026, 10, 1, 9, 0)),
        ),
      );

      // 2. Expense: 1,500,000 (October 2026)
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('tx-exp-1'),
          amount: const drift.Value(1500000),
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value('cat-1'),
          source: const drift.Value('Cash'),
          date: drift.Value(DateTime.utc(2026, 10, 15, 12, 0)),
          createdAt: drift.Value(DateTime.utc(2026, 10, 15, 12, 0)),
        ),
      );

      // 3. Out-of-range transaction: 2,000,000 (September 2026)
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('tx-old'),
          amount: const drift.Value(2000000),
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value('cat-1'),
          source: const drift.Value('Cash'),
          date: drift.Value(DateTime.utc(2026, 9, 30, 20, 0)),
          createdAt: drift.Value(DateTime.utc(2026, 9, 30, 20, 0)),
        ),
      );

      final summary =
          await container.read(monthlyFinancialSummaryProvider('2026-10').future);

      expect(summary.totalIncome, 5000000);
      expect(summary.totalExpense, 1500000);
      expect(summary.netBalance, 3500000);
      expect(summary.transactionCount, 2);
      expect(summary.isPositiveOrZero, isTrue);
      expect(summary.hasActivity, isTrue);
    });
  });

  group('recentTransactionsForMonthProvider', () {
    test('emits empty list when no transactions exist', () async {
      final recent =
          await container.read(recentTransactionsForMonthProvider('2026-10').future);
      expect(recent, isEmpty);
    });

    test('emits up to 5 transactions in descending date order for the month', () async {
      for (int i = 1; i <= 6; i++) {
        await db.transactionDao.insertTransaction(
          TransactionsCompanion(
            id: drift.Value('tx-recent-$i'),
            amount: drift.Value(i * 10000),
            type: const drift.Value(TransactionType.expense),
            categoryId: const drift.Value('cat-1'),
            source: const drift.Value('BCA'),
            date: drift.Value(DateTime.utc(2026, 10, i, 10, 0)),
            createdAt: drift.Value(DateTime.utc(2026, 10, i, 10, 0)),
          ),
        );
      }

      final recent =
          await container.read(recentTransactionsForMonthProvider('2026-10').future);

      expect(recent.length, 5);
      expect(recent.first.transaction.id, 'tx-recent-6');
      expect(recent.last.transaction.id, 'tx-recent-2');
      expect(recent.first.category?.name, 'General');
    });
  });
}
