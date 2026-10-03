import 'package:drift/drift.dart';
import 'budgets.dart';
import 'categories.dart';

/// Per-category limits for a monthly budget.
/// Enforces unique (budgetId, categoryId) pairing.
class BudgetCategories extends Table {
  TextColumn get id => text()();
  TextColumn get budgetId => text().references(Budgets, #id)();
  TextColumn get categoryId => text().references(Categories, #id)();
  IntColumn get limitAmount => integer()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {budgetId, categoryId},
      ];
}
