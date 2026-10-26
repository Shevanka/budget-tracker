import 'package:budget_tracker/core/theme/app_theme.dart';
import 'package:budget_tracker/features/reports/domain/models/spending_over_time.dart';
import 'package:budget_tracker/features/reports/presentation/widgets/spending_bar_chart.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildTestChart({required SpendingOverTimeReport report}) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SpendingBarChart(report: report),
          ),
        ),
      ),
    );
  }

  group('SpendingBarChart Widget Tests', () {
    testWidgets('renders empty state when report has no expense data', (tester) async {
      final start = DateTime.utc(2026, 10, 1);
      final end = DateTime.utc(2026, 10, 7);

      final emptyReport = SpendingOverTimeReport(
        items: List.generate(
          7,
          (i) => DailySpending(
            date: DateTime.utc(2026, 10, 1 + i),
            amount: 0,
          ),
        ),
        totalExpense: 0,
        startDate: start,
        endDate: end,
      );

      await tester.pumpWidget(buildTestChart(report: emptyReport));
      await tester.pumpAndSettle();

      expect(find.text('Spending Over Time'), findsOneWidget);
      expect(find.text('No spending recorded'), findsOneWidget);
      expect(
        find.text('Transactions will appear here as daily bars'),
        findsOneWidget,
      );
      expect(find.byType(BarChart), findsNothing);
      expect(find.textContaining('Avg'), findsNothing);
      expect(find.textContaining('Peak:'), findsNothing);
    });

    testWidgets('renders bar chart, average badge, and peak day for week view', (tester) async {
      // 7 days: Monday to Sunday
      final monday = DateTime.utc(2026, 10, 12);
      final items = [
        DailySpending(date: DateTime.utc(2026, 10, 12), amount: 100000, transactionCount: 1),
        DailySpending(date: DateTime.utc(2026, 10, 13), amount: 50000, transactionCount: 1),
        DailySpending(date: DateTime.utc(2026, 10, 14), amount: 0, transactionCount: 0),
        DailySpending(date: DateTime.utc(2026, 10, 15), amount: 350000, transactionCount: 2), // peak
        DailySpending(date: DateTime.utc(2026, 10, 16), amount: 200000, transactionCount: 1),
        DailySpending(date: DateTime.utc(2026, 10, 17), amount: 0, transactionCount: 0),
        DailySpending(date: DateTime.utc(2026, 10, 18), amount: 0, transactionCount: 0),
      ];

      final report = SpendingOverTimeReport(
        items: items,
        totalExpense: 700000,
        startDate: monday,
        endDate: DateTime.utc(2026, 10, 18),
      );

      await tester.pumpWidget(buildTestChart(report: report));
      await tester.pumpAndSettle();

      // Header & Stats
      expect(find.text('Spending Over Time'), findsOneWidget);
      expect(find.text('Avg Rp 100 rb/d'), findsOneWidget);
      expect(find.text('Peak: 15 Oct (Rp 350.000)'), findsOneWidget);

      // BarChart is present
      expect(find.byType(BarChart), findsOneWidget);

      // Week day titles are shown
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Tue'), findsOneWidget);
      expect(find.text('Wed'), findsOneWidget);
      expect(find.text('Thu'), findsOneWidget);
      expect(find.text('Fri'), findsOneWidget);
      expect(find.text('Sat'), findsOneWidget);
      expect(find.text('Sun'), findsOneWidget);
    });

    testWidgets('renders month view with interval day titles', (tester) async {
      // 31 days for October 2026
      final items = List.generate(31, (i) {
        final day = i + 1;
        final amount = (day == 5 || day == 20) ? 200000 : 0;
        return DailySpending(
          date: DateTime.utc(2026, 10, day),
          amount: amount,
          transactionCount: amount > 0 ? 1 : 0,
        );
      });

      final report = SpendingOverTimeReport(
        items: items,
        totalExpense: 400000,
        startDate: DateTime.utc(2026, 10, 1),
        endDate: DateTime.utc(2026, 10, 31),
      );

      await tester.pumpWidget(buildTestChart(report: report));
      await tester.pumpAndSettle();

      expect(find.byType(BarChart), findsOneWidget);
      expect(find.text('Spending Over Time'), findsOneWidget);

      // First day '1', interval days '5', '10', '15', '20', '25', '30', and last day '31'
      expect(find.text('1'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
      expect(find.text('20'), findsOneWidget);
      expect(find.text('25'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
      expect(find.text('31'), findsOneWidget);

      // Non-interval day like '2' or '3' should not be present
      expect(find.text('2'), findsNothing);
      expect(find.text('3'), findsNothing);
    });
  });
}
