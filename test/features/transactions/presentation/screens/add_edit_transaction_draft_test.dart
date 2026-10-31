import 'package:budget_tracker/database/app_database.dart';
import 'package:budget_tracker/database/converters/transaction_type.dart';
import 'package:budget_tracker/database/database_provider.dart';
import 'package:budget_tracker/features/categories/providers/categories_provider.dart';
import 'package:budget_tracker/features/transactions/presentation/screens/add_edit_transaction_screen.dart';
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
  });

  tearDown(() async {
    await db.close();
  });

  group('AddEditTransactionScreen - Pre-filled Draft Mode', () {
    testWidgets('pre-fills fields and marks notification log as parsed upon save', (tester) async {
      await db.notificationLogDao.insertLog(
        NotificationLogsCompanion(
          id: const drift.Value('log-draft-1'),
          appPackage: const drift.Value('com.bca'),
          title: const drift.Value('m-BCA'),
          body: const drift.Value('Pembelian di INDOMARET Rp 45.000,00'),
          receivedAt: drift.Value(DateTime.utc(2026, 10, 30)),
        ),
      );

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const AddEditTransactionScreen(
              initialAmount: 45000,
              initialSource: 'BCA',
              initialCategoryId: 'cat-food',
              initialNote: 'INDOMARET',
              notificationLogId: 'log-draft-1',
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            activeCategoriesProvider.overrideWith(
              (ref) => Stream.value([foodCategory]),
            ),
            activeCategoriesByTypeProvider(TransactionType.expense).overrideWith(
              (ref) => Stream.value([foodCategory]),
            ),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('45.000'), findsOneWidget);
      expect(find.text('BCA'), findsWidgets);
      expect(find.text('INDOMARET'), findsOneWidget);

      // Ensure Save button is visible
      final saveButton = find.widgetWithText(FilledButton, 'Save Transaction');
      await tester.ensureVisible(saveButton);
      await tester.pumpAndSettle();

      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      final allTx = await db.transactionDao.getTransactionsWithCategory();
      expect(allTx.length, 1);
      expect(allTx.first.transaction.amount, 45000);
      expect(allTx.first.transaction.source, 'BCA');
      expect(allTx.first.transaction.note, 'INDOMARET');

      final log = await db.notificationLogDao.getLogById('log-draft-1');
      expect(log!.parsed, isTrue);
      expect(log.transactionId, allTx.first.transaction.id);
    });
  });
}
