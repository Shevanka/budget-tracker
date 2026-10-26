import 'package:budget_tracker/core/theme/app_theme.dart';
import 'package:budget_tracker/core/utils/year_month_utils.dart';
import 'package:budget_tracker/database/app_database.dart';
import 'package:budget_tracker/database/converters/transaction_type.dart';
import 'package:budget_tracker/features/reports/domain/models/category_spending.dart';
import 'package:budget_tracker/features/reports/domain/models/spending_over_time.dart';
import 'package:budget_tracker/features/reports/presentation/screens/reports_screen.dart';
import 'package:budget_tracker/features/reports/presentation/widgets/category_pie_chart.dart';
import 'package:budget_tracker/features/reports/presentation/widgets/spending_bar_chart.dart';
import 'package:budget_tracker/features/reports/providers/reports_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
    sortOrder: 1,
    createdAt: DateTime.utc(2026, 1, 1),
  );

  final mockReports = <String, CategorySpendingReport>{
    currentMonth: CategorySpendingReport(
      items: [
        CategorySpending(
          category: testCategory,
          amount: 1500000,
          percentage: 100.0,
          transactionCount: 3,
        ),
      ],
      totalExpense: 1500000,
      startDate: YearMonthUtils.getStartOfMonth(currentMonth),
      endDate: YearMonthUtils.getEndOfMonth(currentMonth),
    ),
    prevMonth: CategorySpendingReport(
      items: [
        CategorySpending(
          category: testCategory,
          amount: 800000,
          percentage: 100.0,
          transactionCount: 1,
        ),
      ],
      totalExpense: 800000,
      startDate: YearMonthUtils.getStartOfMonth(prevMonth),
      endDate: YearMonthUtils.getEndOfMonth(prevMonth),
    ),
  };

  Widget buildTestScreen({
    Map<String, CategorySpendingReport>? reports,
    Stream<CategorySpendingReport>? streamOverride,
  }) {
    final activeReports = reports ?? mockReports;

    return ProviderScope(
      overrides: [
        if (streamOverride != null)
          categorySpendingReportProvider.overrideWith(
            (ref, filter) => streamOverride,
          )
        else
          categorySpendingReportProvider.overrideWith(
            (ref, filter) {
              final ym = filter.yearMonth ?? currentMonth;
              return Stream.value(
                activeReports[ym] ??
                    CategorySpendingReport(
                      items: const [],
                      totalExpense: 0,
                      startDate: filter.startDate,
                      endDate: filter.endDate,
                    ),
              );
            },
          ),
        spendingOverTimeProvider.overrideWith(
          (ref, filter) {
            return Stream.value(
              SpendingOverTimeReport(
                items: [
                  DailySpending(
                    date: filter.startDate,
                    amount: 500000,
                    transactionCount: 1,
                  ),
                ],
                totalExpense: 500000,
                startDate: filter.startDate,
                endDate: filter.endDate,
              ),
            );
          },
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const ReportsScreen(),
      ),
    );
  }

  group('ReportsScreen Presentation Tests', () {
    testWidgets('renders reports screen with period selector, pie chart, top category insight, and bar chart',
        (tester) async {
      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      // App bar & mode selector
      expect(find.text('Reports'), findsOneWidget);
      expect(find.text('Month'), findsOneWidget);
      expect(find.text('Week'), findsOneWidget);

      // Period header
      expect(find.text(YearMonthUtils.formatDisplay(currentMonth)), findsOneWidget);

      // Pie chart card
      expect(find.byType(CategoryPieChart), findsOneWidget);
      expect(find.text('Spending by Category'), findsOneWidget);
      expect(find.text('Rp 1.500.000'), findsWidgets);

      // Insights card
      expect(find.text('Top Spending Category'), findsOneWidget);
      expect(find.text('Food & Dining (100.0%)'), findsOneWidget);

      // Spending bar chart card
      expect(find.byType(SpendingBarChart), findsOneWidget);
      expect(find.text('Spending Over Time'), findsOneWidget);
    });

    testWidgets('switching between Month and Week toggles period view',
        (tester) async {
      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      // Tap 'Week' segment
      await tester.tap(find.text('Week'));
      await tester.pumpAndSettle();

      expect(find.text('This Week'), findsOneWidget);

      // Tap 'Month' segment to return
      await tester.tap(find.text('Month'));
      await tester.pumpAndSettle();

      expect(find.text(YearMonthUtils.formatDisplay(currentMonth)), findsOneWidget);
    });

    testWidgets('month navigation updates displayed period and report data',
        (tester) async {
      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      expect(find.text('Rp 1.500.000'), findsWidgets);

      // Tap previous month
      await tester.tap(find.byTooltip('Previous month'));
      await tester.pumpAndSettle();

      expect(find.text(YearMonthUtils.formatDisplay(prevMonth)), findsOneWidget);
      expect(find.text('This Month'), findsOneWidget);
      expect(find.text('Rp 800.000'), findsWidgets);

      // Tap 'This Month' chip
      await tester.tap(find.text('This Month'));
      await tester.pumpAndSettle();

      expect(find.text(YearMonthUtils.formatDisplay(currentMonth)), findsOneWidget);
    });

    testWidgets('renders error card when report stream yields error',
        (tester) async {
      await tester.pumpWidget(
        buildTestScreen(
          streamOverride: Stream.error(Exception('Failed to load')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Failed to load spending report'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
