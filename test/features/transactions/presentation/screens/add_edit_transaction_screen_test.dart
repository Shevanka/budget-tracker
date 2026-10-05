import 'package:budget_tracker/database/app_database.dart';
import 'package:budget_tracker/database/converters/transaction_type.dart';
import 'package:budget_tracker/database/database_provider.dart';
import 'package:budget_tracker/features/categories/providers/categories_provider.dart';
import 'package:budget_tracker/features/transactions/presentation/screens/add_edit_transaction_screen.dart';
import 'package:budget_tracker/routing/app_routes.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  late AppDatabase db;

  final foodCategory = Category(
    id: 'cat-food',
    name: 'Food',
    icon: 'restaurant',
    color: 0xFF43A047,
    type: TransactionType.expense,
    isDefault: true,
    isActive: true,
    sortOrder: 0,
    createdAt: DateTime.utc(2026, 10, 1),
  );

  final transportCategory = Category(
    id: 'cat-transport',
    name: 'Transport',
    icon: 'directions_car',
    color: 0xFF1E88E5,
    type: TransactionType.expense,
    isDefault: true,
    isActive: true,
    sortOrder: 1,
    createdAt: DateTime.utc(2026, 10, 1),
  );

  final salaryCategory = Category(
    id: 'cat-salary',
    name: 'Salary',
    icon: 'payments',
    color: 0xFF2E7D32,
    type: TransactionType.income,
    isDefault: true,
    isActive: true,
    sortOrder: 0,
    createdAt: DateTime.utc(2026, 10, 1),
  );

  setUp(() async {
    db = AppDatabase.inMemory();
    await db.categoryDao.insertCategory(
      CategoriesCompanion(
        id: drift.Value(foodCategory.id),
        name: drift.Value(foodCategory.name),
        icon: drift.Value(foodCategory.icon),
        color: drift.Value(foodCategory.color),
        type: drift.Value(foodCategory.type),
        createdAt: drift.Value(foodCategory.createdAt),
      ),
    );
    await db.categoryDao.insertCategory(
      CategoriesCompanion(
        id: drift.Value(transportCategory.id),
        name: drift.Value(transportCategory.name),
        icon: drift.Value(transportCategory.icon),
        color: drift.Value(transportCategory.color),
        type: drift.Value(transportCategory.type),
        createdAt: drift.Value(transportCategory.createdAt),
      ),
    );
    await db.categoryDao.insertCategory(
      CategoriesCompanion(
        id: drift.Value(salaryCategory.id),
        name: drift.Value(salaryCategory.name),
        icon: drift.Value(salaryCategory.icon),
        color: drift.Value(salaryCategory.color),
        type: drift.Value(salaryCategory.type),
        createdAt: drift.Value(salaryCategory.createdAt),
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  Widget createTestWidget({
    String? transactionId,
  }) {
    final router = GoRouter(
      initialLocation: AppRoute.transactions.path,
      routes: [
        GoRoute(
          path: AppRoute.transactions.path,
          builder: (context, state) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  if (transactionId != null) {
                    context.push(
                      AppRoute.editTransaction.path.replaceAll(':id', transactionId),
                    );
                  } else {
                    context.push(AppRoute.addTransaction.path);
                  }
                },
                child: const Text('Open Add/Edit'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: AppRoute.addTransaction.path,
          builder: (context, state) => const AddEditTransactionScreen(),
        ),
        GoRoute(
          path: AppRoute.editTransaction.path,
          builder: (context, state) {
            final id = state.pathParameters['id'];
            return AddEditTransactionScreen(transactionId: id);
          },
        ),
        GoRoute(
          path: AppRoute.receiptPicker.path,
          builder: (context, state) => const Scaffold(
            body: Text('Receipt Picker Target'),
          ),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        activeCategoriesProvider.overrideWith(
          (ref) => Stream.value([foodCategory, transportCategory, salaryCategory]),
        ),
        activeCategoriesByTypeProvider.overrideWith(
          (ref, type) => Stream.value(
            [foodCategory, transportCategory, salaryCategory]
                .where((c) => c.type == type)
                .toList(),
          ),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  Future<void> pumpScreen(WidgetTester tester, {String? transactionId}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestWidget(transactionId: transactionId));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Add/Edit'));
    await tester.pumpAndSettle();
  }

  group('AddEditTransactionScreen - Add Mode', () {
    testWidgets('renders add transaction form fields and default values', (tester) async {
      await pumpScreen(tester);

      expect(find.text('Add Transaction'), findsOneWidget);
      expect(find.text('Expense'), findsOneWidget);
      expect(find.text('Income'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Amount'), findsOneWidget);
      expect(find.text('Select a category'), findsOneWidget);
      expect(find.text('Cash'), findsWidgets); // Default source text & chip
      expect(find.text('Transaction Date'), findsOneWidget);
      expect(find.text('Scan Receipt (OCR)'), findsOneWidget);
      expect(find.text('Save Transaction'), findsOneWidget);
    });

    testWidgets('validates required fields on empty submit', (tester) async {
      await pumpScreen(tester);

      // Tap save without filling amount or category
      await tester.tap(find.text('Save Transaction'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter an amount'), findsOneWidget);
      expect(find.text('Please select a category'), findsOneWidget);
    });

    testWidgets('validates zero amount as invalid', (tester) async {
      await pumpScreen(tester);

      // Enter '0'
      await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), '0');
      await tester.tap(find.text('Save Transaction'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid amount greater than 0'), findsOneWidget);
    });

    testWidgets('source quick chip updates source text field', (tester) async {
      await pumpScreen(tester);

      // Tap 'BCA' chip
      await tester.tap(find.widgetWithText(ChoiceChip, 'BCA'));
      await tester.pumpAndSettle();

      final sourceField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Payment Method / Source'),
      );
      expect(sourceField.controller?.text, 'BCA');
    });

    testWidgets('navigates to receipt picker when scan receipt is tapped', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text('Scan Receipt (OCR)'));
      await tester.pumpAndSettle();

      expect(find.text('Receipt Picker Target'), findsOneWidget);
    });

    testWidgets('clears selected category when switching between transaction types', (tester) async {
      await pumpScreen(tester);

      // Select expense category Food
      await tester.tap(find.text('Select a category'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Food'));
      await tester.pumpAndSettle();
      expect(find.text('Food'), findsOneWidget);

      // Switch to Income
      await tester.tap(find.text('Income'));
      await tester.pumpAndSettle();

      // Food should be cleared and reset to prompt
      expect(find.text('Select a category'), findsOneWidget);
      expect(find.text('Food'), findsNothing);
    });

    testWidgets('successfully creates an expense transaction with category and amount', (tester) async {
      await pumpScreen(tester);

      // Enter amount: 50.000
      await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), '50000');

      // Select category
      await tester.tap(find.text('Select a category'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Food'));
      await tester.pumpAndSettle();

      // Enter note
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Note (Optional)'),
        'Dinner with friends',
      );

      // Save
      await tester.tap(find.text('Save Transaction'));
      await tester.pumpAndSettle();

      // Verify transaction in DB
      final transactions = await db.transactionDao.getTransactionsWithCategory();
      expect(transactions.length, 1);
      final created = transactions.first.transaction;
      expect(created.amount, 50000);
      expect(created.type, TransactionType.expense);
      expect(created.categoryId, 'cat-food');
      expect(created.source, 'Cash');
      expect(created.note, 'Dinner with friends');

      // Returns to list and shows snackbar
      expect(find.text('Transaction saved'), findsOneWidget);
      expect(find.text('Open Add/Edit'), findsOneWidget);
    });

    testWidgets('successfully creates an income transaction', (tester) async {
      await pumpScreen(tester);

      // Switch to Income
      await tester.tap(find.text('Income'));
      await tester.pumpAndSettle();

      // Enter amount: 5.000.000
      await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), '5000000');

      // Select category Salary
      await tester.tap(find.text('Select a category'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salary'));
      await tester.pumpAndSettle();

      // Tap Mandiri chip
      await tester.tap(find.widgetWithText(ChoiceChip, 'Mandiri'));
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.text('Save Transaction'));
      await tester.pumpAndSettle();

      final transactions = await db.transactionDao.getTransactionsWithCategory();
      expect(transactions.length, 1);
      final created = transactions.first.transaction;
      expect(created.amount, 5000000);
      expect(created.type, TransactionType.income);
      expect(created.categoryId, 'cat-salary');
      expect(created.source, 'Mandiri');

      // Returns to list and shows snackbar
      expect(find.text('Transaction saved'), findsOneWidget);
      expect(find.text('Open Add/Edit'), findsOneWidget);
    });
  });

  group('AddEditTransactionScreen - Edit Mode', () {
    const existingTxId = 'tx-edit-1';

    setUp(() async {
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value(existingTxId),
          amount: const drift.Value(75000),
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value('cat-food'),
          source: const drift.Value('GoPay'),
          date: drift.Value(DateTime.utc(2026, 10, 10, 12, 0)),
          createdAt: drift.Value(DateTime.utc(2026, 10, 10, 12, 0)),
          note: const drift.Value('Initial Lunch'),
        ),
      );
    });

    testWidgets('loads and pre-populates existing transaction', (tester) async {
      await pumpScreen(tester, transactionId: existingTxId);

      expect(find.text('Edit Transaction'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Update Transaction'), findsOneWidget);

      final amountField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Amount'),
      );
      expect(amountField.controller?.text, '75.000');

      final sourceField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Payment Method / Source'),
      );
      expect(sourceField.controller?.text, 'GoPay');

      final noteField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Note (Optional)'),
      );
      expect(noteField.controller?.text, 'Initial Lunch');
    });

    testWidgets('updates existing transaction and sets updatedAt', (tester) async {
      await pumpScreen(tester, transactionId: existingTxId);

      // Change amount to 90.000
      await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), '90000');

      // Change category to Transport
      await tester.tap(find.text('Food'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Transport'));
      await tester.pumpAndSettle();

      // Update
      await tester.tap(find.text('Update Transaction'));
      await tester.pumpAndSettle();

      final updated = await db.transactionDao.getTransactionById(existingTxId);
      expect(updated, isNotNull);
      expect(updated!.amount, 90000);
      expect(updated.categoryId, 'cat-transport');
      expect(updated.updatedAt, isNotNull);

      // Returns to list and shows snackbar
      expect(find.text('Transaction updated'), findsOneWidget);
      expect(find.text('Open Add/Edit'), findsOneWidget);
    });

    testWidgets('delete transaction shows confirmation dialog and allows cancel', (tester) async {
      await pumpScreen(tester, transactionId: existingTxId);

      // Tap delete icon
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('Delete Transaction'), findsWidgets);
      expect(
        find.text('Are you sure you want to delete this transaction?'),
        findsOneWidget,
      );

      // Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Not deleted
      expect(await db.transactionDao.getTransactionById(existingTxId), isNotNull);
    });

    testWidgets('delete transaction confirms, deletes, and restores via undo snackbar', (tester) async {
      await pumpScreen(tester, transactionId: existingTxId);

      // Tap delete icon
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      // Tap Delete in dialog
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      // Transaction is deleted
      expect(await db.transactionDao.getTransactionById(existingTxId), isNull);
      expect(find.text('Transaction deleted'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);

      // Tap Undo
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      // Transaction is restored
      final restored = await db.transactionDao.getTransactionById(existingTxId);
      expect(restored, isNotNull);
      expect(restored!.amount, 75000);
    });
  });
}
