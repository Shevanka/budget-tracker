import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/budget_categories.dart';
import '../tables/budgets.dart';

part 'budget_dao.g.dart';

@DriftAccessor(tables: [Budgets, BudgetCategories])
class BudgetDao extends DatabaseAccessor<AppDatabase> with _$BudgetDaoMixin {
  BudgetDao(super.db);

  /// Fetches the budget for a specific year_month ('YYYY-MM').
  Future<Budget?> getBudgetForMonth(String yearMonth) {
    return (select(budgets)..where((tbl) => tbl.yearMonth.equals(yearMonth)))
        .getSingleOrNull();
  }

  /// Streams the budget for a specific year_month ('YYYY-MM').
  Stream<Budget?> watchBudgetForMonth(String yearMonth) {
    return (select(budgets)..where((tbl) => tbl.yearMonth.equals(yearMonth)))
        .watchSingleOrNull();
  }

  /// Inserts a budget and its category limits atomically.
  Future<void> insertBudgetWithCategories(
    BudgetsCompanion budget,
    List<BudgetCategoriesCompanion> categoryLimits,
  ) {
    return transaction(() async {
      await into(budgets).insert(budget);
      if (categoryLimits.isNotEmpty) {
        await batch((batch) {
          batch.insertAll(budgetCategories, categoryLimits);
        });
      }
    });
  }

  /// Updates a budget and replaces its category limits atomically.
  Future<void> updateBudgetWithCategories(
    BudgetsCompanion budget,
    List<BudgetCategoriesCompanion> categoryLimits,
  ) {
    return transaction(() async {
      await update(budgets).replace(budget);
      await (delete(budgetCategories)
            ..where((tbl) => tbl.budgetId.equals(budget.id.value)))
          .go();
      if (categoryLimits.isNotEmpty) {
        await batch((batch) {
          batch.insertAll(budgetCategories, categoryLimits);
        });
      }
    });
  }

  /// Fetches all category limits for a specific budget.
  Future<List<BudgetCategory>> getBudgetCategories(String budgetId) {
    return (select(budgetCategories)
          ..where((tbl) => tbl.budgetId.equals(budgetId)))
        .get();
  }

  /// Streams all category limits for a specific budget.
  Stream<List<BudgetCategory>> watchBudgetCategories(String budgetId) {
    return (select(budgetCategories)
          ..where((tbl) => tbl.budgetId.equals(budgetId)))
        .watch();
  }

  /// Copies budget limits from [fromYearMonth] to [toYearMonth] (monthly rollover).
  /// Returns `true` if successfully copied, `false` if source not found or target already exists.
  Future<bool> copyBudget({
    required String fromYearMonth,
    required String toYearMonth,
    required String newBudgetId,
    required String Function() newCategoryLimitId,
    required DateTime createdAt,
  }) {
    return transaction(() async {
      final sourceBudget = await getBudgetForMonth(fromYearMonth);
      if (sourceBudget == null) {
        return false;
      }

      final existingTarget = await getBudgetForMonth(toYearMonth);
      if (existingTarget != null) {
        return false;
      }

      await into(budgets).insert(
        BudgetsCompanion(
          id: Value(newBudgetId),
          yearMonth: Value(toYearMonth),
          totalLimit: Value(sourceBudget.totalLimit),
          createdAt: Value(createdAt),
        ),
      );

      final sourceCategories = await getBudgetCategories(sourceBudget.id);
      if (sourceCategories.isNotEmpty) {
        final newCategories = sourceCategories
            .map(
              (cat) => BudgetCategoriesCompanion(
                id: Value(newCategoryLimitId()),
                budgetId: Value(newBudgetId),
                categoryId: Value(cat.categoryId),
                limitAmount: Value(cat.limitAmount),
              ),
            )
            .toList();

        await batch((batch) {
          batch.insertAll(budgetCategories, newCategories);
        });
      }

      return true;
    });
  }

  /// Deletes a budget and its category limits atomically.
  Future<void> deleteBudget(String budgetId) {
    return transaction(() async {
      await (delete(budgetCategories)
            ..where((tbl) => tbl.budgetId.equals(budgetId)))
          .go();
      await (delete(budgets)..where((tbl) => tbl.id.equals(budgetId))).go();
    });
  }
}
