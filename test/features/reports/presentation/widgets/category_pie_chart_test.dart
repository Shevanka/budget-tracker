import 'package:budget_tracker/core/theme/app_theme.dart';
import 'package:budget_tracker/database/app_database.dart';
import 'package:budget_tracker/database/converters/transaction_type.dart';
import 'package:budget_tracker/features/reports/domain/models/category_spending.dart';
import 'package:budget_tracker/features/reports/presentation/widgets/category_pie_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final testCategory1 = Category(
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

  final testCategory2 = Category(
    id: 'cat-transport',
    name: 'Transportation',
    icon: 'directions_bus',
    color: 0xFF1E88E5,
    type: TransactionType.expense,
    isDefault: true,
    isActive: true,
    sortOrder: 2,
    createdAt: DateTime.utc(2026, 1, 1),
  );

  Widget buildTestChart({
    required CategorySpendingReport report,
    ValueChanged<CategorySpending?>? onCategorySelected,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: CategoryPieChart(
              report: report,
              onCategorySelected: onCategorySelected,
            ),
          ),
        ),
      ),
    );
  }

  group('CategoryPieChart Widget Tests', () {
    testWidgets('renders category spending report with total spent in center and legend',
        (tester) async {
      final report = CategorySpendingReport(
        items: [
          CategorySpending(
            category: testCategory1,
            amount: 750000,
            percentage: 75.0,
            transactionCount: 3,
          ),
          CategorySpending(
            category: testCategory2,
            amount: 250000,
            percentage: 25.0,
            transactionCount: 1,
          ),
        ],
        totalExpense: 1000000,
        startDate: DateTime.utc(2026, 10, 1),
        endDate: DateTime.utc(2026, 10, 31),
      );

      await tester.pumpWidget(buildTestChart(report: report));
      await tester.pumpAndSettle();

      // Card Header
      expect(find.text('Spending by Category'), findsOneWidget);
      expect(find.text('2 categories'), findsOneWidget);

      // Default Center Donut Content
      expect(find.text('Total Spent'), findsOneWidget);
      expect(find.text('Rp 1.000.000'), findsOneWidget);

      // Legend items
      expect(find.text('Food & Dining'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
      expect(find.text('Transportation'), findsOneWidget);
      expect(find.text('25%'), findsOneWidget);
    });

    testWidgets('tapping legend item highlights category in center and invokes callback',
        (tester) async {
      CategorySpending? selectedCategory;

      final report = CategorySpendingReport(
        items: [
          CategorySpending(
            category: testCategory1,
            amount: 600000,
            percentage: 60.0,
            transactionCount: 2,
          ),
          CategorySpending(
            category: testCategory2,
            amount: 400000,
            percentage: 40.0,
            transactionCount: 2,
          ),
        ],
        totalExpense: 1000000,
        startDate: DateTime.utc(2026, 10, 1),
        endDate: DateTime.utc(2026, 10, 31),
      );

      await tester.pumpWidget(buildTestChart(
        report: report,
        onCategorySelected: (cat) => selectedCategory = cat,
      ));
      await tester.pumpAndSettle();

      // Tap on 'Transportation' in the legend
      final legendItem = find.descendant(
        of: find.byType(Wrap),
        matching: find.text('Transportation'),
      );
      expect(legendItem, findsOneWidget);
      await tester.tap(legendItem);
      await tester.pumpAndSettle();

      expect(selectedCategory?.category.name, 'Transportation');
      expect(find.text('Rp 400.000'), findsOneWidget);
      expect(find.text('40.0%'), findsOneWidget);
      // Transportation now appears in both center hole and legend
      expect(find.text('Transportation'), findsNWidgets(2));

      // Tap legend item again to deselect
      await tester.tap(legendItem);
      await tester.pumpAndSettle();

      expect(selectedCategory, isNull);
      expect(find.text('Total Spent'), findsOneWidget);
    });

    testWidgets('renders empty state when report has no data', (tester) async {
      final emptyReport = CategorySpendingReport(
        items: const [],
        totalExpense: 0,
        startDate: DateTime.utc(2026, 10, 1),
        endDate: DateTime.utc(2026, 10, 31),
      );

      await tester.pumpWidget(buildTestChart(report: emptyReport));
      await tester.pumpAndSettle();

      expect(find.text('Spending by Category'), findsOneWidget);
      expect(find.text('No expenses'), findsOneWidget);
      expect(find.byIcon(Icons.savings_outlined), findsOneWidget);
    });
  });
}
