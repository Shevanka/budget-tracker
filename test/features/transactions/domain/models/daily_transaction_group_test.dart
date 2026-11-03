import 'package:budget_tracker/database/app_database.dart';
import 'package:budget_tracker/database/converters/transaction_type.dart';
import 'package:budget_tracker/database/daos/transaction_dao.dart';
import 'package:budget_tracker/features/transactions/domain/models/daily_transaction_group.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DailyTransactionGroup', () {
    final foodCategory = Category(
      id: 'cat-food',
      name: 'Food',
      icon: 'restaurant',
      color: 0xFF43A047,
      type: TransactionType.expense,
      isDefault: true,
      isActive: true,
      sortOrder: 0,
      createdAt: DateTime.utc(2026, 10, 1),
    );

    final salaryCategory = Category(
      id: 'cat-salary',
      name: 'Salary',
      icon: 'attach_money',
      color: 0xFF2E7D32,
      type: TransactionType.income,
      isDefault: true,
      isActive: true,
      sortOrder: 1,
      createdAt: DateTime.utc(2026, 10, 1),
    );

    test('fromTransactions returns empty list when given empty input', () {
      final groups = DailyTransactionGroup.fromTransactions([]);
      expect(groups, isEmpty);
    });

    test('groups transactions by local date in descending order', () {
      final tx1 = TransactionWithCategory(
        transaction: Transaction(
          id: 'tx-1',
          amount: 50000,
          type: TransactionType.expense,
          categoryId: 'cat-food',
          source: 'BCA',
          date: DateTime(2026, 10, 15, 10, 0).toUtc(),
          createdAt: DateTime(2026, 10, 15, 10, 0).toUtc(),
          note: 'Lunch',
        ),
        category: foodCategory,
      );

      final tx2 = TransactionWithCategory(
        transaction: Transaction(
          id: 'tx-2',
          amount: 25000,
          type: TransactionType.expense,
          categoryId: 'cat-food',
          source: 'Cash',
          date: DateTime(2026, 10, 15, 14, 0).toUtc(),
          createdAt: DateTime(2026, 10, 15, 14, 0).toUtc(),
          note: 'Snack',
        ),
        category: foodCategory,
      );

      final tx3 = TransactionWithCategory(
        transaction: Transaction(
          id: 'tx-3',
          amount: 5000000,
          type: TransactionType.income,
          categoryId: 'cat-salary',
          source: 'Mandiri',
          date: DateTime(2026, 10, 14, 9, 0).toUtc(),
          createdAt: DateTime(2026, 10, 14, 9, 0).toUtc(),
          note: 'October Salary',
        ),
        category: salaryCategory,
      );

      final groups = DailyTransactionGroup.fromTransactions([tx1, tx2, tx3]);

      expect(groups.length, 2);

      // First group should be Oct 15
      final group1 = groups[0];
      expect(group1.items.length, 2);
      expect(group1.totalExpense, 75000);
      expect(group1.totalIncome, 0);
      expect(group1.netAmount, -75000);

      // Second group should be Oct 14
      final group2 = groups[1];
      expect(group2.items.length, 1);
      expect(group2.totalExpense, 0);
      expect(group2.totalIncome, 5000000);
      expect(group2.netAmount, 5000000);
    });

    test('getDateHeaderLabel returns Today, Yesterday, and formatted date correctly', () {
      final now = DateTime(2026, 10, 15, 14, 0);

      final todayGroup = DailyTransactionGroup(
        date: DateTime(2026, 10, 15),
        items: const [],
        totalExpense: 10000,
        totalIncome: 0,
      );
      expect(todayGroup.getDateHeaderLabel(referenceNow: now), 'Today');

      final yesterdayGroup = DailyTransactionGroup(
        date: DateTime(2026, 10, 14),
        items: const [],
        totalExpense: 20000,
        totalIncome: 0,
      );
      expect(yesterdayGroup.getDateHeaderLabel(referenceNow: now), 'Yesterday');

      final pastGroup = DailyTransactionGroup(
        date: DateTime(2026, 10, 10),
        items: const [],
        totalExpense: 30000,
        totalIncome: 0,
      );
      expect(pastGroup.getDateHeaderLabel(referenceNow: now), contains('10 Oct 2026'));
    });
  });
}
