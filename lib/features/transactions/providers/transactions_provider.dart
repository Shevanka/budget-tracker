import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// Controller handling transaction mutations (delete, undo, etc.).
class TransactionController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

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
}

/// Provider for [TransactionController].
final transactionControllerProvider =
    AutoDisposeAsyncNotifierProvider<TransactionController, void>(
  TransactionController.new,
);
