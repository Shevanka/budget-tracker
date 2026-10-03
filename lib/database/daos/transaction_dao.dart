import 'package:drift/drift.dart';
import '../app_database.dart';
import '../converters/transaction_type.dart';
import '../tables/categories.dart';
import '../tables/transactions.dart';

part 'transaction_dao.g.dart';

@DriftAccessor(tables: [Transactions, Categories])
class TransactionDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionDaoMixin {
  TransactionDao(super.db);

  /// Inserts a new transaction.
  Future<int> insertTransaction(TransactionsCompanion entry) {
    return into(transactions).insert(entry);
  }

  /// Updates an existing transaction.
  Future<bool> updateTransaction(TransactionsCompanion entry) {
    return update(transactions).replace(entry);
  }

  /// Deletes a transaction by id.
  Future<int> deleteTransaction(String id) {
    return (delete(transactions)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// Fetches a transaction by id.
  Future<Transaction?> getTransactionById(String id) {
    return (select(transactions)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  /// Streams recent transactions ordered by date descending, then createdAt descending.
  Stream<List<Transaction>> watchRecentTransactions({int limit = 5}) {
    return (select(transactions)
          ..orderBy([
            (tbl) =>
                OrderingTerm(expression: tbl.date, mode: OrderingMode.desc),
            (tbl) =>
                OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.desc),
          ])
          ..limit(limit))
        .watch();
  }

  /// Streams transactions within a date range (inclusive), ordered by date descending.
  Stream<List<Transaction>> watchTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) {
    return (select(transactions)
          ..where(
            (tbl) =>
                tbl.date.isBiggerOrEqualValue(start) &
                tbl.date.isSmallerOrEqualValue(end),
          )
          ..orderBy([
            (tbl) =>
                OrderingTerm(expression: tbl.date, mode: OrderingMode.desc),
            (tbl) =>
                OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  /// Fetches transactions within a date range (inclusive), ordered by date descending.
  Future<List<Transaction>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) {
    return (select(transactions)
          ..where(
            (tbl) =>
                tbl.date.isBiggerOrEqualValue(start) &
                tbl.date.isSmallerOrEqualValue(end),
          )
          ..orderBy([
            (tbl) =>
                OrderingTerm(expression: tbl.date, mode: OrderingMode.desc),
            (tbl) =>
                OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  /// Fetches transactions for a specific category.
  Future<List<Transaction>> getTransactionsByCategory(String categoryId) {
    return (select(transactions)
          ..where((tbl) => tbl.categoryId.equals(categoryId))
          ..orderBy([
            (tbl) =>
                OrderingTerm(expression: tbl.date, mode: OrderingMode.desc),
          ]))
        .get();
  }

  /// Calculates total spent (expense only) for a specific category in a date range.
  Future<int> getTotalSpentForCategory(
    String categoryId,
    DateTime start,
    DateTime end,
  ) async {
    final sumExp = transactions.amount.sum();
    final query = selectOnly(transactions)
      ..where(
        transactions.categoryId.equals(categoryId) &
            transactions.type.equalsValue(TransactionType.expense) &
            transactions.date.isBiggerOrEqualValue(start) &
            transactions.date.isSmallerOrEqualValue(end),
      )
      ..addColumns([sumExp]);

    final result = await query.map((row) => row.read(sumExp)).getSingle();
    return result ?? 0;
  }

  /// Calculates total spent (all expenses) in a date range.
  Future<int> getTotalSpent(DateTime start, DateTime end) async {
    final sumExp = transactions.amount.sum();
    final query = selectOnly(transactions)
      ..where(
        transactions.type.equalsValue(TransactionType.expense) &
            transactions.date.isBiggerOrEqualValue(start) &
            transactions.date.isSmallerOrEqualValue(end),
      )
      ..addColumns([sumExp]);

    final result = await query.map((row) => row.read(sumExp)).getSingle();
    return result ?? 0;
  }

  /// Calculates total income in a date range.
  Future<int> getTotalIncome(DateTime start, DateTime end) async {
    final sumExp = transactions.amount.sum();
    final query = selectOnly(transactions)
      ..where(
        transactions.type.equalsValue(TransactionType.income) &
            transactions.date.isBiggerOrEqualValue(start) &
            transactions.date.isSmallerOrEqualValue(end),
      )
      ..addColumns([sumExp]);

    final result = await query.map((row) => row.read(sumExp)).getSingle();
    return result ?? 0;
  }
}
