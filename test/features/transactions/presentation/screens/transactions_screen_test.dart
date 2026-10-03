import 'package:budget_tracker/database/app_database.dart';
import 'package:budget_tracker/database/converters/transaction_type.dart';
import 'package:budget_tracker/database/daos/transaction_dao.dart';
import 'package:budget_tracker/features/transactions/domain/models/daily_transaction_group.dart';
import 'package:budget_tracker/features/transactions/presentation/screens/transactions_screen.dart';
import 'package:budget_tracker/features/transactions/presentation/widgets/daily_group_header.dart';
import 'package:budget_tracker/features/transactions/presentation/widgets/transaction_list_tile.dart';
import 'package:budget_tracker/features/transactions/presentation/widgets/transactions_empty_state.dart';
import 'package:budget_tracker/features/transactions/providers/transactions_provider.dart';
import 'package:budget_tracker/routing/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  final testCategory = Category(
    id: 'cat-food',
    name: 'Food & Dining',
    icon: 'restaurant',
    color: 0xFF43A047,
    isDefault: true,
    isActive: true,
    sortOrder: 0,
    createdAt: DateTime.utc(2026, 10, 1),
  );

  final testIncomeCategory = Category(
    id: 'cat-salary',
    name: 'Salary',
    icon: 'attach_money',
    color: 0xFF2E7D32,
    isDefault: true,
    isActive: true,
    sortOrder: 1,
    createdAt: DateTime.utc(2026, 10, 1),
  );

  Widget createTestWidget({
    required AsyncValue<List<DailyTransactionGroup>> groupedState,
    List<RouteBase>? additionalRoutes,
  }) {
    final router = GoRouter(
      initialLocation: AppRoute.transactions.path,
      routes: [
        GoRoute(
          path: AppRoute.transactions.path,
          builder: (context, state) => const TransactionsScreen(),
        ),
        GoRoute(
          path: AppRoute.addTransaction.path,
          builder: (context, state) => const Scaffold(
            body: Text('Add Transaction Screen Target'),
          ),
        ),
        GoRoute(
          path: AppRoute.editTransaction.path,
          builder: (context, state) => Scaffold(
            body: Text(
              'Edit Transaction Screen Target (${state.pathParameters['id']})',
            ),
          ),
        ),
        ...?additionalRoutes,
      ],
    );

    return ProviderScope(
      overrides: [
        groupedTransactionsProvider.overrideWithValue(groupedState),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  group('TransactionsScreen Presentation', () {
    testWidgets('renders empty state when no transactions exist', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          groupedState: const AsyncValue.data([]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TransactionsEmptyState), findsOneWidget);
      expect(find.text('No transactions yet'), findsOneWidget);
      expect(
        find.text('Tap + to record your first income or expense.'),
        findsOneWidget,
      );
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('empty state button navigates to add transaction screen', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          groupedState: const AsyncValue.data([]),
        ),
      );
      await tester.pumpAndSettle();

      // Find the "Add Transaction" button inside TransactionsEmptyState
      final emptyStateButton = find.descendant(
        of: find.byType(TransactionsEmptyState),
        matching: find.text('Add Transaction'),
      );
      expect(emptyStateButton, findsOneWidget);

      await tester.tap(emptyStateButton);
      await tester.pumpAndSettle();

      expect(find.text('Add Transaction Screen Target'), findsOneWidget);
    });

    testWidgets('FAB navigates to add transaction screen', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          groupedState: const AsyncValue.data([]),
        ),
      );
      await tester.pumpAndSettle();

      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);

      await tester.tap(fab);
      await tester.pumpAndSettle();

      expect(find.text('Add Transaction Screen Target'), findsOneWidget);
    });

    testWidgets('renders loading state with progress indicator', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          groupedState: const AsyncValue.loading(),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders error state on error', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          groupedState: const AsyncValue.error('Database failure', StackTrace.empty),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Failed to load transactions'), findsOneWidget);
      expect(find.text('Database failure'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('renders date-grouped transactions with daily totals and details', (tester) async {
      final now = DateTime.now();
      final todayDate = DateTime(now.year, now.month, now.day);
      final yesterdayDate = todayDate.subtract(const Duration(days: 1));

      final todayGroup = DailyTransactionGroup(
        date: todayDate,
        items: [
          TransactionWithCategory(
            transaction: Transaction(
              id: 'tx-1',
              amount: 50000,
              type: TransactionType.expense,
              categoryId: 'cat-food',
              source: 'BCA',
              date: DateTime(todayDate.year, todayDate.month, todayDate.day, 12, 30).toUtc(),
              createdAt: DateTime(todayDate.year, todayDate.month, todayDate.day, 12, 30).toUtc(),
              note: 'Lunch at Cafe',
            ),
            category: testCategory,
          ),
          TransactionWithCategory(
            transaction: Transaction(
              id: 'tx-2',
              amount: 1500000,
              type: TransactionType.income,
              categoryId: 'cat-salary',
              source: 'Mandiri',
              date: DateTime(todayDate.year, todayDate.month, todayDate.day, 9, 0).toUtc(),
              createdAt: DateTime(todayDate.year, todayDate.month, todayDate.day, 9, 0).toUtc(),
              note: 'Bonus',
            ),
            category: testIncomeCategory,
          ),
        ],
        totalExpense: 50000,
        totalIncome: 1500000,
      );

      final yesterdayGroup = DailyTransactionGroup(
        date: yesterdayDate,
        items: [
          TransactionWithCategory(
            transaction: Transaction(
              id: 'tx-3',
              amount: 35000,
              type: TransactionType.expense,
              categoryId: 'cat-food',
              source: 'GoPay',
              date: DateTime(yesterdayDate.year, yesterdayDate.month, yesterdayDate.day, 19, 15).toUtc(),
              createdAt: DateTime(yesterdayDate.year, yesterdayDate.month, yesterdayDate.day, 19, 15).toUtc(),
              note: null,
            ),
            category: testCategory,
          ),
        ],
        totalExpense: 35000,
        totalIncome: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          groupedState: AsyncValue.data([todayGroup, yesterdayGroup]),
        ),
      );
      await tester.pumpAndSettle();

      // Headers
      expect(find.byType(DailyGroupHeader), findsNWidgets(2));
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Yesterday'), findsOneWidget);

      // Daily totals formatted in headers
      expect(find.text('-Rp 50.000'), findsWidgets);
      expect(find.text('+Rp 1.500.000'), findsWidgets);
      expect(find.text('-Rp 35.000'), findsWidgets);

      // Transaction items
      expect(find.byType(TransactionListTile), findsNWidgets(3));
      expect(find.text('Lunch at Cafe'), findsOneWidget);
      expect(find.text('Bonus'), findsOneWidget);
      expect(find.text('Food & Dining'), findsWidgets); // Used as title when note is null

      // Tap on a transaction item navigates to edit screen with ID
      await tester.tap(find.text('Lunch at Cafe'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Transaction Screen Target (tx-1)'), findsOneWidget);
    });

    testWidgets('TransactionListTile shows correct category fallback and colors', (tester) async {
      final now = DateTime.now();
      final uncategorizedGroup = DailyTransactionGroup(
        date: DateTime(now.year, now.month, now.day),
        items: [
          TransactionWithCategory(
            transaction: Transaction(
              id: 'tx-no-cat',
              amount: 10000,
              type: TransactionType.expense,
              categoryId: 'cat-nonexistent',
              source: 'Cash',
              date: DateTime(now.year, now.month, now.day, 10, 0).toUtc(),
              createdAt: DateTime(now.year, now.month, now.day, 10, 0).toUtc(),
              note: null,
            ),
            category: null,
          ),
        ],
        totalExpense: 10000,
        totalIncome: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          groupedState: AsyncValue.data([uncategorizedGroup]),
        ),
      );
      await tester.pumpAndSettle();

      // When note is null and category is null, displays 'Uncategorized'
      expect(find.text('Uncategorized'), findsOneWidget);
      expect(find.text('-Rp 10.000'), findsWidgets);
    });
  });
}
