import 'package:budget_tracker/core/theme/app_theme.dart';
import 'package:budget_tracker/core/utils/year_month_utils.dart';
import 'package:budget_tracker/database/app_database.dart';
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
  @override
  Future<void> build() async {}

  @override
  Future<Budget?> ensureBudgetForMonth(
    String yearMonth, {
    bool fallbackToLatest = true,
  }) async {
    return null;
  }
}

void main() {
  final currentMonth = YearMonthUtils.currentYearMonth();
  final prevMonth = YearMonthUtils.previousYearMonth(currentMonth);

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

  Widget createTestWidget({
    Map<String, MonthlyFinancialSummary>? summaries,
    Stream<MonthlyFinancialSummary>? summaryStreamOverride,
    List<Override> additionalOverrides = const [],
  }) {
    final activeSummaries = summaries ?? mockSummaries;

    final router = GoRouter(
      initialLocation: AppRoute.dashboard.path,
      routes: [
        GoRoute(
          path: AppRoute.dashboard.path,
          builder: (context, state) => const DashboardScreen(),
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
        ...additionalOverrides,
      ],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        routerConfig: router,
      ),
    );
  }

  group('DashboardScreen Presentation', () {
    testWidgets('renders month selector, net balance card, and income/expense summaries',
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
      expect(find.text('Rp 1.500.000'), findsOneWidget);

      // Quick Action Buttons & FAB
      expect(find.text('Add Transaction'), findsOneWidget);
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
      expect(find.text('Rp 1.000.000'), findsOneWidget);

      // Tap "This Month" chip to return to current month
      await tester.tap(find.text('This Month'));
      await tester.pumpAndSettle();

      expect(find.text(YearMonthUtils.formatDisplay(currentMonth)), findsWidgets);
      expect(find.text('Rp 3.500.000'), findsOneWidget);
    });

    testWidgets('quick actions navigate to respective screens', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap "Add Transaction" quick action button
      await tester.tap(find.text('Add Transaction'));
      await tester.pumpAndSettle();
      expect(find.text('Add Transaction Target Screen'), findsOneWidget);
    });

    testWidgets('setup budget quick action navigates to budget setup screen',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap "Setup Budget" quick action button
      await tester.tap(find.text('Setup Budget'));
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
  });
}
