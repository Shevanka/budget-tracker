import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/id_generator.dart';
import '../../../database/app_database.dart';
import '../../../database/database_provider.dart';
import '../domain/models/budget_detail.dart';
import '../domain/models/budget_status.dart';
import '../domain/services/budget_service.dart';

/// Reactive stream of the monthly [Budget] for a specific [yearMonth] ('YYYY-MM').
final budgetForMonthProvider =
    StreamProvider.autoDispose.family<Budget?, String>((ref, yearMonth) {
  final dao = ref.watch(budgetDaoProvider);
  return dao.watchBudgetForMonth(yearMonth);
});

/// Reactive stream of all [BudgetCategory] limits for a specific [budgetId].
final budgetCategoriesProvider =
    StreamProvider.autoDispose.family<List<BudgetCategory>, String>((ref, budgetId) {
  final dao = ref.watch(budgetDaoProvider);
  return dao.watchBudgetCategories(budgetId);
});

/// Reactive stream providing the aggregated [MonthlyBudgetPlan] for [yearMonth].
final monthlyBudgetPlanProvider =
    StreamProvider.autoDispose.family<MonthlyBudgetPlan?, String>((ref, yearMonth) {
  final budgetDao = ref.watch(budgetDaoProvider);
  final categoryDao = ref.watch(categoryDaoProvider);

  return budgetDao.watchBudgetForMonth(yearMonth).asyncMap((budget) async {
    if (budget == null) {
      return null;
    }

    final budgetCategories = await budgetDao.getBudgetCategories(budget.id);
    final allCategories = await categoryDao.getAllCategories();
    final categoriesMap = {for (final cat in allCategories) cat.id: cat};

    final categoryLimits = budgetCategories
        .map((bc) {
          final category = categoriesMap[bc.categoryId];
          if (category == null) return null;
          return CategoryLimitItem(
            category: category,
            limitAmount: bc.limitAmount,
          );
        })
        .whereType<CategoryLimitItem>()
        .toList();

    return MonthlyBudgetPlan(
      budget: budget,
      yearMonth: yearMonth,
      totalLimit: budget.totalLimit,
      categoryLimits: categoryLimits,
    );
  });
});

/// Controller handling budget mutations (save, delete, copy/rollover).
class BudgetController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Saves a monthly budget with total limit and per-category limits.
  /// If a budget already exists for [yearMonth], it is updated atomically;
  /// otherwise, a new budget is created.
  Future<Budget> saveBudget({
    required String yearMonth,
    required int totalLimit,
    required Map<String, int> categoryLimits,
  }) async {
    state = const AsyncValue.loading();
    try {
      final budgetDao = ref.read(budgetDaoProvider);
      final existingBudget = await budgetDao.getBudgetForMonth(yearMonth);
      final budgetId = existingBudget?.id ?? IdGenerator.generate();
      final now = DateTime.now().toUtc();

      final budgetCompanion = BudgetsCompanion(
        id: Value(budgetId),
        yearMonth: Value(yearMonth),
        totalLimit: Value(totalLimit),
        createdAt: Value(existingBudget?.createdAt ?? now),
      );

      final categoryCompanions = categoryLimits.entries
          .where((entry) => entry.value > 0)
          .map((entry) => BudgetCategoriesCompanion(
                id: Value(IdGenerator.generate()),
                budgetId: Value(budgetId),
                categoryId: Value(entry.key),
                limitAmount: Value(entry.value),
              ))
          .toList();

      if (existingBudget != null) {
        await budgetDao.updateBudgetWithCategories(
          budgetCompanion,
          categoryCompanions,
        );
      } else {
        await budgetDao.insertBudgetWithCategories(
          budgetCompanion,
          categoryCompanions,
        );
      }

      final saved = await budgetDao.getBudgetForMonth(yearMonth);
      state = const AsyncValue.data(null);
      return saved!;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Deletes a budget and all its category limits by [budgetId].
  Future<void> deleteBudget(String budgetId) async {
    state = const AsyncValue.loading();
    try {
      final budgetDao = ref.read(budgetDaoProvider);
      await budgetDao.deleteBudget(budgetId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Copies budget limits from [fromYearMonth] to [toYearMonth] (monthly rollover).
  Future<bool> copyBudget({
    required String fromYearMonth,
    required String toYearMonth,
  }) async {
    state = const AsyncValue.loading();
    try {
      final budgetDao = ref.read(budgetDaoProvider);
      final newBudgetId = IdGenerator.generate();
      final success = await budgetDao.copyBudget(
        fromYearMonth: fromYearMonth,
        toYearMonth: toYearMonth,
        newBudgetId: newBudgetId,
        newCategoryLimitId: () => IdGenerator.generate(),
        createdAt: DateTime.now().toUtc(),
      );
      state = const AsyncValue.data(null);
      return success;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

/// Provider exposing [BudgetController] for budget mutations.
final budgetControllerProvider =
    AutoDisposeAsyncNotifierProvider<BudgetController, void>(
  BudgetController.new,
);

/// Provider for [BudgetService].
final budgetServiceProvider = Provider<BudgetService>((ref) {
  return BudgetService(
    budgetDao: ref.watch(budgetDaoProvider),
    transactionDao: ref.watch(transactionDaoProvider),
    categoryDao: ref.watch(categoryDaoProvider),
  );
});

/// Reactive stream of complete [MonthlyBudgetStatus] for [yearMonth],
/// including total budget, total spent, and category-level calculations.
final monthlyBudgetStatusProvider =
    StreamProvider.autoDispose.family<MonthlyBudgetStatus, String>((ref, yearMonth) {
  final service = ref.watch(budgetServiceProvider);
  return service.watchMonthlyBudgetStatus(yearMonth);
});

/// Parameter record for fetching an individual category's budget status.
typedef CategoryBudgetParams = ({String yearMonth, String categoryId});

/// Fetches [CategoryBudgetStatus] for a single category in [yearMonth].
final categoryBudgetStatusProvider =
    FutureProvider.autoDispose.family<CategoryBudgetStatus?, CategoryBudgetParams>(
        (ref, params) {
  final service = ref.watch(budgetServiceProvider);
  return service.getCategoryBudgetStatus(params.yearMonth, params.categoryId);
});

/// Streams [CategoryBudgetStatus] for a single category in [yearMonth].
final categoryBudgetStatusStreamProvider =
    StreamProvider.autoDispose.family<CategoryBudgetStatus?, CategoryBudgetParams>(
        (ref, params) {
  final service = ref.watch(budgetServiceProvider);
  return service.watchCategoryBudgetStatus(params.yearMonth, params.categoryId);
});

