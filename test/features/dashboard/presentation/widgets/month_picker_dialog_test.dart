import 'package:budget_tracker/core/theme/app_theme.dart';
import 'package:budget_tracker/core/utils/year_month_utils.dart';
import 'package:budget_tracker/features/dashboard/presentation/widgets/month_picker_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildTestDialog({
    String initialYearMonth = '2026-06',
    int minYear = 2020,
    int maxYear = 2030,
    ValueChanged<String?>? onResult,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              final result = await showMonthPickerDialog(
                context: context,
                initialYearMonth: initialYearMonth,
                minYear: minYear,
                maxYear: maxYear,
              );
              onResult?.call(result);
            },
            child: const Text('Open Dialog'),
          ),
        ),
      ),
    );
  }

  group('MonthPickerDialog Widget Tests', () {
    testWidgets('renders initial year and 12 months with selected month highlighted',
        (tester) async {
      await tester.pumpWidget(buildTestDialog(initialYearMonth: '2026-06'));
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Check header year
      expect(find.text('2026'), findsOneWidget);

      // Check all 12 month abbreviations are displayed
      for (final m in [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ]) {
        expect(find.text(m), findsOneWidget);
      }

      // Check 'Jun' (index 6) is a FilledButton because initial is 2026-06
      final filledBtn = find.widgetWithText(FilledButton, 'Jun');
      expect(filledBtn, findsOneWidget);

      // Check footer actions
      expect(find.text('This Month'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('navigates years with chevron buttons and respects min/max boundaries',
        (tester) async {
      await tester.pumpWidget(buildTestDialog(
        initialYearMonth: '2025-01',
        minYear: 2024,
        maxYear: 2026,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('2025'), findsOneWidget);

      final nextYearBtn = find.widgetWithIcon(IconButton, Icons.chevron_right_rounded);
      final prevYearBtn = find.widgetWithIcon(IconButton, Icons.chevron_left_rounded);

      // Tap next year -> 2026
      await tester.tap(nextYearBtn);
      await tester.pumpAndSettle();
      expect(find.text('2026'), findsOneWidget);

      // At maxYear (2026), next year button should be disabled
      final nextWidget = tester.widget<IconButton>(nextYearBtn);
      expect(nextWidget.onPressed, isNull);

      // Tap prev year twice -> 2025 -> 2024
      await tester.tap(prevYearBtn);
      await tester.pumpAndSettle();
      expect(find.text('2025'), findsOneWidget);

      await tester.tap(prevYearBtn);
      await tester.pumpAndSettle();
      expect(find.text('2024'), findsOneWidget);

      // At minYear (2024), previous year button should be disabled
      final prevWidget = tester.widget<IconButton>(prevYearBtn);
      expect(prevWidget.onPressed, isNull);
    });

    testWidgets('tapping a month pops dialog with selected year-month string',
        (tester) async {
      String? selected;
      await tester.pumpWidget(buildTestDialog(
        initialYearMonth: '2026-03',
        onResult: (val) => selected = val,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Tap 'Oct'
      await tester.tap(find.text('Oct'));
      await tester.pumpAndSettle();

      // Dialog closed
      expect(find.byType(MonthPickerDialog), findsNothing);
      expect(selected, '2026-10');
    });

    testWidgets('selecting month across navigated year returns correct year-month',
        (tester) async {
      String? selected;
      await tester.pumpWidget(buildTestDialog(
        initialYearMonth: '2025-01',
        minYear: 2020,
        maxYear: 2030,
        onResult: (val) => selected = val,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      final nextYearBtn = find.widgetWithIcon(IconButton, Icons.chevron_right_rounded);

      // Navigate to 2027
      await tester.tap(nextYearBtn);
      await tester.pumpAndSettle();
      await tester.tap(nextYearBtn);
      await tester.pumpAndSettle();
      expect(find.text('2027'), findsOneWidget);

      // Tap 'Feb'
      await tester.tap(find.text('Feb'));
      await tester.pumpAndSettle();

      expect(find.byType(MonthPickerDialog), findsNothing);
      expect(selected, '2027-02');
    });

    testWidgets('tapping "This Month" pops dialog with current real year-month',
        (tester) async {
      String? selected;
      final currentRealMonth = YearMonthUtils.currentYearMonth();

      await tester.pumpWidget(buildTestDialog(
        initialYearMonth: '2020-01',
        onResult: (val) => selected = val,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Tap 'This Month'
      await tester.tap(find.text('This Month'));
      await tester.pumpAndSettle();

      expect(find.byType(MonthPickerDialog), findsNothing);
      expect(selected, currentRealMonth);
    });

    testWidgets('tapping "Cancel" pops dialog with null result',
        (tester) async {
      String? selected = 'initial-value';
      await tester.pumpWidget(buildTestDialog(
        initialYearMonth: '2026-05',
        onResult: (val) => selected = val,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Tap 'Cancel'
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(MonthPickerDialog), findsNothing);
      expect(selected, isNull);
    });
  });
}
