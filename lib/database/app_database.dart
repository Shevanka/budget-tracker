import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'converters/transaction_type.dart';
import 'daos/budget_dao.dart';
import 'daos/category_dao.dart';
import 'daos/notification_log_dao.dart';
import 'daos/transaction_dao.dart';
import 'tables/budget_categories.dart';
import 'tables/budgets.dart';
import 'tables/categories.dart';
import 'tables/notification_logs.dart';
import 'tables/transactions.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Categories,
    Transactions,
    Budgets,
    BudgetCategories,
    NotificationLogs,
  ],
  daos: [
    CategoryDao,
    TransactionDao,
    BudgetDao,
    NotificationLogDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  /// In-memory database constructor for testing.
  AppDatabase.inMemory([QueryExecutor? e])
      : super(e ?? NativeDatabase.memory());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'budget_tracker');
  }
}
