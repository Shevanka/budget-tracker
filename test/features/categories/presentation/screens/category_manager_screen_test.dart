import 'dart:async';

import 'package:budget_tracker/database/app_database.dart';
import 'package:budget_tracker/database/converters/transaction_type.dart';
import 'package:budget_tracker/features/categories/presentation/screens/category_manager_screen.dart';
import 'package:budget_tracker/features/categories/providers/categories_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeCategoryController extends CategoryController {
  FakeCategoryController(
    this.categories,
    this.onCategoriesChanged, {
    this.transactionCounts = const {},
  });

  final List<Category> categories;
  final VoidCallback onCategoriesChanged;
  final Map<String, int> transactionCounts;

  @override
  Future<void> build() async {}

  @override
  Future<int> getTransactionCount(String categoryId) async {
    return transactionCounts[categoryId] ?? 0;
  }

  @override
  Future<Category?> createCategory({
    required String name,
    required String icon,
    required int color,
    required TransactionType type,
  }) async {
    final newCat = Category(
      id: 'cat-created',
      name: name,
      icon: icon,
      color: color,
      type: type,
      isDefault: false,
      isActive: true,
      sortOrder: categories.length,
      createdAt: DateTime.utc(2026, 10, 1),
    );
    categories.add(newCat);
    onCategoriesChanged();
    return newCat;
  }

  @override
  Future<bool> updateCategory({
    required String id,
    required String name,
    required String icon,
    required int color,
    required TransactionType type,
  }) async {
    final index = categories.indexWhere((c) => c.id == id);
    if (index != -1) {
      final existing = categories[index];
      categories[index] = existing.copyWith(
        name: name,
        icon: icon,
        color: color,
        type: type,
      );
      onCategoriesChanged();
      return true;
    }
    return false;
  }

  @override
  Future<void> softDeleteCategory(String id) async {
    final count = transactionCounts[id] ?? 0;
    if (count > 0) {
      throw StateError(
        'Cannot delete category linked to $count existing transaction(s)',
      );
    }
    final index = categories.indexWhere((c) => c.id == id);
    if (index != -1) {
      categories[index] = categories[index].copyWith(isActive: false);
      onCategoriesChanged();
    }
  }

  @override
  Future<void> restoreCategory(String id) async {
    final index = categories.indexWhere((c) => c.id == id);
    if (index != -1) {
      categories[index] = categories[index].copyWith(isActive: true);
      onCategoriesChanged();
    }
  }
}

