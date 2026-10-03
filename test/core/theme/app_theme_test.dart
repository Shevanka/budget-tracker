import 'package:budget_tracker/core/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppColors', () {
    test('categoryPalette has 16 distinct colors', () {
      expect(AppColors.categoryPalette.length, 16);
      final uniqueColors = AppColors.categoryPalette.toSet();
      expect(uniqueColors.length, 16);
    });

    test('budget status colors are distinct', () {
      expect(AppColors.budgetSafe, isNot(equals(AppColors.budgetWarning)));
      expect(AppColors.budgetWarning, isNot(equals(AppColors.budgetDanger)));
    });
  });

  group('AppCustomColors ThemeExtension', () {
    test('can be accessed from ThemeData extensions', () {
      final theme = AppTheme.lightTheme;
      final customColors = theme.extension<AppCustomColors>();

      expect(customColors, isNotNull);
      expect(customColors!.income, equals(AppColors.income));
      expect(customColors.expense, equals(AppColors.expense));
      expect(customColors.budgetSafe, equals(AppColors.budgetSafe));
      expect(customColors.budgetWarning, equals(AppColors.budgetWarning));
      expect(customColors.budgetDanger, equals(AppColors.budgetDanger));
    });

    test('copyWith updates specified fields', () {
      const original = AppCustomColors(
        income: Colors.green,
        expense: Colors.red,
        budgetSafe: Colors.green,
        budgetWarning: Colors.orange,
        budgetDanger: Colors.red,
      );

      final modified = original.copyWith(income: Colors.blue);
      expect(modified.income, equals(Colors.blue));
      expect(modified.expense, equals(Colors.red));
      expect(modified.budgetSafe, equals(Colors.green));
    });

    test('lerp interpolates correctly between two instances', () {
      const a = AppCustomColors(
        income: Color(0xFF000000),
        expense: Color(0xFF000000),
        budgetSafe: Color(0xFF000000),
        budgetWarning: Color(0xFF000000),
        budgetDanger: Color(0xFF000000),
      );

      const b = AppCustomColors(
        income: Color(0xFFFFFFFF),
        expense: Color(0xFFFFFFFF),
        budgetSafe: Color(0xFFFFFFFF),
        budgetWarning: Color(0xFFFFFFFF),
        budgetDanger: Color(0xFFFFFFFF),
      );

      final half = a.lerp(b, 0.5);
      expect(half.income, equals(Color.lerp(a.income, b.income, 0.5)));
      expect(half.lerp(null, 0.5), equals(half));
    });

    testWidgets('AppCustomColorsX extension works on BuildContext', (tester) async {
      late AppCustomColors retrievedColors;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
            builder: (context) {
              retrievedColors = context.customColors;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(retrievedColors.income, equals(AppColors.income));
      expect(retrievedColors.expense, equals(AppColors.expense));
    });
  });

  group('AppTheme', () {
    test('lightTheme has Material 3 enabled and light brightness', () {
      final theme = AppTheme.lightTheme;

      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, equals(Brightness.light));
      expect(theme.colorScheme.brightness, equals(Brightness.light));
    });

    test('lightTheme has styled components', () {
      final theme = AppTheme.lightTheme;

      expect(theme.appBarTheme.centerTitle, isTrue);
      expect(theme.appBarTheme.elevation, equals(0));
      expect(theme.cardTheme.shape, isA<RoundedRectangleBorder>());
      expect(theme.inputDecorationTheme.filled, isTrue);
      expect(theme.navigationBarTheme.labelBehavior,
          equals(NavigationDestinationLabelBehavior.alwaysShow));
    });
  });
}
