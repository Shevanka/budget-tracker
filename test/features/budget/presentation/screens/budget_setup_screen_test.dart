import 'package:budget_tracker/core/theme/app_theme.dart';
import 'package:budget_tracker/database/app_database.dart';
import 'package:budget_tracker/database/converters/transaction_type.dart';
import 'package:budget_tracker/database/database_provider.dart';
import 'package:budget_tracker/features/budget/presentation/screens/budget_setup_screen.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.inMemory();

    // Seed test categories
    await db.categoryDao.insertCategory(
      CategoriesCompanion(
        id: const drift.Value('cat-food'),
        name: const drift.Value('Food & Dining'),
        icon: const drift.Value('restaurant'),
        color: const drift.Value(0xFF43A047),
        type: const drift.Value(TransactionType.expense),
        sortOrder: const drift.Value(0),
        createdAt: drift.Value(DateTime.utc(2026, 10, 1)),
      ),
    );
    await db.categoryDao.insertCategory(
      CategoriesCompanion(
        id: const drift.Value('cat-transport'),
        name: const drift.Value('Transportation'),
        icon: const drift.Value('directions_car'),
        color: const drift.Value(0xFF1E88E5),
        type: const drift.Value(TransactionType.expense),
        sortOrder: const drift.Value(1),
        createdAt: drift.Value(DateTime.utc(2026, 10, 1)),
      ),
    );
    await db.categoryDao.insertCategory(
      CategoriesCompanion(
        id: const drift.Value('cat-bills'),
        name: const drift.Value('Bills & Utilities'),
        icon: const drift.Value('receipt_long'),
        color: const drift.Value(0xFFE53935),
        type: const drift.Value(TransactionType.expense),
        sortOrder: const drift.Value(2),
        createdAt: drift.Value(DateTime.utc(2026, 10, 1)),
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  Widget createWidget({String initialYearMonth = '2026-10'}) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: BudgetSetupScreen(initialYearMonth: initialYearMonth),
      ),
    );
  }

  Future<void> pumpBudgetScreen(WidgetTester tester,
      {String initialYearMonth = '2026-10'}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createWidget(initialYearMonth: initialYearMonth));
    await tester.pumpAndSettle();
  }

  group('BudgetSetupScreen presentation', () {
    testWidgets('renders all screen sections and month switcher header',
        (tester) async {
      await pumpBudgetScreen(tester, initialYearMonth: '2026-10');

      expect(find.text('Budget Setup'), findsOneWidget);
      expect(find.text('October 2026'), findsOneWidget);
      expect(find.text('Monthly Budget Setup'), findsOneWidget);
      expect(find.text('Total Monthly Budget'), findsOneWidget);
      expect(find.text('Allocation Summary'), findsOneWidget);
      expect(find.text('Category Limits'), findsOneWidget);
      expect(find.text('Save Budget'), findsOneWidget);
      expect(find.text('No category limits configured'), findsOneWidget);
    });

    testWidgets('navigates previous and next month using chevron buttons',
        (tester) async {
      await pumpBudgetScreen(tester, initialYearMonth: '2026-10');

      expect(find.text('October 2026'), findsOneWidget);

      // Tap previous month
      await tester.tap(find.byTooltip('Previous month'));
      await tester.pumpAndSettle();

      expect(find.text('September 2026'), findsOneWidget);

      // Tap next month twice
      await tester.tap(find.byTooltip('Next month'));
      await tester.pumpAndSettle();
      expect(find.text('October 2026'), findsOneWidget);

      await tester.tap(find.byTooltip('Next month'));
      await tester.pumpAndSettle();
      expect(find.text('November 2026'), findsOneWidget);
    });
  });

  group('BudgetSetupScreen category limits & live summary', () {
    testWidgets('adds category limit from bottom sheet and removes it',
        (tester) async {
      await pumpBudgetScreen(tester, initialYearMonth: '2026-10');

      // Tap "Add Category"
      await tester.tap(find.widgetWithText(OutlinedButton, 'Add Category'));
      await tester.pumpAndSettle();

      // Bottom sheet appears
      expect(find.text('Select Category to Budget'), findsOneWidget);
      expect(find.text('Food & Dining'), findsOneWidget);
      expect(find.text('Transportation'), findsOneWidget);
      expect(find.text('Bills & Utilities'), findsOneWidget);

      // Select Food & Dining
      await tester.tap(find.text('Food & Dining'));
      await tester.pumpAndSettle();

      // Food & Dining is now in the list
      expect(find.text('Food & Dining'), findsOneWidget);
      expect(find.text('No category limits configured'), findsNothing);

      // Tap remove category
      await tester.tap(find.byTooltip('Remove'));
      await tester.pumpAndSettle();

      // Food & Dining is removed
      expect(find.text('Food & Dining'), findsNothing);
      expect(find.text('No category limits configured'), findsOneWidget);
    });

    testWidgets('live updates allocation summary and displays warning when overallocated',
        (tester) async {
      await pumpBudgetScreen(tester, initialYearMonth: '2026-10');

      // Set total budget to 2,000,000
      final totalBudgetField =
          find.widgetWithText(TextFormField, 'Total Budget Amount');
      await tester.enterText(totalBudgetField, '2000000');
      await tester.pumpAndSettle();

      // Add Food & Dining with 1,500,000
      await tester.tap(find.widgetWithText(OutlinedButton, 'Add Category'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Food & Dining'));
      await tester.pumpAndSettle();

      final categoryFields = find.byType(TextFormField);
      // categoryFields.last is the added category field
      await tester.enterText(categoryFields.last, '1500000');
      await tester.pumpAndSettle();

      // Allocated: 1,500,000, Unallocated: 500,000
      expect(find.text('Rp 1.500.000'), findsWidgets);
      expect(find.text('Rp 500.000'), findsOneWidget);
      expect(find.text('75% allocated'), findsOneWidget);
      expect(find.textContaining('Warning: Category limits'), findsNothing);

      // Now increase category limit to 2,500,000 -> exceeds total 2,000,000 by 500,000
      await tester.enterText(categoryFields.last, '2500000');
      await tester.pumpAndSettle();

      // Warning banner appears
      expect(
        find.textContaining('Warning: Category limits (Rp 2.500.000) exceed the total budget (Rp 2.000.000) by Rp 500.000.'),
        findsOneWidget,
      );
      expect(find.text('Over Budget'), findsOneWidget);
    });
  });

  group('BudgetSetupScreen mutations', () {
    testWidgets('validates required positive total budget amount on save',
        (tester) async {
      await pumpBudgetScreen(tester, initialYearMonth: '2026-10');

      // Attempt save with empty budget
      await tester.tap(find.text('Save Budget'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a total budget'), findsOneWidget);
    });

    testWidgets('successfully saves new budget with category limits to database',
        (tester) async {
      await pumpBudgetScreen(tester, initialYearMonth: '2026-10');

      // Enter total budget: 5,000,000
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Total Budget Amount'),
        '5000000',
      );
      await tester.pumpAndSettle();

      // Add Food & Dining category limit: 2,000,000
      await tester.tap(find.widgetWithText(OutlinedButton, 'Add Category'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Food & Dining'));
      await tester.pumpAndSettle();

      final categoryFields = find.byType(TextFormField);
      await tester.enterText(categoryFields.last, '2000000');
      await tester.pumpAndSettle();

      // Tap Save Budget
      await tester.tap(find.text('Save Budget'));
      await tester.pumpAndSettle();

      // Success snackbar appears
      expect(find.text('Budget for October 2026 saved'), findsOneWidget);

      // Verify in DB
      final savedBudget = await db.budgetDao.getBudgetForMonth('2026-10');
      expect(savedBudget, isNotNull);
      expect(savedBudget!.totalLimit, 5000000);

      final savedLimits =
          await db.budgetDao.getBudgetCategories(savedBudget.id);
      expect(savedLimits.length, 1);
      expect(savedLimits.first.categoryId, 'cat-food');
      expect(savedLimits.first.limitAmount, 2000000);
    });

    testWidgets('loads existing budget and allows deleting it with confirmation dialog',
        (tester) async {
      // Seed an existing budget for 2026-10
      await db.budgetDao.insertBudgetWithCategories(
        BudgetsCompanion(
          id: const drift.Value('b-existing'),
          yearMonth: const drift.Value('2026-10'),
          totalLimit: const drift.Value(4000000),
          createdAt: drift.Value(DateTime.utc(2026, 10, 1)),
        ),
        [
          const BudgetCategoriesCompanion(
            id: drift.Value('bc-existing-1'),
            budgetId: drift.Value('b-existing'),
            categoryId: drift.Value('cat-food'),
            limitAmount: drift.Value(1500000),
          ),
        ],
      );

      await pumpBudgetScreen(tester, initialYearMonth: '2026-10');

      // Pre-populated data is rendered
      expect(find.text('4.000.000'), findsOneWidget);
      expect(find.text('Food & Dining'), findsOneWidget);
      expect(find.text('1.500.000'), findsOneWidget);

      // Delete button appears in AppBar
      expect(find.byTooltip('Delete Budget'), findsOneWidget);

      // Tap delete
      await tester.tap(find.byTooltip('Delete Budget'));
      await tester.pumpAndSettle();

      // Confirmation dialog appears
      expect(find.text('Delete Budget'), findsWidgets);
      expect(
        find.text(
          'Are you sure you want to delete the budget for October 2026?\n\n'
          'All category limits for this month will be removed.',
        ),
        findsOneWidget,
      );

      // Cancel first
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(await db.budgetDao.getBudgetForMonth('2026-10'), isNotNull);

      // Tap delete again and confirm
      await tester.tap(find.byTooltip('Delete Budget'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Budget for October 2026 deleted'), findsOneWidget);
      expect(await db.budgetDao.getBudgetForMonth('2026-10'), isNull);
    });
  });
}
