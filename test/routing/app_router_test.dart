import 'package:budget_tracker/app.dart';
import 'package:budget_tracker/database/app_database.dart';
import 'package:budget_tracker/database/database_provider.dart';
import 'package:budget_tracker/features/categories/providers/categories_provider.dart';
import 'package:budget_tracker/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:budget_tracker/features/transactions/presentation/screens/add_edit_transaction_screen.dart';
import 'package:budget_tracker/features/transactions/presentation/screens/transactions_screen.dart';
import 'package:budget_tracker/features/transactions/providers/transactions_provider.dart';
import 'package:budget_tracker/routing/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.inMemory();
  });

  tearDown(() async {
    await db.close();
  });

  Widget createTestApp() {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        groupedTransactionsProvider.overrideWithValue(
          const AsyncValue.data([]),
        ),
        activeCategoriesProvider.overrideWith(
          (ref) => Stream.value([]),
        ),
        activeCategoriesByTypeProvider.overrideWith(
          (ref, type) => Stream.value([]),
        ),
        transactionByIdProvider.overrideWith(
          (ref, id) => Future.value(null),
        ),
      ],
      child: const BudgetTrackerApp(),
    );
  }

  group('Bottom Navigation Tab Switching', () {
    testWidgets('switches to Transactions tab on tap', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Dashboard Overview'), findsOneWidget);

      await tester.tap(find.text('Transactions'));
      await tester.pumpAndSettle();

      expect(find.byType(TransactionsScreen), findsOneWidget);
      expect(find.text('No transactions yet'), findsOneWidget);
    });

    testWidgets('switches to Reports tab on tap', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reports'));
      await tester.pumpAndSettle();

      expect(find.text('Spending Analytics'), findsOneWidget);
    });

    testWidgets('switches to Settings tab on tap', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(find.text('Categories'), findsOneWidget);
      expect(find.text('Budget Setup'), findsOneWidget);
      expect(find.text('Smart Recording Review'), findsOneWidget);
    });
  });

  group('Pushed Routes Navigation', () {
    testWidgets('navigates to Add Transaction screen', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Tap "Add Transaction" on Dashboard
      await tester.tap(find.text('Add Transaction').first);
      await tester.pumpAndSettle();

      expect(find.byType(AddEditTransactionScreen), findsOneWidget);
      expect(find.text('Add Transaction'), findsWidgets);
    });

    testWidgets('navigates to Budget Setup screen', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Setup Budget'));
      await tester.pumpAndSettle();

      expect(find.text('Monthly Budget Setup'), findsOneWidget);
    });

    testWidgets('navigates to Category Manager from Settings', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Categories'));
      await tester.pumpAndSettle();

      expect(find.text('Category Management'), findsOneWidget);
    });

    testWidgets('navigates to Smart Recording Review from Settings', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Smart Recording Review'));
      await tester.pumpAndSettle();

      expect(find.text('Draft Transactions Review'), findsOneWidget);
    });

    testWidgets('navigates to Edit Transaction with parameter', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final BuildContext context =
          tester.element(find.byType(DashboardScreen));
      context.push(AppRoute.editTransaction.path.replaceAll(':id', 'tx-123'));
      await tester.pumpAndSettle();

      expect(find.byType(AddEditTransactionScreen), findsOneWidget);
      expect(find.text('Edit Transaction'), findsOneWidget);
    });

    testWidgets('navigates to Receipt Picker screen', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final BuildContext context =
          tester.element(find.byType(DashboardScreen));
      context.push(AppRoute.receiptPicker.path);
      await tester.pumpAndSettle();

      expect(find.text('Scan Receipt'), findsOneWidget);
      expect(find.text('Receipt Scanner'), findsOneWidget);
    });
  });
}
