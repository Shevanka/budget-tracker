import 'package:budget_tracker/database/app_database.dart';
import 'package:budget_tracker/database/converters/transaction_type.dart';
import 'package:budget_tracker/database/database_provider.dart';
import 'package:budget_tracker/features/alerts/providers/alerts_provider.dart';
import 'package:budget_tracker/features/alerts/services/budget_alert_service.dart';
import 'package:budget_tracker/features/transactions/providers/transactions_provider.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockBudgetAlertService extends Mock implements BudgetAlertService {}

void main() {
  late AppDatabase db;
  late MockBudgetAlertService mockAlertService;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(
      Transaction(
        id: 'dummy-tx',
        amount: 1000,
        type: TransactionType.expense,
        categoryId: 'cat-food',
        source: 'Cash',
        date: DateTime.utc(2026, 10, 1),
        createdAt: DateTime.utc(2026, 10, 1),
        updatedAt: null,
        note: null,
      ),
    );
  });

  setUp(() async {
    db = AppDatabase.inMemory();
    mockAlertService = MockBudgetAlertService();

    when(() => mockAlertService.checkAndAlertForTransaction(any()))
        .thenAnswer((_) async => []);

    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        budgetAlertServiceProvider.overrideWithValue(mockAlertService),
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

  test('TransactionController createTransaction inserts transaction with UUID v4 and UTC date', () async {
    final controller = container.read(transactionControllerProvider.notifier);
    final localDate = DateTime(2026, 10, 15, 14, 30);

    final created = await controller.createTransaction(
      amount: 75000,
      type: TransactionType.expense,
      categoryId: 'cat-food',
      source: 'BCA',
      date: localDate,
      note: 'Team Lunch',
    );

    expect(created, isNotNull);
    expect(created!.amount, 75000);
    expect(created.type, TransactionType.expense);
    expect(created.categoryId, 'cat-food');
    expect(created.source, 'BCA');
    expect(created.note, 'Team Lunch');
    expect(created.date.isUtc, isTrue);
    expect(created.date, localDate.toUtc());
    expect(created.createdAt.isUtc, isTrue);
    // UUID v4 format verification
    expect(
      RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')
          .hasMatch(created.id),
      isTrue,
    );

    // Verify alert service was triggered for expense transaction
    verify(() => mockAlertService.checkAndAlertForTransaction(any(
          that: isA<Transaction>().having((t) => t.id, 'id', created.id),
        ))).called(1);

    // Verify accessible via transactionByIdProvider
    final fetched = await container.read(transactionByIdProvider(created.id).future);
    expect(fetched, isNotNull);
    expect(fetched!.id, created.id);
  });

  test('TransactionController createTransaction skips alert check for income transactions', () async {
    final controller = container.read(transactionControllerProvider.notifier);

    final created = await controller.createTransaction(
      amount: 10000000,
      type: TransactionType.income,
      categoryId: 'cat-food',
      source: 'Salary',
      date: DateTime.utc(2026, 10, 1),
      note: 'Monthly Salary',
    );

    expect(created, isNotNull);
    expect(created!.type, TransactionType.income);
    verifyNever(() => mockAlertService.checkAndAlertForTransaction(any()));
  });

  test('TransactionController updateTransaction updates fields, sets updatedAt, and triggers alert for expense', () async {
    final controller = container.read(transactionControllerProvider.notifier);
    final created = await controller.createTransaction(
      amount: 30000,
      type: TransactionType.expense,
      categoryId: 'cat-food',
      source: 'Cash',
      date: DateTime.utc(2026, 10, 10),
      note: 'Initial Note',
    );

    expect(created, isNotNull);
    expect(created!.updatedAt, isNull);
    clearInteractions(mockAlertService);

    final success = await controller.updateTransaction(
      id: created.id,
      amount: 45000,
      type: TransactionType.expense,
      categoryId: 'cat-food',
      source: 'GoPay',
      date: DateTime.utc(2026, 10, 11),
      note: 'Updated Note',
    );

    expect(success, isTrue);

    final updated = await db.transactionDao.getTransactionById(created.id);
    expect(updated, isNotNull);
    expect(updated!.amount, 45000);
    expect(updated.type, TransactionType.expense);
    expect(updated.source, 'GoPay');
    expect(updated.note, 'Updated Note');
    expect(updated.updatedAt, isNotNull);
    expect(updated.updatedAt!.isUtc, isTrue);

    verify(() => mockAlertService.checkAndAlertForTransaction(any(
          that: isA<Transaction>().having((t) => t.id, 'id', created.id),
        ))).called(1);
  });

  test('TransactionController createTransaction succeeds even if alert service throws', () async {
    when(() => mockAlertService.checkAndAlertForTransaction(any()))
        .thenThrow(Exception('Notification platform channel failed'));

    final controller = container.read(transactionControllerProvider.notifier);
    final created = await controller.createTransaction(
      amount: 50000,
      type: TransactionType.expense,
      categoryId: 'cat-food',
      source: 'Cash',
      date: DateTime.utc(2026, 10, 15),
      note: 'Coffee',
    );

    expect(created, isNotNull);
    expect(await db.transactionDao.getTransactionById(created!.id), isNotNull);
  });

  test('TransactionController deleteTransactionWithUndo and restoreTransaction works seamlessly', () async {
    final controller = container.read(transactionControllerProvider.notifier);
    final created = await controller.createTransaction(
      amount: 20000,
      type: TransactionType.expense,
      categoryId: 'cat-food',
      source: 'OVO',
      date: DateTime.utc(2026, 10, 12),
      note: 'Snack',
    );

    expect(created, isNotNull);

    // Delete with undo
    final deleted = await controller.deleteTransactionWithUndo(created!.id);
    expect(deleted, isNotNull);
    expect(deleted!.id, created.id);
    expect(await db.transactionDao.getTransactionById(created.id), isNull);

    clearInteractions(mockAlertService);

    // Restore
    final restored = await controller.restoreTransaction(deleted);
    expect(restored, isTrue);

    final retrieved = await db.transactionDao.getTransactionById(created.id);
    expect(retrieved, isNotNull);
    expect(retrieved!.id, created.id);
    expect(retrieved.amount, 20000);
    expect(retrieved.source, 'OVO');

    // Restoring expense re-checks alert
    verify(() => mockAlertService.checkAndAlertForTransaction(any(
          that: isA<Transaction>().having((t) => t.id, 'id', created.id),
        ))).called(1);
  });
}
