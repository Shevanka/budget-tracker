import 'package:budget_tracker/core/theme/app_theme.dart';
import 'package:budget_tracker/core/utils/year_month_utils.dart';
import 'package:budget_tracker/database/app_database.dart';
import 'package:budget_tracker/database/converters/transaction_type.dart';
import 'package:budget_tracker/database/daos/transaction_dao.dart';
import 'package:budget_tracker/features/dashboard/presentation/widgets/dashboard_recent_transactions.dart';
import 'package:budget_tracker/features/dashboard/providers/dashboard_provider.dart';
import 'package:budget_tracker/routing/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  final currentMonth = YearMonthUtils.currentYearMonth();

  final testCategory = Category(
    id: 'cat-food',
    name: 'Food & Dining',
    icon: 'restaurant',
    color: 0xFF43A047,
    type: TransactionType.expense,
    isDefault: true,
    isActive: true,
    sortOrder: 0,
    createdAt: DateTime.utc(2026, 1, 1),
  );

  final testIncomeCategory = Category(
    id: 'cat-salary',
    name: 'Salary',
    icon: 'attach_money',
    color: 0xFF2E7D32,
    type: TransactionType.income,
    isDefault: true,
    isActive: true,
    sortOrder: 1,
    createdAt: DateTime.utc(2026, 1, 1),
  );

  final sampleItems = [
    TransactionWithCategory(
      transaction: Transaction(
        id: 'tx-1',
        amount: 25000,
        type: TransactionType.expense,
        categoryId: 'cat-food',
        source: 'GoPay',
        note: 'GrabFood lunch',
        date: DateTime.utc(2026, 10, 15, 12, 30),
        createdAt: DateTime.utc(2026, 10, 15, 12, 30),
      ),
      category: testCategory,
    ),
    TransactionWithCategory(
      transaction: Transaction(
        id: 'tx-2',
        amount: 5000000,
        type: TransactionType.income,
        categoryId: 'cat-salary',
        source: 'BCA',
        note: null,
        date: DateTime.utc(2026, 10, 1, 9, 0),
        createdAt: DateTime.utc(2026, 10, 1, 9, 0),
      ),
      category: testIncomeCategory,
    ),
  ];

  Widget createWidget({
    required AsyncValue<List<TransactionWithCategory>> recentAsync,
  }) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: SingleChildScrollView(
              child: DashboardRecentTransactions(
                selectedYearMonth: currentMonth,
              ),
            ),
          ),
        ),
        GoRoute(
          path: AppRoute.transactions.path,
          builder: (context, state) => const Scaffold(
            body: Text('Transactions Screen Target'),
          ),
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
              'Edit Transaction Target (${state.pathParameters['id']})',
            ),
          ),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        recentTransactionsForMonthProvider(currentMonth).overrideWith(
          (ref) => recentAsync.when(
            data: (data) => Stream.value(data),
            error: (err, st) => Stream.error(err, st),
            loading: () => const Stream.empty(),
          ),
        ),
      ],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        routerConfig: router,
      ),
    );
  }

  group('DashboardRecentTransactions', () {
    testWidgets('renders recent transaction tiles with notes, source, and amounts',
        (tester) async {
      await tester.pumpWidget(
        createWidget(recentAsync: AsyncValue.data(sampleItems)),
      );
      await tester.pumpAndSettle();

      // Section Header
      expect(find.text('Recent Transactions'), findsOneWidget);
      expect(find.text('See All'), findsOneWidget);

      // First transaction (Expense)
      expect(find.text('GrabFood lunch'), findsOneWidget);
      expect(find.textContaining('GoPay'), findsOneWidget);
      expect(find.text('-Rp 25.000'), findsOneWidget);

      // Second transaction (Income)
      expect(find.text('Salary'), findsOneWidget);
      expect(find.textContaining('BCA'), findsOneWidget);
      expect(find.text('+Rp 5.000.000'), findsOneWidget);

      // Bottom footer button
      expect(find.text('See All Transactions'), findsOneWidget);
    });

    testWidgets('renders empty state when no transactions exist for the month',
        (tester) async {
      await tester.pumpWidget(
        createWidget(recentAsync: const AsyncValue.data([])),
      );
      await tester.pumpAndSettle();

      final displayMonth = YearMonthUtils.formatDisplay(currentMonth);
      expect(find.text('No transactions in $displayMonth'), findsOneWidget);
      expect(find.text('Add Transaction'), findsOneWidget);

      // Tapping "Add Transaction" navigates to add transaction screen
      await tester.tap(find.text('Add Transaction'));
      await tester.pumpAndSettle();
      expect(find.text('Add Transaction Screen Target'), findsOneWidget);
    });

    testWidgets('header See All button navigates to transactions tab',
        (tester) async {
      await tester.pumpWidget(
        createWidget(recentAsync: AsyncValue.data(sampleItems)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('See All'));
      await tester.pumpAndSettle();
      expect(find.text('Transactions Screen Target'), findsOneWidget);
    });

    testWidgets('footer See All Transactions button navigates to transactions tab',
        (tester) async {
      await tester.pumpWidget(
        createWidget(recentAsync: AsyncValue.data(sampleItems)),
      );
      await tester.pumpAndSettle();

      final footerButton = find.text('See All Transactions');
      await tester.ensureVisible(footerButton);
      await tester.tap(footerButton);
      await tester.pumpAndSettle();
      expect(find.text('Transactions Screen Target'), findsOneWidget);
    });

    testWidgets('tapping an individual transaction tile navigates to edit screen',
        (tester) async {
      await tester.pumpWidget(
        createWidget(recentAsync: AsyncValue.data(sampleItems)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('GrabFood lunch'));
      await tester.pumpAndSettle();
      expect(find.text('Edit Transaction Target (tx-1)'), findsOneWidget);
    });

    testWidgets('renders error card when recent transactions stream fails',
        (tester) async {
      await tester.pumpWidget(
        createWidget(
          recentAsync: AsyncValue.error(
            Exception('Database query failed'),
            StackTrace.empty,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Failed to load recent transactions'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
