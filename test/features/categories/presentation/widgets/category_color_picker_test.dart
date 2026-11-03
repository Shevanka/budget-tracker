import 'package:budget_tracker/features/categories/presentation/widgets/category_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CategoryColorPicker', () {
    testWidgets('renders all default palette colors with selection checkmark', (tester) async {
      int selected = CategoryColorPicker.defaultColors.first;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryColorPicker(
              selectedColor: selected,
              onColorSelected: (val) => selected = val,
            ),
          ),
        ),
      );

      expect(find.text('Color'), findsOneWidget);
      expect(find.text('Red'), findsOneWidget); // First color is Red (0xFFE53935)
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('calls onColorSelected when a color circle is tapped', (tester) async {
      int? selected;
      const targetColor = 0xFF1E88E5; // Blue

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryColorPicker(
              selectedColor: CategoryColorPicker.defaultColors.first,
              onColorSelected: (val) => selected = val,
            ),
          ),
        ),
      );

      // Find the blue color circle tooltip / semantics
      final blueCircle = find.byTooltip('Blue');
      expect(blueCircle, findsOneWidget);

      await tester.tap(blueCircle);
      await tester.pumpAndSettle();

      expect(selected, targetColor);
    });

    testWidgets('renders custom colors when provided', (tester) async {
      const customColors = [0xFF112233, 0xFF445566];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryColorPicker(
              selectedColor: 0xFF112233,
              colors: customColors,
              onColorSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(GestureDetector), findsNWidgets(2));
    });
  });
}
