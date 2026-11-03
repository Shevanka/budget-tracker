import 'dart:async';

import '../../../../core/utils/id_generator.dart';
import '../../../../core/utils/year_month_utils.dart';
import '../../../../database/app_database.dart';
import '../../../../database/daos/budget_dao.dart';
import '../../../../database/daos/category_dao.dart';
import '../../../../database/daos/transaction_dao.dart';
import '../models/budget_status.dart';

/// Domain service responsible for calculating budget metrics:
/// - Spent amount, allocated limit, and remaining balance per category
/// - Budget consumption percentage and threshold level (safe / warning / danger)
/// - Total monthly budget overview and reactive streams
class BudgetService {
  final BudgetDao _budgetDao;
  final TransactionDao _transactionDao;
  final CategoryDao _categoryDao;

  BudgetService({
    required BudgetDao budgetDao,
    required TransactionDao transactionDao,
    required CategoryDao categoryDao,
  })  : _budgetDao = budgetDao,
        _transactionDao = transactionDao,
        _categoryDao = categoryDao;

  /// Pure calculation of a category's budget status from raw numbers.
  CategoryBudgetStatus calculateCategoryStatus({
    required Category category,
    required int limit,
    required int spent,
  }) {
    return CategoryBudgetStatus.calculate(
      category: category,
      limit: limit,
      spent: spent,
    );
  }

  /// Pure calculation of monthly budget status from aggregated figures.
  MonthlyBudgetStatus calculateMonthlyStatus({
    required String yearMonth,
    required int totalLimit,
    required int totalSpent,
    required List<CategoryBudgetStatus> categoryStatuses,
    required int unbudgetedSpent,
  }) {
    return MonthlyBudgetStatus.calculate(
      yearMonth: yearMonth,
      totalLimit: totalLimit,
      totalSpent: totalSpent,
      categoryStatuses: categoryStatuses,
      unbudgetedSpent: unbudgetedSpent,
    );
  }

  /// Calculates the budget status for a specific category in [yearMonth].
  /// Returns `null` if the category does not exist in the database.
  Future<CategoryBudgetStatus?> getCategoryBudgetStatus(
    String yearMonth,
    String categoryId,
  ) async {
    final category = await _categoryDao.getCategoryById(categoryId);
    if (category == null) return null;

    final limit = await _budgetDao.getCategoryLimit(yearMonth, categoryId) ?? 0;
    final start = YearMonthUtils.getStartOfMonth(yearMonth);
    final end = YearMonthUtils.getEndOfMonth(yearMonth);
    final spent = await _transactionDao.getTotalSpentForCategory(
      categoryId,
      start,
      end,
    );

    return calculateCategoryStatus(
      category: category,
      limit: limit,
      spent: spent,
    );
  }

  /// Calculates the complete [MonthlyBudgetStatus] for [yearMonth]
  /// combining the monthly total budget and per-category breakdowns.
  Future<MonthlyBudgetStatus> getMonthlyBudgetStatus(String yearMonth) async {
    final budget = await _budgetDao.getBudgetForMonth(yearMonth);
    final totalLimit = budget?.totalLimit ?? 0;

    final start = YearMonthUtils.getStartOfMonth(yearMonth);
    final end = YearMonthUtils.getEndOfMonth(yearMonth);

    final totalSpent = await _transactionDao.getTotalSpent(start, end);
    final categoryExpenses =
        await _transactionDao.getCategoryExpensesByDateRange(start, end);

    final budgetCategories = budget != null
        ? await _budgetDao.getBudgetCategories(budget.id)
        : <BudgetCategory>[];
    final categoryLimitsMap = {
      for (final bc in budgetCategories) bc.categoryId: bc.limitAmount,
    };

    final allCategories = await _categoryDao.getAllCategories();
    final categoriesMap = {for (final c in allCategories) c.id: c};

    // Union of categories that either have a limit or have expenses this month
    final relevantCategoryIds = {
      ...categoryLimitsMap.keys,
      ...categoryExpenses.keys,
    };

    final categoryStatuses = <CategoryBudgetStatus>[];
    int unbudgetedSpent = 0;

    for (final catId in relevantCategoryIds) {
      final category = categoriesMap[catId];
      if (category == null) continue;

      final limit = categoryLimitsMap[catId] ?? 0;
      final spent = categoryExpenses[catId] ?? 0;

      if (limit == 0 && spent > 0) {
        unbudgetedSpent += spent;
      }

      categoryStatuses.add(
        calculateCategoryStatus(
          category: category,
          limit: limit,
          spent: spent,
        ),
      );
    }

    // Sort category statuses: categories with limits first (by spent desc), then unbudgeted by spent desc
    categoryStatuses.sort((a, b) {
      if (a.hasLimit && !b.hasLimit) return -1;
      if (!a.hasLimit && b.hasLimit) return 1;
      return b.spent.compareTo(a.spent);
    });

    return calculateMonthlyStatus(
      yearMonth: yearMonth,
      totalLimit: totalLimit,
      totalSpent: totalSpent,
      categoryStatuses: categoryStatuses,
      unbudgetedSpent: unbudgetedSpent,
    );
  }

