import 'package:budget_tracker/core/theme/app_theme.dart';
import 'package:budget_tracker/database/app_database.dart';
import 'package:budget_tracker/database/converters/transaction_type.dart';
import 'package:budget_tracker/features/budget/domain/models/budget_status.dart';
import 'package:budget_tracker/features/budget/presentation/widgets/budget_progress_bar.dart';
import 'package:budget_tracker/features/budget/presentation/widgets/category_budget_progress_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final sampleCategory = Category(
    id: 'cat-food',
    name: 'Food & Dining',
    icon: 'restaurant',
    color: 0xFF43A047,
    type: TransactionType.expense,
    sortOrder: 1,
    isDefault: true,
    isActive: true,
    createdAt: DateTime.utc(2026, 1, 1),
  );

  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }

  group('CategoryBudgetProgressTile', () {
    testWidgets('renders category details, formatted amounts, and percentage badge',
        (tester) async {
      final status = CategoryBudgetStatus.calculate(
        category: sampleCategory,
        limit: 1000000,
        spent: 850000,
      );

      await tester.pumpWidget(
        buildTestableWidget(
          CategoryBudgetProgressTile(status: status),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Food & Dining'), findsOneWidget);
      expect(find.text('Rp 850.000 / Rp 1.000.000'), findsOneWidget);
      expect(find.text('85%'), findsOneWidget);
      expect(find.text('Remaining: Rp 150.000'), findsOneWidget);
      expect(find.text('Near limit'), findsOneWidget);
      expect(find.byType(BudgetProgressBar), findsOneWidget);
    });

    testWidgets('renders exceeded message when spending surpasses limit',
        (tester) async {
      final status = CategoryBudgetStatus.calculate(
        category: sampleCategory,
        limit: 1000000,
        spent: 1250000,
      );

      await tester.pumpWidget(
        buildTestableWidget(
          CategoryBudgetProgressTile(status: status),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Exceeded by Rp 250.000'), findsOneWidget);
      expect(find.text('125%'), findsOneWidget);
    });

    testWidgets('renders unbudgeted category with No Limit badge',
        (tester) async {
      final status = CategoryBudgetStatus.calculate(
        category: sampleCategory,
        limit: 0,
        spent: 350000,
      );

      await tester.pumpWidget(
        buildTestableWidget(
          CategoryBudgetProgressTile(status: status),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Food & Dining'), findsOneWidget);
      expect(find.text('Rp 350.000'), findsOneWidget);
      expect(find.text('No Limit'), findsOneWidget);
      expect(find.byType(BudgetProgressBar), findsNothing);
    });

    testWidgets('triggers onTap callback when card is clicked', (tester) async {
      var tapped = false;
      final status = CategoryBudgetStatus.calculate(
        category: sampleCategory,
        limit: 1000000,
        spent: 500000,
      );

      await tester.pumpWidget(
        buildTestableWidget(
          CategoryBudgetProgressTile(
            status: status,
            onTap: () => tapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(CategoryBudgetProgressTile));
      expect(tapped, isTrue);
    });

    testWidgets('renders compact mode without error', (tester) async {
      final status = CategoryBudgetStatus.calculate(
        category: sampleCategory,
        limit: 1000000,
        spent: 400000,
      );

      await tester.pumpWidget(
        buildTestableWidget(
          CategoryBudgetProgressTile(
            status: status,
            compact: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Food & Dining'), findsOneWidget);
      expect(find.text('40%'), findsOneWidget);
    });
  });
}
