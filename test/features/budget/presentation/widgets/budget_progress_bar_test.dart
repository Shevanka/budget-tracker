import 'package:budget_tracker/core/theme/app_colors.dart';
import 'package:budget_tracker/core/theme/app_theme.dart';
import 'package:budget_tracker/database/app_database.dart';
import 'package:budget_tracker/database/converters/transaction_type.dart';
import 'package:budget_tracker/features/budget/domain/models/budget_status.dart';
import 'package:budget_tracker/features/budget/presentation/widgets/budget_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 200,
            child: child,
          ),
        ),
      ),
    );
  }

  group('BudgetProgressBar', () {
    testWidgets('renders safe color when percentage is below 80%', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const BudgetProgressBar(
            percentage: 60,
            animate: false,
          ),
        ),
      );

      final barFinder = find.byType(BudgetProgressBar);
      expect(barFinder, findsOneWidget);

      final bar = tester.widget<BudgetProgressBar>(barFinder);
      expect(bar.effectiveStatusLevel, BudgetStatusLevel.safe);

      final BuildContext context = tester.element(barFinder);
      expect(bar.resolveColor(context), AppColors.budgetSafe);
    });

    testWidgets('renders warning color when percentage is 80% to 99%', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const BudgetProgressBar(
            percentage: 85,
            animate: false,
          ),
        ),
      );

      final barFinder = find.byType(BudgetProgressBar);
      final bar = tester.widget<BudgetProgressBar>(barFinder);
      expect(bar.effectiveStatusLevel, BudgetStatusLevel.warning);

      final BuildContext context = tester.element(barFinder);
      expect(bar.resolveColor(context), AppColors.budgetWarning);
    });

    testWidgets('renders danger color when percentage is 100% or greater', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const BudgetProgressBar(
            percentage: 125,
            animate: false,
          ),
        ),
      );

      final barFinder = find.byType(BudgetProgressBar);
      final bar = tester.widget<BudgetProgressBar>(barFinder);
      expect(bar.effectiveStatusLevel, BudgetStatusLevel.danger);

      final BuildContext context = tester.element(barFinder);
      expect(bar.resolveColor(context), AppColors.budgetDanger);
    });

    testWidgets('custom color overrides semantic color', (tester) async {
      const customColor = Colors.purple;
      await tester.pumpWidget(
        buildTestableWidget(
          const BudgetProgressBar(
            percentage: 50,
            color: customColor,
            animate: false,
          ),
        ),
      );

      final barFinder = find.byType(BudgetProgressBar);
      final bar = tester.widget<BudgetProgressBar>(barFinder);
      final BuildContext context = tester.element(barFinder);
      expect(bar.resolveColor(context), customColor);
    });

    testWidgets('animates progress bar fill smoothly', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const BudgetProgressBar(
            percentage: 75,
            animate: true,
          ),
        ),
      );

      expect(find.byType(TweenAnimationBuilder<double>), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byType(BudgetProgressBar), findsOneWidget);
    });

    testWidgets('includes accessibility semantics label and value', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const BudgetProgressBar(
            percentage: 85,
            animate: false,
          ),
        ),
      );

      final semanticsFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'Budget progress: 85%, warning' &&
            widget.properties.value == '85%',
      );
      expect(semanticsFinder, findsOneWidget);
    });

    testWidgets('fromCategoryStatus initializes correctly', (tester) async {
      final sampleCategory = Category(
        id: 'cat-1',
        name: 'Dining',
        icon: 'restaurant',
        color: 0xFF43A047,
        type: TransactionType.expense,
        sortOrder: 1,
        isDefault: true,
        isActive: true,
        createdAt: DateTime.utc(2026, 1, 1),
      );

      final status = CategoryBudgetStatus.calculate(
        category: sampleCategory,
        limit: 1000000,
        spent: 850000,
      );

      await tester.pumpWidget(
        buildTestableWidget(
          BudgetProgressBar.fromCategoryStatus(
            status: status,
            animate: false,
          ),
        ),
      );

      final barFinder = find.byType(BudgetProgressBar);
      expect(barFinder, findsOneWidget);
      final bar = tester.widget<BudgetProgressBar>(barFinder);
      expect(bar.percentage, 85);
      expect(bar.statusLevel, BudgetStatusLevel.warning);
    });

    testWidgets('fromMonthlyStatus initializes with default height 12', (tester) async {
      final monthlyStatus = MonthlyBudgetStatus.calculate(
        yearMonth: '2026-10',
        totalLimit: 5000000,
        totalSpent: 2000000,
        categoryStatuses: [],
        unbudgetedSpent: 0,
      );

      await tester.pumpWidget(
        buildTestableWidget(
          BudgetProgressBar.fromMonthlyStatus(
            status: monthlyStatus,
            animate: false,
          ),
        ),
      );

      final barFinder = find.byType(BudgetProgressBar);
      expect(barFinder, findsOneWidget);
      final bar = tester.widget<BudgetProgressBar>(barFinder);
      expect(bar.percentage, 40);
      expect(bar.height, 12.0);
      expect(bar.statusLevel, BudgetStatusLevel.safe);
    });
  });
}
