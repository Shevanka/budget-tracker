import 'package:budget_tracker/core/theme/app_theme.dart';
import 'package:budget_tracker/database/app_database.dart';
import 'package:budget_tracker/database/converters/transaction_type.dart';
import 'package:budget_tracker/features/reports/domain/models/category_spending.dart';
import 'package:budget_tracker/features/reports/presentation/widgets/category_breakdown_list.dart';
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

  Widget buildTestWidget({
    required CategorySpendingReport report,
    CategorySpending? selectedCategory,
    ValueChanged<CategorySpending?>? onCategorySelected,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: CategoryBreakdownList(
              report: report,
              selectedCategory: selectedCategory,
              onCategorySelected: onCategorySelected,
            ),
          ),
        ),
      ),
    );
  }

  group('CategoryBreakdownList Widget Tests', () {
    testWidgets('renders empty state when report has no data', (tester) async {
      final emptyReport = CategorySpendingReport(
        items: const [],
        totalExpense: 0,
        startDate: DateTime.utc(2026, 10, 1),
        endDate: DateTime.utc(2026, 10, 31),
      );

      await tester.pumpWidget(buildTestWidget(report: emptyReport));
      await tester.pumpAndSettle();

      expect(find.text('Category Breakdown'), findsOneWidget);
      expect(find.text('No expenses in this period'), findsOneWidget);
      expect(find.text('Categorized expenses will appear here'), findsOneWidget);
    });

    testWidgets('renders category items with amounts, percentages, tx count, and progress bars',
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

      await tester.pumpWidget(buildTestWidget(report: report));
      await tester.pumpAndSettle();

      // Card Header & Total Badge
      expect(find.text('Category Breakdown'), findsOneWidget);
      expect(find.text('Rp 1.000.000'), findsOneWidget);

      // Item 1: Food & Dining
      expect(find.text('Food & Dining'), findsOneWidget);
      expect(find.text('Rp 750.000'), findsOneWidget);
      expect(find.text('75.0%'), findsOneWidget);
      expect(find.text('3 transactions'), findsOneWidget);

      // Item 2: Transportation
      expect(find.text('Transportation'), findsOneWidget);
      expect(find.text('Rp 250.000'), findsOneWidget);
      expect(find.text('25.0%'), findsOneWidget);
      expect(find.text('1 transaction'), findsOneWidget);

      // Linear progress indicators are present
      expect(find.byType(LinearProgressIndicator), findsNWidgets(2));
    });

    testWidgets('tapping category item invokes callback with selected category and allows deselect',
        (tester) async {
      final item1 = CategorySpending(
        category: testCategory1,
        amount: 600000,
        percentage: 60.0,
        transactionCount: 2,
      );
      final item2 = CategorySpending(
        category: testCategory2,
        amount: 400000,
        percentage: 40.0,
        transactionCount: 1,
      );

      final report = CategorySpendingReport(
        items: [item1, item2],
        totalExpense: 1000000,
        startDate: DateTime.utc(2026, 10, 1),
        endDate: DateTime.utc(2026, 10, 31),
      );

      CategorySpending? selected;

      await tester.pumpWidget(
        buildTestWidget(
          report: report,
          selectedCategory: null,
          onCategorySelected: (cat) => selected = cat,
        ),
      );
      await tester.pumpAndSettle();

      // Tap Food & Dining
      await tester.tap(find.text('Food & Dining'));
      await tester.pumpAndSettle();

      expect(selected, equals(item1));

      // Re-render with item1 selected
      await tester.pumpWidget(
        buildTestWidget(
          report: report,
          selectedCategory: item1,
          onCategorySelected: (cat) => selected = cat,
        ),
      );
      await tester.pumpAndSettle();

      // Tap again to deselect
      await tester.tap(find.text('Food & Dining'));
      await tester.pumpAndSettle();

      expect(selected, isNull);
    });
  });
}
