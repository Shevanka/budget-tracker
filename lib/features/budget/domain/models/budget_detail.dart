import '../../../../database/app_database.dart';

/// Represents an individual category's budget limit paired with its category metadata.
class CategoryLimitItem {
  final Category category;
  final int limitAmount;

  const CategoryLimitItem({
    required this.category,
    required this.limitAmount,
  });

  CategoryLimitItem copyWith({
    Category? category,
    int? limitAmount,
  }) {
    return CategoryLimitItem(
      category: category ?? this.category,
      limitAmount: limitAmount ?? this.limitAmount,
    );
  }
}

/// Aggregated representation of a monthly budget plan, including total limit
/// and per-category allocations.
class MonthlyBudgetPlan {
  final Budget? budget;
  final String yearMonth;
  final int totalLimit;
  final List<CategoryLimitItem> categoryLimits;

  const MonthlyBudgetPlan({
    this.budget,
    required this.yearMonth,
    required this.totalLimit,
    required this.categoryLimits,
  });

  /// The sum of all allocated category limits in IDR.
  int get totalAllocated =>
      categoryLimits.fold(0, (sum, item) => sum + item.limitAmount);

  /// Remaining unallocated amount from the total budget.
  /// Can be negative if category limits exceed the total budget.
  int get unallocatedAmount => totalLimit - totalAllocated;

  /// Whether the sum of category limits strictly exceeds the total budget.
  bool get isOverallocated => totalAllocated > totalLimit && totalLimit > 0;

  /// Ratio of total allocated amount compared to total limit (0.0 to 1.0+).
  double get allocationRatio =>
      totalLimit > 0 ? (totalAllocated / totalLimit) : 0.0;
}