  /// Streams reactive updates to [MonthlyBudgetStatus] whenever budget limits
  /// or transactions change in [yearMonth].
  Stream<MonthlyBudgetStatus> watchMonthlyBudgetStatus(String yearMonth) {
    return Stream<MonthlyBudgetStatus>.multi((emitter) {
      final start = YearMonthUtils.getStartOfMonth(yearMonth);
      final end = YearMonthUtils.getEndOfMonth(yearMonth);

      void emitStatus() async {
        try {
          final status = await getMonthlyBudgetStatus(yearMonth);
          if (emitter.hasListener) {
            emitter.add(status);
          }
        } catch (e, st) {
          if (emitter.hasListener) {
            emitter.addError(e, st);
          }
        }
      }

      final budgetSub = _budgetDao
          .watchBudgetForMonth(yearMonth)
          .listen((_) => emitStatus());
      final expenseSub = _transactionDao
          .watchCategoryExpensesByDateRange(start, end)
          .listen((_) => emitStatus());

      emitter.onCancel = () {
        budgetSub.cancel();
        expenseSub.cancel();
      };
    }).distinct();
  }

  /// Streams reactive updates to [CategoryBudgetStatus] for a single category.
  Stream<CategoryBudgetStatus?> watchCategoryBudgetStatus(
    String yearMonth,
    String categoryId,
  ) {
    return Stream<CategoryBudgetStatus?>.multi((emitter) {
      final start = YearMonthUtils.getStartOfMonth(yearMonth);
      final end = YearMonthUtils.getEndOfMonth(yearMonth);

      void emitStatus() async {
        try {
          final status = await getCategoryBudgetStatus(yearMonth, categoryId);
          if (emitter.hasListener) {
            emitter.add(status);
          }
        } catch (e, st) {
          if (emitter.hasListener) {
            emitter.addError(e, st);
          }
        }
      }

      final budgetSub = _budgetDao
          .watchBudgetForMonth(yearMonth)
          .listen((_) => emitStatus());
      final expenseSub = _transactionDao
          .watchTotalSpentForCategory(categoryId, start, end)
          .listen((_) => emitStatus());

      emitter.onCancel = () {
        budgetSub.cancel();
        expenseSub.cancel();
      };
    }).distinct();
  }

  /// Finds the preceding budget that can be rolled over to [yearMonth].
  ///
  /// First checks the immediate previous month (`YearMonthUtils.previousYearMonth(yearMonth)`).
  /// If none exists and [fallbackToLatest] is `true`, checks the most recent budget prior to [yearMonth].
  Future<Budget?> getPreviousAvailableBudget(
    String yearMonth, {
    bool fallbackToLatest = true,
  }) async {
    final prevMonth = YearMonthUtils.previousYearMonth(yearMonth);
    final prevBudget = await _budgetDao.getBudgetForMonth(prevMonth);
    if (prevBudget != null) {
      return prevBudget;
    }

    if (fallbackToLatest) {
      return _budgetDao.getLatestBudgetBefore(yearMonth);
    }
    return null;
  }

  /// Ensures a budget exists for [yearMonth] by copying the previous month's budget
  /// (or the most recent preceding budget) if no budget currently exists.
  ///
  /// Rollover rules:
  /// 1. If a budget already exists for [yearMonth], returns the existing budget immediately.
  /// 2. If no budget exists, finds the previous available budget via [getPreviousAvailableBudget].
  /// 3. If a previous budget is found, duplicates its totalLimit and all category limits
  ///    under new UUIDs with UTC timestamp for [yearMonth].
  /// 4. Returns the newly rolled-over [Budget], or `null` if no preceding budget is available.
  Future<Budget?> ensureMonthlyBudgetRollover(
    String yearMonth, {
    bool fallbackToLatest = true,
  }) async {
    final existingBudget = await _budgetDao.getBudgetForMonth(yearMonth);
    if (existingBudget != null) {
      return existingBudget;
    }

    final sourceBudget = await getPreviousAvailableBudget(
      yearMonth,
      fallbackToLatest: fallbackToLatest,
    );

    if (sourceBudget == null) {
      return null;
    }

    final newBudgetId = IdGenerator.generate();
    final success = await _budgetDao.copyBudget(
      fromYearMonth: sourceBudget.yearMonth,
      toYearMonth: yearMonth,
      newBudgetId: newBudgetId,
      newCategoryLimitId: () => IdGenerator.generate(),
      createdAt: DateTime.now().toUtc(),
    );

    if (success) {
      return _budgetDao.getBudgetForMonth(yearMonth);
    }
    return null;
  }
}

