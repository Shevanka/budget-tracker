import 'package:budget_tracker/core/theme/app_colors.dart';
import 'package:budget_tracker/core/theme/app_theme.dart';
import 'package:budget_tracker/core/utils/year_month_utils.dart';
import 'package:budget_tracker/features/dashboard/domain/models/financial_summary.dart';
import 'package:budget_tracker/features/dashboard/presentation/widgets/balance_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildTestCard({
    required MonthlyFinancialSummary summary,
    ThemeData? theme,
  }) {
    return MaterialApp(
      theme: theme ?? AppTheme.lightTheme,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: BalanceCard(summary: summary),
        ),
      ),
    );
  }

  group('BalanceCard Widget Tests', () {
    testWidgets('renders surplus state correctly with positive balance',
        (tester) async {
      const summary = MonthlyFinancialSummary(
        yearMonth: '2026-10',
        totalIncome: 10000000,
        totalExpense: 3500000,
        netBalance: 6500000,
        transactionCount: 8,
      );

      await tester.pumpWidget(buildTestCard(summary: summary));
      await tester.pumpAndSettle();

      expect(find.text('Net Balance'), findsOneWidget);
      expect(find.text('Rp 6.500.000'), findsOneWidget);
      expect(find.text('Surplus for this month'), findsOneWidget);
      expect(find.text(YearMonthUtils.formatDisplay('2026-10')), findsOneWidget);
      expect(find.byIcon(Icons.account_balance_wallet), findsOneWidget);

      final balanceText = tester.widget<Text>(find.text('Rp 6.500.000'));
      expect(balanceText.style?.color, AppColors.income);
    });

    testWidgets('renders zero balance neutral state correctly', (tester) async {
      const summary = MonthlyFinancialSummary(
        yearMonth: '2026-10',
        totalIncome: 0,
        totalExpense: 0,
        netBalance: 0,
        transactionCount: 0,
      );

      await tester.pumpWidget(buildTestCard(summary: summary));
      await tester.pumpAndSettle();

      expect(find.text('Net Balance'), findsOneWidget);
      expect(find.text('Rp 0'), findsOneWidget);
      expect(find.text('No transactions recorded yet'), findsOneWidget);
      expect(find.text(YearMonthUtils.formatDisplay('2026-10')), findsOneWidget);

      final balanceText = tester.widget<Text>(find.text('Rp 0'));
      // Zero balance uses onSurface color
      expect(balanceText.style?.color, AppTheme.lightTheme.colorScheme.onSurface);
    });

    testWidgets('renders deficit state correctly with negative balance',
        (tester) async {
      const summary = MonthlyFinancialSummary(
        yearMonth: '2026-10',
        totalIncome: 2000000,
        totalExpense: 3500000,
        netBalance: -1500000,
        transactionCount: 4,
      );

      await tester.pumpWidget(buildTestCard(summary: summary));
      await tester.pumpAndSettle();

      expect(find.text('Net Balance'), findsOneWidget);
      expect(find.text('-Rp 1.500.000'), findsOneWidget);
      expect(find.text('Deficit (spending exceeds income)'), findsOneWidget);

      final balanceText = tester.widget<Text>(find.text('-Rp 1.500.000'));
      expect(balanceText.style?.color, AppColors.expense);
    });

    testWidgets('correctly formats different month labels', (tester) async {
      const summary = MonthlyFinancialSummary(
        yearMonth: '2025-01',
        totalIncome: 500000,
        totalExpense: 200000,
        netBalance: 300000,
        transactionCount: 2,
      );

      await tester.pumpWidget(buildTestCard(summary: summary));
      await tester.pumpAndSettle();

      expect(find.text(YearMonthUtils.formatDisplay('2025-01')), findsOneWidget);
    });
  });
}
