import 'package:budget_tracker/database/app_database.dart';
import 'package:budget_tracker/database/converters/transaction_type.dart';
import 'package:budget_tracker/database/database_provider.dart';
import 'package:budget_tracker/features/transactions/providers/transactions_provider.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() async {
    db = AppDatabase.inMemory();
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
      ],
    );

    // Seed a category
    await db.categoryDao.insertCategory(
      CategoriesCompanion(
        id: const drift.Value('cat-food'),
        name: const drift.Value('Food'),
        icon: const drift.Value('restaurant'),
        color: const drift.Value(0xFF43A047),
        createdAt: drift.Value(DateTime.utc(2026, 10, 1)),
      ),
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('TransactionController deleteTransaction removes transaction and updates state', () async {
    await db.transactionDao.insertTransaction(
      TransactionsCompanion(
        id: const drift.Value('tx-to-delete'),
        amount: const drift.Value(25000),
        type: const drift.Value(TransactionType.expense),
        categoryId: const drift.Value('cat-food'),
        source: const drift.Value('Cash'),
        date: drift.Value(DateTime.utc(2026, 10, 15, 12, 0)),
        createdAt: drift.Value(DateTime.utc(2026, 10, 15, 12, 0)),
      ),
    );

    expect(await db.transactionDao.getTransactionById('tx-to-delete'), isNotNull);

    final controller = container.read(transactionControllerProvider.notifier);
    final success = await controller.deleteTransaction('tx-to-delete');

    expect(success, isTrue);
    expect(await db.transactionDao.getTransactionById('tx-to-delete'), isNull);
    expect(container.read(transactionControllerProvider), const AsyncData<void>(null));
  });

  test('groupedTransactionsProvider emits grouped transactions from database', () async {
    await db.transactionDao.insertTransaction(
      TransactionsCompanion(
        id: const drift.Value('tx-1'),
        amount: const drift.Value(50000),
        type: const drift.Value(TransactionType.expense),
        categoryId: const drift.Value('cat-food'),
        source: const drift.Value('BCA'),
        date: drift.Value(DateTime.utc(2026, 10, 15, 10, 0)),
        createdAt: drift.Value(DateTime.utc(2026, 10, 15, 10, 0)),
      ),
    );

    // Read the stream
    final initialGroups = await container.read(transactionsStreamProvider.future);
    expect(initialGroups.length, 1);
    expect(initialGroups.first.transaction.id, 'tx-1');

    final grouped = container.read(groupedTransactionsProvider);
    expect(grouped.value, isNotNull);
    expect(grouped.value!.length, 1);
    expect(grouped.value!.first.totalExpense, 50000);
  });
}
