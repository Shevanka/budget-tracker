import 'package:budget_tracker/core/theme/app_theme.dart';
import 'package:budget_tracker/core/utils/year_month_utils.dart';
import 'package:budget_tracker/database/app_database.dart';
import 'package:budget_tracker/database/converters/transaction_type.dart';
import 'package:budget_tracker/features/budget/domain/models/budget_status.dart';
import 'package:budget_tracker/features/budget/presentation/widgets/category_budget_progress_tile.dart';
import 'package:budget_tracker/features/budget/presentation/widgets/monthly_budget_card.dart';
import 'package:budget_tracker/features/budget/providers/budget_provider.dart';
import 'package:budget_tracker/features/dashboard/presentation/widgets/dashboard_budget_section.dart';
import 'package:budget_tracker/routing/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class MockBudgetController extends BudgetController {
  bool copyCalled = false;
  String? fromMonth;
  String? toMonth;
  bool copyResult = true;

  @override
  Future<void> build() async {}

  @override
  Future<bool> copyBudget({
    required String fromYearMonth,
    required String toYearMonth,
  }) async {
    copyCalled = true;
    fromMonth = fromYearMonth;
    toMonth = toYearMonth;
    return copyResult;
  }
}

void main() {
  final currentMonth = YearMonthUtils.currentYearMonth();
  final prevMonth = YearMonthUtils.previousYearMonth(currentMonth);

  final catFood = Category(
    id: 'cat-food',
    name: 'Food & Dining',
    icon: 'restaurant',
    color: 0xFF43A047,
    type: TransactionType.expense,
    isDefault: true,
    isActive: true,
    sortOrder: 0,
    createdAt: DateTime.utc(2026, 1, 1),
  );

  final catTransport = Category(
    id: 'cat-transport',
    name: 'Transportation',
    icon: 'directions_car',
    color: 0xFF1E88E5,
    type: TransactionType.expense,
    isDefault: true,
    isActive: true,
    sortOrder: 1,
    createdAt: DateTime.utc(2026, 1, 1),
  );

  final catShopping = Category(
    id: 'cat-shopping',
    name: 'Shopping',
    icon: 'shopping_bag',
    color: 0xFFFB8C00,
    type: TransactionType.expense,
    isDefault: true,
    isActive: true,
    sortOrder: 2,
    createdAt: DateTime.utc(2026, 1, 1),
  );

  final catEntertainment = Category(
    id: 'cat-ent',
    name: 'Entertainment',
    icon: 'movie',
    color: 0xFF8E24AA,
    type: TransactionType.expense,
    isDefault: false,
    isActive: true,
    sortOrder: 3,
    createdAt: DateTime.utc(2026, 1, 1),
  );

  Widget createWidget({
    required AsyncValue<MonthlyBudgetStatus> budgetStatusAsync,
    Budget? previousBudget,
    BudgetController? budgetController,
  }) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: SingleChildScrollView(
              child: DashboardBudgetSection(selectedYearMonth: currentMonth),
            ),
          ),
        ),
        GoRoute(
          path: AppRoute.budgetSetup.path,
          builder: (context, state) => const Scaffold(
            body: Text('Budget Setup Screen Target'),
          ),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        if (budgetController != null)
          budgetControllerProvider.overrideWith(() => budgetController),
        monthlyBudgetStatusProvider(currentMonth).overrideWith(
          (ref) => budgetStatusAsync.when(
            data: (data) => Stream.value(data),
            error: (err, st) => Stream.error(err, st),
            loading: () => const Stream.empty(),
          ),
        ),
        previousAvailableBudgetProvider(currentMonth).overrideWith(
          (ref) => Future.value(previousBudget),
        ),
      ],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        routerConfig: router,
      ),
    );
  }

  group('DashboardBudgetSection', () {
    testWidgets('renders active monthly budget, overall progress bar, and category tiles',
        (tester) async {
      final status = MonthlyBudgetStatus.calculate(
        yearMonth: currentMonth,
        totalLimit: 5000000,
        totalSpent: 2500000,
        categoryStatuses: [
          CategoryBudgetStatus.calculate(
            category: catFood,
            limit: 2000000,
            spent: 1200000,
          ),
          CategoryBudgetStatus.calculate(
            category: catTransport,
            limit: 1000000,
            spent: 800000,
          ),
        ],
        unbudgetedSpent: 500000,
      );

      await tester.pumpWidget(
        createWidget(budgetStatusAsync: AsyncValue.data(status)),
      );
      await tester.pumpAndSettle();

      // Section Header
      expect(find.text('Budget Progress'), findsOneWidget);
      expect(find.text('Manage'), findsOneWidget);

      // Monthly Budget Card
      expect(find.byType(MonthlyBudgetCard), findsOneWidget);
      expect(find.text('Rp 2.500.000'), findsOneWidget);
      expect(find.text('of Rp 5.000.000'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
      expect(find.text('Remaining: Rp 2.500.000'), findsOneWidget);

      // Category Budgets Header & Tiles
      expect(find.text('Category Budgets'), findsOneWidget);
      expect(find.byType(CategoryBudgetProgressTile), findsNWidgets(2));
      expect(find.text('Food & Dining'), findsOneWidget);
      expect(find.text('Transportation'), findsOneWidget);
    });

    testWidgets('displays View All button when more than 3 categories are configured',
        (tester) async {
      final status = MonthlyBudgetStatus.calculate(
        yearMonth: currentMonth,
        totalLimit: 10000000,
        totalSpent: 4000000,
        categoryStatuses: [
          CategoryBudgetStatus.calculate(
            category: catFood,
            limit: 3000000,
            spent: 1500000,
          ),
          CategoryBudgetStatus.calculate(
            category: catTransport,
            limit: 2000000,
            spent: 1000000,
          ),
          CategoryBudgetStatus.calculate(
            category: catShopping,
            limit: 2000000,
            spent: 800000,
          ),
          CategoryBudgetStatus.calculate(
            category: catEntertainment,
            limit: 1000000,
            spent: 700000,
          ),
        ],
        unbudgetedSpent: 0,
      );

      await tester.pumpWidget(
        createWidget(budgetStatusAsync: AsyncValue.data(status)),
      );
      await tester.pumpAndSettle();

      // Only top 3 tiles are rendered on the dashboard
      expect(find.byType(CategoryBudgetProgressTile), findsNWidgets(3));
      expect(find.text('View All'), findsOneWidget);

      // Tapping "View All" navigates to Budget Setup
      await tester.tap(find.text('View All'));
      await tester.pumpAndSettle();
      expect(find.text('Budget Setup Screen Target'), findsOneWidget);
    });

    testWidgets('renders empty state card when no budget is set for the month',
        (tester) async {
      final status = MonthlyBudgetStatus.calculate(
        yearMonth: currentMonth,
        totalLimit: 0,
        totalSpent: 0,
        categoryStatuses: const [],
        unbudgetedSpent: 0,
      );

      await tester.pumpWidget(
        createWidget(budgetStatusAsync: AsyncValue.data(status)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Budget Progress'), findsOneWidget);
      expect(find.textContaining('No Budget Set for'), findsOneWidget);
      expect(find.text('Set Up Budget'), findsOneWidget);
      expect(find.byType(CategoryBudgetProgressTile), findsNothing);

      // Tapping "Set Up Budget" navigates to Budget Setup
      await tester.tap(find.text('Set Up Budget'));
      await tester.pumpAndSettle();
      expect(find.text('Budget Setup Screen Target'), findsOneWidget);
    });

    testWidgets('allows copying previous month budget when available',
        (tester) async {
      final status = MonthlyBudgetStatus.calculate(
        yearMonth: currentMonth,
        totalLimit: 0,
        totalSpent: 0,
        categoryStatuses: const [],
        unbudgetedSpent: 0,
      );

      final prevBudget = Budget(
        id: 'budget-prev',
        yearMonth: prevMonth,
        totalLimit: 4500000,
        createdAt: DateTime.utc(2026, 9, 1),
      );

      final mockController = MockBudgetController();

      await tester.pumpWidget(
        createWidget(
          budgetStatusAsync: AsyncValue.data(status),
          previousBudget: prevBudget,
          budgetController: mockController,
        ),
      );
      await tester.pumpAndSettle();

      final copyText = 'Copy ${YearMonthUtils.formatDisplay(prevMonth)}';
      expect(find.text(copyText), findsOneWidget);

      await tester.tap(find.text(copyText));
      await tester.pumpAndSettle();

      expect(mockController.copyCalled, isTrue);
      expect(mockController.fromMonth, prevMonth);
      expect(mockController.toMonth, currentMonth);
      expect(find.textContaining('Copied budget from'), findsOneWidget);
    });

    testWidgets('renders error card when budget status fails to load',
        (tester) async {
      await tester.pumpWidget(
        createWidget(
          budgetStatusAsync: AsyncValue.error(
            Exception('Database query failed'),
            StackTrace.empty,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Failed to load budget status'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('tapping Manage button in section header navigates to budget setup',
        (tester) async {
      final status = MonthlyBudgetStatus.calculate(
        yearMonth: currentMonth,
        totalLimit: 5000000,
        totalSpent: 2000000,
        categoryStatuses: const [],
        unbudgetedSpent: 0,
      );

      await tester.pumpWidget(
        createWidget(budgetStatusAsync: AsyncValue.data(status)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Manage'));
      await tester.pumpAndSettle();
      expect(find.text('Budget Setup Screen Target'), findsOneWidget);
    });

    testWidgets('tapping a category tile navigates to budget setup',
        (tester) async {
      final status = MonthlyBudgetStatus.calculate(
        yearMonth: currentMonth,
        totalLimit: 5000000,
        totalSpent: 1000000,
        categoryStatuses: [
          CategoryBudgetStatus.calculate(
            category: catFood,
            limit: 2000000,
            spent: 1000000,
          ),
        ],
        unbudgetedSpent: 0,
      );

      await tester.pumpWidget(
        createWidget(budgetStatusAsync: AsyncValue.data(status)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(CategoryBudgetProgressTile).first);
      await tester.pumpAndSettle();
      expect(find.text('Budget Setup Screen Target'), findsOneWidget);
    });
  });
}
