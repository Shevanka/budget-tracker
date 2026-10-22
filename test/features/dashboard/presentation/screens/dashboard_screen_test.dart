import 'package:budget_tracker/core/theme/app_theme.dart';
import 'package:budget_tracker/core/utils/year_month_utils.dart';
import 'package:budget_tracker/database/app_database.dart';
import 'package:budget_tracker/database/converters/transaction_type.dart';
import 'package:budget_tracker/database/daos/transaction_dao.dart';
import 'package:budget_tracker/features/budget/domain/models/budget_status.dart';
import 'package:budget_tracker/features/budget/presentation/widgets/monthly_budget_card.dart';
import 'package:budget_tracker/features/budget/providers/budget_provider.dart';
import 'package:budget_tracker/features/dashboard/domain/models/financial_summary.dart';
import 'package:budget_tracker/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:budget_tracker/features/dashboard/presentation/widgets/widgets.dart';
import 'package:budget_tracker/features/dashboard/providers/dashboard_provider.dart';
import 'package:budget_tracker/routing/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class FakeBudgetController extends BudgetController {
  static final List<String> ensureBudgetCalls = [];

  @override
  Future<void> build() async {}

  @override
  Future<Budget?> ensureBudgetForMonth(
    String yearMonth, {
    bool fallbackToLatest = true,
  }) async {
    ensureBudgetCalls.add(yearMonth);
    return null;
  }
}

