import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';
import 'daos/budget_dao.dart';
import 'daos/category_dao.dart';
import 'daos/notification_log_dao.dart';
import 'daos/transaction_dao.dart';

/// Central provider for [AppDatabase].
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Provider for [CategoryDao].
final categoryDaoProvider = Provider<CategoryDao>((ref) {
  return ref.watch(databaseProvider).categoryDao;
});

/// Provider for [TransactionDao].
final transactionDaoProvider = Provider<TransactionDao>((ref) {
  return ref.watch(databaseProvider).transactionDao;
});

/// Provider for [BudgetDao].
final budgetDaoProvider = Provider<BudgetDao>((ref) {
  return ref.watch(databaseProvider).budgetDao;
});

/// Provider for [NotificationLogDao].
final notificationLogDaoProvider = Provider<NotificationLogDao>((ref) {
  return ref.watch(databaseProvider).notificationLogDao;
});
