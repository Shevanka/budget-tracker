import 'package:budget_tracker/core/theme/app_colors.dart';
import 'package:budget_tracker/core/theme/app_theme.dart';
import 'package:budget_tracker/features/dashboard/domain/models/financial_summary.dart';
import 'package:budget_tracker/features/dashboard/presentation/widgets/income_expense_summary_card.dart';
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
          child: IncomeExpenseSummaryCard(summary: summary),
        ),
      ),
    );
  }

  group('IncomeExpenseSummaryCard Widget Tests', () {
    testWidgets('renders income and expense cards with icons, labels, and formatted values',
        (tester) async {
      const summary = MonthlyFinancialSummary(
        yearMonth: '2026-10',
        totalIncome: 7500000,
        totalExpense: 3250000,
        netBalance: 4250000,
        transactionCount: 5,
      );

      await tester.pumpWidget(buildTestCard(summary: summary));
      await tester.pumpAndSettle();

      // Labels and Icons
      expect(find.text('Income'), findsOneWidget);
      expect(find.text('Expense'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_downward_rounded), findsOneWidget);
      expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);

      // Amounts
      expect(find.text('Rp 7.500.000'), findsOneWidget);
      expect(find.text('Rp 3.250.000'), findsOneWidget);

      // Color verification
      final incomeText = tester.widget<Text>(find.text('Rp 7.500.000'));
      expect(incomeText.style?.color, AppColors.income);

      final expenseText = tester.widget<Text>(find.text('Rp 3.250.000'));
      expect(expenseText.style?.color, AppColors.expense);
    });

    testWidgets('handles zero income and expense gracefully', (tester) async {
      const summary = MonthlyFinancialSummary(
        yearMonth: '2026-10',
        totalIncome: 0,
        totalExpense: 0,
        netBalance: 0,
        transactionCount: 0,
      );

      await tester.pumpWidget(buildTestCard(summary: summary));
      await tester.pumpAndSettle();

      expect(find.text('Rp 0'), findsNWidgets(2));
    });
  });
}
