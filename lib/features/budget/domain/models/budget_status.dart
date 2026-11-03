import 'package:flutter/foundation.dart' show listEquals;

import '../../../../database/app_database.dart';

/// Semantic threshold levels for budget consumption:
/// - [safe]: < 80% of limit consumed
/// - [warning]: 80% to 99% of limit consumed
/// - [danger]: >= 100% of limit consumed (exceeded or fully exhausted)
enum BudgetStatusLevel {
  safe,
  warning,
  danger,
}

/// Represents the calculated budget consumption status for an individual category.
class CategoryBudgetStatus {
  final Category category;
  final int limit;
  final int spent;
  final int remaining;
  final int percentage;
  final double ratio;
  final BudgetStatusLevel statusLevel;

  const CategoryBudgetStatus({
    required this.category,
    required this.limit,
    required this.spent,
    required this.remaining,
    required this.percentage,
    required this.ratio,
    required this.statusLevel,
  });

  /// Whether a positive budget limit is configured for this category.
  bool get hasLimit => limit > 0;

  /// Whether spending has strictly exceeded the allocated limit.
  bool get isExceeded => hasLimit && spent > limit;

  /// Whether spending has reached the 80%-99% warning threshold.
  bool get isNearLimit => percentage >= 80 && percentage < 100;

  /// Pure calculation factory creating a [CategoryBudgetStatus] from raw figures.
  factory CategoryBudgetStatus.calculate({
    required Category category,
    required int limit,
    required int spent,
  }) {
    final remaining = limit - spent;
    final percentage = limit > 0 ? ((spent / limit) * 100).round() : 0;
    final ratio = limit > 0 ? (spent / limit) : 0.0;

    final BudgetStatusLevel statusLevel;
    if (limit <= 0) {
      statusLevel = BudgetStatusLevel.safe;
    } else if (percentage >= 100) {
      statusLevel = BudgetStatusLevel.danger;
    } else if (percentage >= 80) {
      statusLevel = BudgetStatusLevel.warning;
    } else {
      statusLevel = BudgetStatusLevel.safe;
    }

    return CategoryBudgetStatus(
      category: category,
      limit: limit,
      spent: spent,
      remaining: remaining,
      percentage: percentage,
      ratio: ratio,
      statusLevel: statusLevel,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryBudgetStatus &&
          runtimeType == other.runtimeType &&
          category.id == other.category.id &&
          limit == other.limit &&
          spent == other.spent &&
          remaining == other.remaining &&
          percentage == other.percentage &&
          ratio == other.ratio &&
          statusLevel == other.statusLevel;

  @override
  int get hashCode => Object.hash(
        category.id,
        limit,
        spent,
        remaining,
        percentage,
        ratio,
        statusLevel,
      );

  @override
  String toString() =>
      'CategoryBudgetStatus(category: ${category.name}, limit: $limit, spent: $spent, remaining: $remaining, percentage: $percentage%, level: ${statusLevel.name})';
}

/// Represents the overall monthly budget status, combining overall limit,
/// total spending, remaining balance, and individual category breakdowns.
class MonthlyBudgetStatus {
  final String yearMonth;
  final int totalLimit;
  final int totalSpent;
  final int totalRemaining;
  final int percentage;
  final double ratio;
  final BudgetStatusLevel statusLevel;
  final List<CategoryBudgetStatus> categoryStatuses;
  final int unbudgetedSpent;

  const MonthlyBudgetStatus({
    required this.yearMonth,
    required this.totalLimit,
    required this.totalSpent,
    required this.totalRemaining,
    required this.percentage,
    required this.ratio,
    required this.statusLevel,
    required this.categoryStatuses,
    required this.unbudgetedSpent,
  });

  /// Whether a total budget limit was set for this month.
  bool get hasBudget => totalLimit > 0;

  /// Whether total spending has strictly exceeded the monthly budget.
  bool get isExceeded => hasBudget && totalSpent > totalLimit;

  /// Whether total spending has reached the 80%-99% warning threshold.
  bool get isNearLimit => percentage >= 80 && percentage < 100;

  /// Pure calculation factory creating a [MonthlyBudgetStatus] from raw figures.
  factory MonthlyBudgetStatus.calculate({
    required String yearMonth,
    required int totalLimit,
    required int totalSpent,
    required List<CategoryBudgetStatus> categoryStatuses,
    required int unbudgetedSpent,
  }) {
    final totalRemaining = totalLimit - totalSpent;
    final percentage = totalLimit > 0 ? ((totalSpent / totalLimit) * 100).round() : 0;
    final ratio = totalLimit > 0 ? (totalSpent / totalLimit) : 0.0;

    final BudgetStatusLevel statusLevel;
    if (totalLimit <= 0) {
      statusLevel = BudgetStatusLevel.safe;
    } else if (percentage >= 100) {
      statusLevel = BudgetStatusLevel.danger;
    } else if (percentage >= 80) {
      statusLevel = BudgetStatusLevel.warning;
    } else {
      statusLevel = BudgetStatusLevel.safe;
    }

    return MonthlyBudgetStatus(
      yearMonth: yearMonth,
      totalLimit: totalLimit,
      totalSpent: totalSpent,
      totalRemaining: totalRemaining,
      percentage: percentage,
      ratio: ratio,
      statusLevel: statusLevel,
      categoryStatuses: categoryStatuses,
      unbudgetedSpent: unbudgetedSpent,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonthlyBudgetStatus &&
          runtimeType == other.runtimeType &&
          yearMonth == other.yearMonth &&
          totalLimit == other.totalLimit &&
          totalSpent == other.totalSpent &&
          totalRemaining == other.totalRemaining &&
          percentage == other.percentage &&
          ratio == other.ratio &&
          statusLevel == other.statusLevel &&
          unbudgetedSpent == other.unbudgetedSpent &&
          listEquals(categoryStatuses, other.categoryStatuses);

  @override
  int get hashCode => Object.hash(
        yearMonth,
        totalLimit,
        totalSpent,
        totalRemaining,
        percentage,
        ratio,
        statusLevel,
        unbudgetedSpent,
        Object.hashAll(categoryStatuses),
      );

  @override
  String toString() =>
      'MonthlyBudgetStatus(yearMonth: $yearMonth, totalLimit: $totalLimit, totalSpent: $totalSpent, remaining: $totalRemaining, percentage: $percentage%, level: ${statusLevel.name})';
}
