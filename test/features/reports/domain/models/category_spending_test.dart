import 'package:budget_tracker/database/app_database.dart';
import 'package:budget_tracker/database/converters/transaction_type.dart';
import 'package:budget_tracker/features/reports/domain/models/category_spending.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final testCategory1 = Category(
    id: 'cat-food',
    name: 'Food & Dining',
    icon: 'restaurant',
    color: 0xFF43A047,
    type: TransactionType.expense,
    isDefault: true,
    isActive: true,
    sortOrder: 1,
    createdAt: DateTime.utc(2026, 1, 1),
  );

  final testCategory2 = Category(
    id: 'cat-transport',
    name: 'Transportation',
    icon: 'directions_bus',
    color: 0xFF1E88E5,
    type: TransactionType.expense,
    isDefault: true,
    isActive: true,
    sortOrder: 2,
    createdAt: DateTime.utc(2026, 1, 1),
  );

  group('CategorySpending Model Tests', () {
    test('instantiates and formats toString correctly', () {
      final spending = CategorySpending(
        category: testCategory1,
        amount: 500000,
        percentage: 50.0,
        transactionCount: 3,
      );

      expect(spending.category.name, 'Food & Dining');
      expect(spending.amount, 500000);
      expect(spending.percentage, 50.0);
      expect(spending.transactionCount, 3);
      expect(spending.toString(), contains('Food & Dining'));
      expect(spending.toString(), contains('50.0%'));
    });

    test('equality and hashCode work properly', () {
      final spending1 = CategorySpending(
        category: testCategory1,
        amount: 500000,
        percentage: 50.0,
        transactionCount: 3,
      );

      final spending2 = CategorySpending(
        category: testCategory1,
        amount: 500000,
        percentage: 50.0,
        transactionCount: 3,
      );

      final spending3 = CategorySpending(
        category: testCategory2,
        amount: 250000,
        percentage: 25.0,
        transactionCount: 1,
      );

      expect(spending1, equals(spending2));
      expect(spending1.hashCode, equals(spending2.hashCode));
      expect(spending1, isNot(equals(spending3)));
    });
  });

  group('CategorySpendingReport Model Tests', () {
    test('computes isEmpty and hasData correctly', () {
      final start = DateTime.utc(2026, 10, 1);
      final end = DateTime.utc(2026, 10, 31, 23, 59, 59);

      final emptyReport = CategorySpendingReport(
        items: const [],
        totalExpense: 0,
        startDate: start,
        endDate: end,
      );

      expect(emptyReport.isEmpty, isTrue);
      expect(emptyReport.hasData, isFalse);
      expect(emptyReport.topCategory, isNull);

      final spendingItem = CategorySpending(
        category: testCategory1,
        amount: 500000,
        percentage: 100.0,
        transactionCount: 2,
      );

      final populatedReport = CategorySpendingReport(
        items: [spendingItem],
        totalExpense: 500000,
        startDate: start,
        endDate: end,
      );

      expect(populatedReport.isEmpty, isFalse);
      expect(populatedReport.hasData, isTrue);
      expect(populatedReport.topCategory, equals(spendingItem));
    });

    test('equality and hashCode work properly on report', () {
      final start = DateTime.utc(2026, 10, 1);
      final end = DateTime.utc(2026, 10, 31, 23, 59, 59);

      final spendingItem = CategorySpending(
        category: testCategory1,
        amount: 500000,
        percentage: 100.0,
      );

      final report1 = CategorySpendingReport(
        items: [spendingItem],
        totalExpense: 500000,
        startDate: start,
        endDate: end,
      );

      final report2 = CategorySpendingReport(
        items: [spendingItem],
        totalExpense: 500000,
        startDate: start,
        endDate: end,
      );

      expect(report1, equals(report2));
      expect(report1.hashCode, equals(report2.hashCode));
    });
  });
}
