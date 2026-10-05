import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/id_generator.dart';
import '../../../database/app_database.dart';
import '../../../database/converters/transaction_type.dart';
import '../../../database/daos/transaction_dao.dart';
import '../../../database/database_provider.dart';
import '../domain/models/daily_transaction_group.dart';

/// Reactive stream of all transactions joined with their categories.
final transactionsStreamProvider =
    StreamProvider.autoDispose<List<TransactionWithCategory>>((ref) {
  final dao = ref.watch(transactionDaoProvider);
  return dao.watchTransactionsWithCategory();
});

/// Computes daily grouped transactions with daily totals from [transactionsStreamProvider].
final groupedTransactionsProvider =
    Provider.autoDispose<AsyncValue<List<DailyTransactionGroup>>>((ref) {
  final transactionsAsync = ref.watch(transactionsStreamProvider);
  return transactionsAsync.whenData(DailyTransactionGroup.fromTransactions);
});

/// Fetches a single transaction by its ID.
final transactionByIdProvider =
    FutureProvider.autoDispose.family<Transaction?, String>((ref, id) {
  final dao = ref.watch(transactionDaoProvider);
  return dao.getTransactionById(id);
});

/// Streams a single transaction by its ID.
final transactionStreamByIdProvider =
    StreamProvider.autoDispose.family<Transaction?, String>((ref, id) {
  final dao = ref.watch(transactionDaoProvider);
  return dao.watchTransactionById(id);
});

/// Controller handling transaction mutations (create, update, delete, restore).
class TransactionController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Inserts a new transaction with UTC timestamp and generated UUID v4.
  Future<Transaction?> createTransaction({
    required int amount,
    required TransactionType type,
    required String categoryId,
    required String source,
    required DateTime date,
    String? note,
  }) async {
    state = const AsyncValue.loading();
    try {
      final dao = ref.read(transactionDaoProvider);
      final id = IdGenerator.generate();
      final now = DateTime.now().toUtc();
      final entry = TransactionsCompanion(
        id: Value(id),
        amount: Value(amount),
        type: Value(type),
        categoryId: Value(categoryId),
        source: Value(source.trim()),
        date: Value(date.toUtc()),
        note: Value(note?.trim().isNotEmpty == true ? note!.trim() : null),
        createdAt: Value(now),
        updatedAt: const Value.absent(),
      );
      await dao.insertTransaction(entry);
      state = const AsyncValue.data(null);
      return dao.getTransactionById(id);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Updates an existing transaction with UTC timestamp and sets updatedAt.
  Future<bool> updateTransaction({
    required String id,
    required int amount,
    required TransactionType type,
    required String categoryId,
    required String source,
    required DateTime date,
    String? note,
  }) async {
    state = const AsyncValue.loading();
    try {
      final dao = ref.read(transactionDaoProvider);
      final existing = await dao.getTransactionById(id);
      if (existing == null) {
        state = AsyncValue.error('Transaction not found', StackTrace.current);
        return false;
      }
      final now = DateTime.now().toUtc();
      final entry = TransactionsCompanion(
        id: Value(id),
        amount: Value(amount),
        type: Value(type),
        categoryId: Value(categoryId),
        source: Value(source.trim()),
        date: Value(date.toUtc()),
        note: Value(note?.trim().isNotEmpty == true ? note!.trim() : null),
        createdAt: Value(existing.createdAt),
        updatedAt: Value(now),
      );
      final success = await dao.updateTransaction(entry);
      state = const AsyncValue.data(null);
      return success;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Deletes a transaction by id and returns whether it succeeded.
  Future<bool> deleteTransaction(String id) async {
    state = const AsyncValue.loading();
    try {
      final dao = ref.read(transactionDaoProvider);
      await dao.deleteTransaction(id);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Deletes a transaction by id and returns the deleted transaction object for undo.
  Future<Transaction?> deleteTransactionWithUndo(String id) async {
    state = const AsyncValue.loading();
    try {
      final dao = ref.read(transactionDaoProvider);
      final existing = await dao.getTransactionById(id);
      if (existing == null) {
        state = const AsyncValue.data(null);
        return null;
      }
      await dao.deleteTransaction(id);
      state = const AsyncValue.data(null);
      return existing;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Restores a previously deleted transaction with its original attributes.
  Future<bool> restoreTransaction(Transaction transaction) async {
    state = const AsyncValue.loading();
    try {
      final dao = ref.read(transactionDaoProvider);
      final entry = TransactionsCompanion(
        id: Value(transaction.id),
        amount: Value(transaction.amount),
        type: Value(transaction.type),
        categoryId: Value(transaction.categoryId),
        source: Value(transaction.source),
        date: Value(transaction.date),
        note: Value(transaction.note),
        createdAt: Value(transaction.createdAt),
        updatedAt: Value(transaction.updatedAt),
      );
      await dao.insertTransaction(entry);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

/// Provider for [TransactionController].
final transactionControllerProvider =
    AutoDisposeAsyncNotifierProvider<TransactionController, void>(
  TransactionController.new,
);