void main() {
  final foodCategory = Category(
    id: 'cat-food',
    name: 'Food & Dining',
    icon: 'restaurant',
    color: 0xFF43A047,
    type: TransactionType.expense,
    isDefault: true,
    isActive: true,
    sortOrder: 0,
    createdAt: DateTime.utc(2026, 10, 1),
  );

  final transportCategory = Category(
    id: 'cat-transport',
    name: 'Transportation',
    icon: 'directions_car',
    color: 0xFF1E88E5,
    type: TransactionType.expense,
    isDefault: true,
    isActive: true,
    sortOrder: 1,
    createdAt: DateTime.utc(2026, 10, 1),
  );

  final salaryCategory = Category(
    id: 'cat-salary',
    name: 'Monthly Salary',
    icon: 'payments',
    color: 0xFF2E7D32,
    type: TransactionType.income,
    isDefault: true,
    isActive: true,
    sortOrder: 0,
    createdAt: DateTime.utc(2026, 10, 1),
  );

  final oldExpenseCategory = Category(
    id: 'cat-old-exp',
    name: 'Archived Subscriptions',
    icon: 'receipt_long',
    color: 0xFFE53935,
    type: TransactionType.expense,
    isDefault: false,
    isActive: false,
    sortOrder: 2,
    createdAt: DateTime.utc(2026, 10, 1),
  );

  Widget createTestWidget({
    List<Category>? initialCats,
    Map<String, int>? transactionCounts,
  }) {
    final currentCats = initialCats ??
        List.of([
          foodCategory,
          transportCategory,
          salaryCategory,
          oldExpenseCategory,
        ]);

    final streamController = StreamController<List<Category>>.broadcast();
    addTearDown(streamController.close);

    void notify() {
      if (!streamController.isClosed) {
        streamController.add(List.of(currentCats));
      }
    }

    return ProviderScope(
      overrides: [
        categoryControllerProvider.overrideWith(
          () => FakeCategoryController(
            currentCats,
            notify,
            transactionCounts: transactionCounts ?? const {},
          ),
        ),
        categoriesByFilterProvider.overrideWith((ref, filter) {
          return Stream.multi((emitter) {
            void emitFiltered() {
              final filtered = currentCats.where((c) {
                if (!filter.includeInactive && !c.isActive) return false;
                if (filter.type != null && c.type != filter.type) return false;
                return true;
              }).toList();
              emitter.add(filtered);
            }

            emitFiltered();
            final sub = streamController.stream.listen((_) => emitFiltered());
            emitter.onCancel = sub.cancel;
          });
        }),
      ],
      child: const MaterialApp(
        home: CategoryManagerScreen(),
      ),
    );
  }

  Future<void> pumpScreen(
    WidgetTester tester, {
    List<Category>? initialCats,
    Map<String, int>? transactionCounts,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestWidget(
      initialCats: initialCats,
      transactionCounts: transactionCounts,
    ));
    await tester.pumpAndSettle();
  }

  group('CategoryManagerScreen presentation', () {
    testWidgets('renders category manager screen with tabs and category list', (tester) async {
      await pumpScreen(tester);

      expect(find.text('Category Manager'), findsOneWidget);
      expect(find.text('Expense Categories'), findsOneWidget);
      expect(find.text('Income Categories'), findsOneWidget);
      expect(find.text('Add Category'), findsOneWidget);

      // Default tab is Expense: shows Food & Dining and Transportation
      expect(find.text('Food & Dining'), findsOneWidget);
      expect(find.text('Transportation'), findsOneWidget);
      // Inactive category is hidden by default
      expect(find.text('Archived Subscriptions'), findsNothing);
      // Income category is hidden in Expense tab
      expect(find.text('Monthly Salary'), findsNothing);
    });

    testWidgets('switches to Income tab and displays income categories', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text('Income Categories'));
      await tester.pumpAndSettle();

      expect(find.text('Monthly Salary'), findsOneWidget);
      expect(find.text('Food & Dining'), findsNothing);
    });

    testWidgets('toggle show inactive reveals archived categories with Inactive chip', (tester) async {
      await pumpScreen(tester);

      expect(find.text('Archived Subscriptions'), findsNothing);

      // Tap show inactive button in AppBar
      await tester.tap(find.byTooltip('Show inactive'));
      await tester.pumpAndSettle();

      expect(find.text('Archived Subscriptions'), findsOneWidget);
      expect(find.text('Inactive'), findsOneWidget);
      expect(find.byTooltip('Restore'), findsOneWidget);
    });

    testWidgets('restore inactive category re-activates it and shows snackbar', (tester) async {
      await pumpScreen(tester);

      // Reveal inactive
      await tester.tap(find.byTooltip('Show inactive'));
      await tester.pumpAndSettle();

      // Tap restore icon
      await tester.tap(find.byTooltip('Restore'));
      await tester.pumpAndSettle();

      expect(find.text('Category "Archived Subscriptions" restored'), findsOneWidget);
    });

    testWidgets('renders empty state when no categories exist for type', (tester) async {
      await pumpScreen(tester, initialCats: []);

      expect(find.text('No expense categories'), findsOneWidget);
      expect(find.text('Add Expense Category'), findsOneWidget);
    });
  });

  group('CategoryManagerScreen mutations', () {
    testWidgets('adds a new category via Add Category bottom sheet', (tester) async {
      await pumpScreen(tester);

      // Tap "Add Category" FAB
      await tester.tap(find.text('Add Category'));
      await tester.pumpAndSettle();

      // Validate sheet appears
      expect(find.text('Add Category'), findsWidgets);
      expect(find.text('Create Category'), findsOneWidget);

      // Attempt save with empty name -> validation error
      await tester.tap(find.text('Create Category'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter a category name'), findsOneWidget);

      // Enter category name
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Category Name'),
        'Coffee & Snacks',
      );

      // Tap Create Category
      await tester.tap(find.text('Create Category'));
      await tester.pumpAndSettle();

      // Category appears in the list
      expect(find.text('Coffee & Snacks'), findsOneWidget);
    });

    testWidgets('edits existing category via edit icon button', (tester) async {
      await pumpScreen(tester);

      // Tap edit icon on Food & Dining
      final editButtons = find.byTooltip('Edit');
      await tester.tap(editButtons.first);
      await tester.pumpAndSettle();

      expect(find.text('Edit Category'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);

      // Change category name
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Category Name'),
        'Groceries & Food',
      );

      // Save changes
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      // Verify updated name in UI
      expect(find.text('Groceries & Food'), findsOneWidget);
    });

    testWidgets('soft-deletes category with confirmation and restores via undo snackbar', (tester) async {
      await pumpScreen(tester);

      // Tap delete icon on Food & Dining
      final deleteButtons = find.byTooltip('Delete');
      await tester.tap(deleteButtons.first);
      await tester.pumpAndSettle();

      // Dialog appears
      expect(find.text('Delete Category'), findsOneWidget);
      expect(
        find.text('Are you sure you want to delete "Food & Dining"?\n\n'
            'Existing transactions will preserve this category, but it will no longer be available for new transactions.'),
        findsOneWidget,
      );

      // Cancel first
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Food & Dining'), findsOneWidget);

      // Tap delete again and confirm
      await tester.tap(deleteButtons.first);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      // Snackbar appears and category is hidden
      expect(find.text('Category "Food & Dining" deleted'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
      expect(find.text('Food & Dining'), findsNothing);

      // Tap Undo
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      // Category is restored
      expect(find.text('Food & Dining'), findsOneWidget);
    });

    testWidgets('tapping delete on category with existing transactions shows prevention dialog with count and does not delete', (tester) async {
      await pumpScreen(
        tester,
        transactionCounts: {
          'cat-food': 3,
        },
      );

      // Tap delete icon on Food & Dining
      final deleteButtons = find.byTooltip('Delete');
      await tester.tap(deleteButtons.first);
      await tester.pumpAndSettle();

      // Prevention alert dialog appears
      expect(find.text('Cannot Delete Category'), findsOneWidget);
      expect(
        find.text(
          'Cannot delete "Food & Dining" because it is linked to 3 transactions.\n\n'
          'Please reassign or delete these transactions before deleting this category.',
        ),
        findsOneWidget,
      );
      expect(find.widgetWithText(FilledButton, 'OK'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.widgetWithText(FilledButton, 'OK'));
      await tester.pumpAndSettle();

      // Dialog is dismissed and Food & Dining is still visible and active
      expect(find.text('Cannot Delete Category'), findsNothing);
      expect(find.text('Food & Dining'), findsOneWidget);
    });
  });
}
