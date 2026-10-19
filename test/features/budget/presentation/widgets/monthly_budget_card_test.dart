import 'package:budget_tracker/core/theme/app_theme.dart';
import 'package:budget_tracker/features/budget/domain/models/budget_status.dart';
import 'package:budget_tracker/features/budget/presentation/widgets/budget_progress_bar.dart';
import 'package:budget_tracker/features/budget/presentation/widgets/monthly_budget_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }

  group('MonthlyBudgetCard', () {
    testWidgets('renders active budget status, amounts, progress bar, and remaining balance',
        (tester) async {
      final status = MonthlyBudgetStatus.calculate(
        yearMonth: '2026-10',
        totalLimit: 5000000,
        totalSpent: 1500000,
        categoryStatuses: [],
        unbudgetedSpent: 200000,
      );

      var manageTapped = false;

      await tester.pumpWidget(
        buildTestableWidget(
          MonthlyBudgetCard(
            status: status,
            onManageBudget: () => manageTapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Budget October 2026'), findsOneWidget);
      expect(find.text('Total monthly budget'), findsOneWidget);
      expect(find.text('Rp 1.500.000'), findsOneWidget);
      expect(find.text('of Rp 5.000.000'), findsOneWidget);
      expect(find.text('30%'), findsOneWidget);
      expect(find.byType(BudgetProgressBar), findsOneWidget);
      expect(find.text('Remaining: Rp 3.500.000'), findsOneWidget);
      expect(find.text('+Rp 200.000 unbudgeted'), findsOneWidget);

      // Tap manage icon
      final editButton = find.byIcon(Icons.tune);
      expect(editButton, findsOneWidget);
      await tester.tap(editButton);
      expect(manageTapped, isTrue);
    });

    testWidgets('renders exceeded message when spending surpasses total budget',
        (tester) async {
      final status = MonthlyBudgetStatus.calculate(
        yearMonth: '2026-10',
        totalLimit: 2000000,
        totalSpent: 2500000,
        categoryStatuses: [],
        unbudgetedSpent: 0,
      );

      await tester.pumpWidget(
        buildTestableWidget(
          MonthlyBudgetCard(status: status),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Exceeded by Rp 500.000'), findsOneWidget);
      expect(find.text('125%'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('renders empty state when no budget is set for the month',
        (tester) async {
      final status = MonthlyBudgetStatus.calculate(
        yearMonth: '2026-10',
        totalLimit: 0,
        totalSpent: 300000,
        categoryStatuses: [],
        unbudgetedSpent: 300000,
      );

      var setupTapped = false;

      await tester.pumpWidget(
        buildTestableWidget(
          MonthlyBudgetCard(
            status: status,
            onSetupBudget: () => setupTapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Budget Set for October 2026'), findsOneWidget);
      expect(find.text('Current spent: Rp 300.000'), findsOneWidget);
      expect(find.byType(BudgetProgressBar), findsNothing);

      final setupButton = find.text('Set Up Budget');
      expect(setupButton, findsOneWidget);
      await tester.tap(setupButton);
      expect(setupTapped, isTrue);
    });
  });
}
