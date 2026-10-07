import 'package:budget_tracker/database/converters/transaction_type.dart';
import 'package:budget_tracker/features/categories/presentation/widgets/category_icon_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CategoryIconPicker', () {
    testWidgets('renders search field, filter chips, and icon grid', (tester) async {
      IconData selected = Icons.restaurant;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryIconPicker(
              selectedIcon: selected,
              selectedColor: 0xFF43A047,
              onIconSelected: (val) => selected = val,
            ),
          ),
        ),
      );

      expect(find.text('Icon'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Transport'), findsOneWidget);
      expect(find.text('Finance'), findsOneWidget);
      expect(find.byIcon(Icons.restaurant), findsOneWidget);
    });

    testWidgets('defaults to Finance group when categoryType is income', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryIconPicker(
              selectedIcon: Icons.payments,
              selectedColor: 0xFF2E7D32,
              categoryType: TransactionType.income,
              onIconSelected: (_) {},
            ),
          ),
        ),
      );

      final financeChip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Finance'),
      );
      expect(financeChip.selected, isTrue);
      expect(find.byIcon(Icons.payments), findsOneWidget);
    });

    testWidgets('filters icons by group chip selection', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryIconPicker(
              selectedIcon: Icons.restaurant,
              selectedColor: 0xFF43A047,
              onIconSelected: (_) {},
            ),
          ),
        ),
      );

      // Tap Transport chip
      await tester.tap(find.widgetWithText(ChoiceChip, 'Transport'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.directions_car), findsOneWidget);
      expect(find.byIcon(Icons.restaurant), findsNothing);
    });

    testWidgets('searches icons by text query and clears search', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryIconPicker(
              selectedIcon: Icons.restaurant,
              selectedColor: 0xFF43A047,
              onIconSelected: (_) {},
            ),
          ),
        ),
      );

      // Search 'pizza'
      await tester.enterText(find.byType(TextField), 'pizza');
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.local_pizza), findsOneWidget);
      expect(find.byIcon(Icons.directions_car), findsNothing);

      // Clear search
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.restaurant), findsOneWidget);
    });

    testWidgets('shows empty state when search query matches nothing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryIconPicker(
              selectedIcon: Icons.restaurant,
              selectedColor: 0xFF43A047,
              onIconSelected: (_) {},
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'xyznonexistent123');
      await tester.pumpAndSettle();

      expect(find.text('No icons match "xyznonexistent123"'), findsOneWidget);
      expect(find.byIcon(Icons.search_off), findsOneWidget);
    });

    testWidgets('calls onIconSelected when an icon is tapped', (tester) async {
      IconData? selected;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryIconPicker(
              selectedIcon: Icons.restaurant,
              selectedColor: 0xFF43A047,
              onIconSelected: (val) => selected = val,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.fastfood));
      await tester.pumpAndSettle();

      expect(selected, Icons.fastfood);
    });
  });
}
