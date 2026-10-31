import 'package:budget_tracker/app.dart';
import 'package:budget_tracker/database/app_database.dart';
import 'package:budget_tracker/database/database_provider.dart';
import 'package:budget_tracker/features/budget/domain/models/budget_status.dart';
import 'package:budget_tracker/features/budget/providers/budget_provider.dart';
import 'package:budget_tracker/features/dashboard/domain/models/financial_summary.dart';
import 'package:budget_tracker/features/dashboard/providers/dashboard_provider.dart';
import 'package:budget_tracker/features/notification_watcher/providers/draft_transaction_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BudgetTrackerApp smoke test renders navigation and dashboard',
      (WidgetTester tester) async {
    final db = AppDatabase.inMemory();
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          monthlyFinancialSummaryProvider.overrideWith(
            (ref, month) => Stream.value(
              MonthlyFinancialSummary(
                yearMonth: month,
                totalIncome: 0,
                totalExpense: 0,
                netBalance: 0,
              ),
            ),
          ),
          monthlyBudgetStatusProvider.overrideWith(
            (ref, month) => Stream.value(
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
            (ref, month) => Stream.value([]),
          ),
          pendingDraftTransactionsProvider.overrideWith(
            (ref) => Stream.value([]),
          ),
        ],
        child: const BudgetTrackerApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Dashboard is the initial screen
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Net Balance'), findsOneWidget);

    // Verify 4 NavigationDestination tabs are present in NavigationBar
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Transactions'), findsOneWidget);
    expect(find.text('Reports'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
