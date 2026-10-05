import 'package:budget_tracker/database/app_database.dart';
import 'package:budget_tracker/features/categories/presentation/widgets/category_picker_field.dart';
import 'package:budget_tracker/features/categories/providers/categories_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final foodCategory = Category(
    id: 'cat-food',
    name: 'Food',
    icon: 'restaurant',
    color: 0xFF43A047,
    isDefault: true,
    isActive: true,
    sortOrder: 0,
    createdAt: DateTime.utc(2026, 10, 1),
  );

  final transportCategory = Category(
    id: 'cat-transport',
    name: 'Transport',
    icon: 'directions_car',
    color: 0xFF1E88E5,
    isDefault: true,
    isActive: true,
    sortOrder: 1,
    createdAt: DateTime.utc(2026, 10, 1),
  );

  Widget createWidget({
    String? selectedCategoryId,
    ValueChanged<Category>? onCategorySelected,
    String? errorMessage,
    List<Category>? categories,
  }) {
    return ProviderScope(
      overrides: [
        activeCategoriesProvider.overrideWith(
          (ref) => Stream.value(categories ?? [foodCategory, transportCategory]),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: CategoryPickerField(
              selectedCategoryId: selectedCategoryId,
              onCategorySelected: onCategorySelected ?? (_) {},
              errorMessage: errorMessage,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('renders placeholder when no category is selected', (tester) async {
    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    expect(find.text('Category'), findsOneWidget);
    expect(find.text('Select a category'), findsOneWidget);
  });

  testWidgets('renders error message when provided', (tester) async {
    await tester.pumpWidget(
      createWidget(errorMessage: 'Please select a category'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Please select a category'), findsOneWidget);
  });

  testWidgets('renders selected category details when categoryId is provided', (tester) async {
    await tester.pumpWidget(createWidget(selectedCategoryId: 'cat-food'));
    await tester.pumpAndSettle();

    expect(find.text('Food'), findsOneWidget);
    expect(find.byIcon(Icons.restaurant), findsOneWidget);
  });

  testWidgets('opens modal bottom sheet and selects category on tap', (tester) async {
    Category? picked;

    await tester.pumpWidget(
      createWidget(
        onCategorySelected: (cat) {
          picked = cat;
        },
      ),
    );
    await tester.pumpAndSettle();

    // Tap field to open bottom sheet
    await tester.tap(find.text('Select a category'));
    await tester.pumpAndSettle();

    expect(find.text('Select Category'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Transport'), findsOneWidget);

    // Tap Transport
    await tester.tap(find.text('Transport'));
    await tester.pumpAndSettle();

    // Bottom sheet is closed and category is selected
    expect(find.text('Select Category'), findsNothing);
    expect(picked, isNotNull);
    expect(picked!.id, 'cat-transport');
  });
}
