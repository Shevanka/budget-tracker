import 'package:flutter/foundation.dart' hide Category;

import '../../../../database/app_database.dart';

/// Represents spending in a single category within a specific reporting period.
@immutable
class CategorySpending {
  final Category category;
  final int amount;
  final double percentage;
  final int transactionCount;

  const CategorySpending({
    required this.category,
    required this.amount,
    required this.percentage,
    this.transactionCount = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategorySpending &&
          runtimeType == other.runtimeType &&
          category == other.category &&
          amount == other.amount &&
          (percentage - other.percentage).abs() < 0.001 &&
          transactionCount == other.transactionCount;

  @override
  int get hashCode => Object.hash(category, amount, percentage, transactionCount);

  @override
  String toString() =>
      'CategorySpending(category: ${category.name}, amount: $amount, percentage: ${percentage.toStringAsFixed(1)}%)';
}

/// Represents aggregated category spending report over a date range.
@immutable
class CategorySpendingReport {
  final List<CategorySpending> items;
  final int totalExpense;
  final DateTime startDate;
  final DateTime endDate;

  const CategorySpendingReport({
    required this.items,
    required this.totalExpense,
    required this.startDate,
    required this.endDate,
  });

  bool get isEmpty => totalExpense == 0 || items.isEmpty;
  bool get hasData => !isEmpty;

  CategorySpending? get topCategory => items.isNotEmpty ? items.first : null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategorySpendingReport &&
          runtimeType == other.runtimeType &&
          listEquals(items, other.items) &&
          totalExpense == other.totalExpense &&
          startDate == other.startDate &&
          endDate == other.endDate;

  @override
  int get hashCode => Object.hash(
        Object.hashAll(items),
        totalExpense,
        startDate,
        endDate,
      );
}