void main() {
  final currentMonth = YearMonthUtils.currentYearMonth();
  final prevMonth = YearMonthUtils.previousYearMonth(currentMonth);

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

  final mockSummaries = <String, MonthlyFinancialSummary>{
    currentMonth: MonthlyFinancialSummary(
      yearMonth: currentMonth,
      totalIncome: 5000000,
      totalExpense: 1500000,
      netBalance: 3500000,
      transactionCount: 2,
    ),
    prevMonth: MonthlyFinancialSummary(
      yearMonth: prevMonth,
      totalIncome: 3000000,
      totalExpense: 1000000,
      netBalance: 2000000,
      transactionCount: 1,
    ),
  };

  final mockBudgetStatuses = <String, MonthlyBudgetStatus>{
    currentMonth: MonthlyBudgetStatus.calculate(
      yearMonth: currentMonth,
      totalLimit: 5000000,
      totalSpent: 1500000,
      categoryStatuses: [
        CategoryBudgetStatus.calculate(
          category: testCategory,
          limit: 2000000,
          spent: 800000,
        ),
      ],
      unbudgetedSpent: 700000,
    ),
    prevMonth: MonthlyBudgetStatus.calculate(
      yearMonth: prevMonth,
      totalLimit: 4000000,
      totalSpent: 1000000,
      categoryStatuses: const [],
      unbudgetedSpent: 1000000,
    ),
  };

  final mockRecentTransactions = <String, List<TransactionWithCategory>>{
    currentMonth: [
      TransactionWithCategory(
        transaction: Transaction(
          id: 'tx-1',
          amount: 50000,
          type: TransactionType.expense,
          categoryId: 'cat-food',
          source: 'Cash',
          note: 'Dinner',
          date: DateTime.utc(2026, 10, 15, 19, 0),
          createdAt: DateTime.utc(2026, 10, 15, 19, 0),
        ),
        category: testCategory,
      ),
    ],
    prevMonth: [],
  };

  Widget createTestWidget({
    Map<String, MonthlyFinancialSummary>? summaries,
    Map<String, MonthlyBudgetStatus>? budgetStatuses,
    Map<String, List<TransactionWithCategory>>? recentTransactions,
    Stream<MonthlyFinancialSummary>? summaryStreamOverride,
    List<Override> additionalOverrides = const [],
  }) {
    final activeSummaries = summaries ?? mockSummaries;
    final activeBudgetStatuses = budgetStatuses ?? mockBudgetStatuses;
    final activeRecent = recentTransactions ?? mockRecentTransactions;

    final router = GoRouter(
      initialLocation: AppRoute.dashboard.path,
      routes: [
        GoRoute(
          path: AppRoute.dashboard.path,
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: AppRoute.transactions.path,
          builder: (context, state) => const Scaffold(
            body: Text('Transactions Target Screen'),
          ),
        ),
        GoRoute(
          path: AppRoute.addTransaction.path,
          builder: (context, state) => const Scaffold(
            body: Text('Add Transaction Target Screen'),
          ),
        ),
        GoRoute(
          path: AppRoute.budgetSetup.path,
          builder: (context, state) => const Scaffold(
            body: Text('Budget Setup Target Screen'),
          ),
        ),
        GoRoute(
          path: AppRoute.categoryManager.path,
          builder: (context, state) => const Scaffold(
            body: Text('Category Manager Target Screen'),
          ),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        budgetControllerProvider.overrideWith(FakeBudgetController.new),
        if (summaryStreamOverride != null)
          monthlyFinancialSummaryProvider.overrideWith(
            (ref, month) => summaryStreamOverride,
          )
        else
          monthlyFinancialSummaryProvider.overrideWith(
            (ref, month) => Stream.value(
              activeSummaries[month] ??
                  MonthlyFinancialSummary(
                    yearMonth: month,
                    totalIncome: 0,
                    totalExpense: 0,
                    netBalance: 0,
                    transactionCount: 0,
                  ),
            ),
          ),
        monthlyBudgetStatusProvider.overrideWith(
          (ref, month) => Stream.value(
            activeBudgetStatuses[month] ??
                MonthlyBudgetStatus(
                  yearMonth: month,
                  totalLimit: 0,
                  totalSpent: 0,
                  totalRemaining: 0,
                  percentage: 0,
                  ratio: 0.0,
                  statusLevel: BudgetStatusLevel.safe,
                  categoryStatuses: const [],
                  unbudgetedSpent: 0,
                ),
          ),
        ),
        previousAvailableBudgetProvider.overrideWith(
          (ref, month) => Future.value(null),
        ),
        recentTransactionsForMonthProvider.overrideWith(
          (ref, month) => Stream.value(activeRecent[month] ?? []),
        ),
        ...additionalOverrides,
      ],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        routerConfig: router,
      ),
    );
  }

  group('DashboardScreen Presentation', () {
    testWidgets(
        'renders month selector, net balance card, income/expense summaries, budget progress, and recent transactions',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // App bar & Month Header
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.byType(MonthSelectorHeader), findsOneWidget);
      expect(find.text(YearMonthUtils.formatDisplay(currentMonth)), findsWidgets);

      // Balance Card
      expect(find.byType(BalanceCard), findsOneWidget);
      expect(find.text('Net Balance'), findsOneWidget);
      expect(find.text('Rp 3.500.000'), findsOneWidget);
      expect(find.textContaining('Surplus'), findsOneWidget);

      // Income & Expense Summaries
      expect(find.byType(IncomeExpenseSummaryCard), findsOneWidget);
      expect(find.text('Rp 5.000.000'), findsOneWidget);
      expect(find.text('Rp 1.500.000'), findsWidgets);

      // Budget Progress Section
      expect(find.byType(DashboardBudgetSection), findsOneWidget);
      expect(find.text('Budget Progress'), findsOneWidget);
      expect(find.byType(MonthlyBudgetCard), findsOneWidget);
      expect(find.text('of Rp 5.000.000'), findsOneWidget);
      expect(find.text('30%'), findsOneWidget);
      expect(find.text('Category Budgets'), findsOneWidget);
      expect(find.text('Food & Dining'), findsWidgets);

      // Recent Transactions Section
      expect(find.byType(DashboardRecentTransactions), findsOneWidget);
      expect(find.text('Recent Transactions'), findsOneWidget);
      expect(find.text('Dinner'), findsOneWidget);
      expect(find.text('-Rp 50.000'), findsOneWidget);
      expect(find.text('See All Transactions'), findsOneWidget);

      // Quick Action Buttons & FAB
      final addButton = find.text('Add Transaction');
      await tester.ensureVisible(addButton);
      expect(addButton, findsOneWidget);
      expect(find.text('Setup Budget'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('month navigation updates the displayed month and financial summary values',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Rp 3.500.000'), findsOneWidget);

      // Tap previous month chevron
      final prevButton = find.byTooltip('Previous month');
      expect(prevButton, findsOneWidget);
      await tester.tap(prevButton);
      await tester.pumpAndSettle();

      expect(find.text(YearMonthUtils.formatDisplay(prevMonth)), findsWidgets);
      expect(find.text('This Month'), findsOneWidget);
      expect(find.text('Rp 2.000.000'), findsOneWidget);
      expect(find.text('Rp 3.000.000'), findsOneWidget);
      expect(find.text('Rp 1.000.000'), findsWidgets);

      // Tap "This Month" chip to return to current month
      await tester.tap(find.text('This Month'));
      await tester.pumpAndSettle();

      expect(find.text(YearMonthUtils.formatDisplay(currentMonth)), findsWidgets);
      expect(find.text('Rp 3.500.000'), findsOneWidget);
    });

    testWidgets('tapping month header dropdown opens MonthPickerDialog and updates month',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap the dropdown icon in MonthSelectorHeader
      final dropdownIcon = find.byIcon(Icons.arrow_drop_down_rounded);
      expect(dropdownIcon, findsOneWidget);
      await tester.tap(dropdownIcon);
      await tester.pumpAndSettle();

      // Verify dialog is open
      expect(find.byType(MonthPickerDialog), findsOneWidget);

      // Tap Previous Year chevron in dialog to jump back 1 year
      await tester.tap(find.byTooltip('Previous year'));
      await tester.pumpAndSettle();

      // Tap 'Jan'
      await tester.tap(find.text('Jan'));
      await tester.pumpAndSettle();

      // Dialog should be dismissed
      expect(find.byType(MonthPickerDialog), findsNothing);

      // Month selector header should now display January of previous year
      final (currentYear, _) = YearMonthUtils.parse(currentMonth);
      final expectedYearMonth = '${currentYear - 1}-01';
      expect(find.text(YearMonthUtils.formatDisplay(expectedYearMonth)), findsWidgets);
    });

    testWidgets('horizontal fling navigates between months', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final nextMonth = YearMonthUtils.nextYearMonth(currentMonth);

      // Fling right-to-left (negative horizontal offset) to advance to next month
      await tester.fling(find.byType(DashboardScreen), const Offset(-400, 0), 1000);
      await tester.pumpAndSettle();

      expect(find.text(YearMonthUtils.formatDisplay(nextMonth)), findsWidgets);

      // Fling left-to-right (positive horizontal offset) to return to previous month
      await tester.fling(find.byType(DashboardScreen), const Offset(400, 0), 1000);
      await tester.pumpAndSettle();

      expect(find.text(YearMonthUtils.formatDisplay(currentMonth)), findsWidgets);
    });

    testWidgets('quick actions navigate to respective screens', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap "Add Transaction" quick action button
      final addButton = find.widgetWithText(FilledButton, 'Add Transaction');
      await tester.ensureVisible(addButton);
      await tester.tap(addButton);
      await tester.pumpAndSettle();
      expect(find.text('Add Transaction Target Screen'), findsOneWidget);
    });

    testWidgets('setup budget quick action navigates to budget setup screen',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap "Setup Budget" quick action button
      final setupButton = find.text('Setup Budget');
      await tester.ensureVisible(setupButton);
      await tester.tap(setupButton);
      await tester.pumpAndSettle();
      expect(find.text('Budget Setup Target Screen'), findsOneWidget);
    });

    testWidgets('recent transactions See All button navigates to transactions tab',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final seeAllButton = find.text('See All');
      await tester.ensureVisible(seeAllButton);
      await tester.tap(seeAllButton);
      await tester.pumpAndSettle();
      expect(find.text('Transactions Target Screen'), findsOneWidget);
    });

    testWidgets('budget progress Manage button navigates to budget setup screen',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Manage'));
      await tester.pumpAndSettle();
      expect(find.text('Budget Setup Target Screen'), findsOneWidget);
    });

    testWidgets('app bar category manager button navigates to category manager screen',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Categories'));
      await tester.pumpAndSettle();
      expect(find.text('Category Manager Target Screen'), findsOneWidget);
    });

    testWidgets('app bar budget setup button navigates to budget setup screen',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Budget Setup'));
      await tester.pumpAndSettle();
      expect(find.text('Budget Setup Target Screen'), findsOneWidget);
    });

    testWidgets('FAB navigates to add transaction screen', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(find.text('Add Transaction Target Screen'), findsOneWidget);
    });

    testWidgets('renders error card when financial summary stream yields an error',
        (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          summaryStreamOverride: Stream.error(Exception('Database error')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Failed to load financial summary'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('pull-to-refresh triggers refresh and re-ensures budget for month',
        (tester) async {
      FakeBudgetController.ensureBudgetCalls.clear();
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final initialCallCount = FakeBudgetController.ensureBudgetCalls.length;
      expect(initialCallCount, greaterThanOrEqualTo(1));

      // Trigger pull to refresh
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, 300),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(FakeBudgetController.ensureBudgetCalls.length, greaterThan(initialCallCount));
      expect(FakeBudgetController.ensureBudgetCalls.last, currentMonth);
    });

    testWidgets('slow drag below horizontal threshold does not navigate month',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text(YearMonthUtils.formatDisplay(currentMonth)), findsWidgets);

      // Perform a slow drag with negligible release velocity
      final gesture = await tester.startGesture(const Offset(200, 200));
      await gesture.moveBy(const Offset(-30, 0));
      await tester.pump(const Duration(milliseconds: 500));
      await gesture.up();
      await tester.pumpAndSettle();

      // Month remains unchanged
      expect(find.text(YearMonthUtils.formatDisplay(currentMonth)), findsWidgets);
    });
  });
}
