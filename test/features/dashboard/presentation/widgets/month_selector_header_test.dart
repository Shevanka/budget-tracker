import 'package:budget_tracker/core/theme/app_theme.dart';
import 'package:budget_tracker/core/utils/year_month_utils.dart';
import 'package:budget_tracker/features/dashboard/presentation/widgets/month_picker_dialog.dart';
import 'package:budget_tracker/features/dashboard/presentation/widgets/month_selector_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final currentMonth = YearMonthUtils.currentYearMonth();
  const pastMonth = '2024-03';

  Widget buildTestHeader({
    required String selectedYearMonth,
    VoidCallback? onPrevious,
    VoidCallback? onNext,
    VoidCallback? onResetCurrent,
    ValueChanged<String>? onMonthSelected,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: MonthSelectorHeader(
            selectedYearMonth: selectedYearMonth,
            onPrevious: onPrevious ?? () {},
            onNext: onNext ?? () {},
            onResetCurrent: onResetCurrent,
            onMonthSelected: onMonthSelected,
          ),
        ),
      ),
    );
  }

  group('MonthSelectorHeader Widget Tests', () {
    testWidgets('renders month title, calendar icon, and chevrons',
        (tester) async {
      await tester.pumpWidget(buildTestHeader(selectedYearMonth: '2026-10'));
      await tester.pumpAndSettle();

      expect(find.text(YearMonthUtils.formatDisplay('2026-10')), findsOneWidget);
      expect(find.byIcon(Icons.calendar_month_outlined), findsOneWidget);
      expect(find.byTooltip('Previous month'), findsOneWidget);
      expect(find.byTooltip('Next month'), findsOneWidget);
    });

    testWidgets('triggers onPrevious and onNext callbacks on chevron taps',
        (tester) async {
      var prevCalled = false;
      var nextCalled = false;

      await tester.pumpWidget(
        buildTestHeader(
          selectedYearMonth: '2026-10',
          onPrevious: () => prevCalled = true,
          onNext: () => nextCalled = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Previous month'));
      expect(prevCalled, isTrue);

      await tester.tap(find.byTooltip('Next month'));
      expect(nextCalled, isTrue);
    });

    testWidgets(
        'renders "This Month" chip for past month and triggers onResetCurrent on tap',
        (tester) async {
      var resetCalled = false;

      await tester.pumpWidget(
        buildTestHeader(
          selectedYearMonth: pastMonth,
          onResetCurrent: () => resetCalled = true,
        ),
      );
      await tester.pumpAndSettle();

      final thisMonthChip = find.text('This Month');
      expect(thisMonthChip, findsOneWidget);

      await tester.tap(thisMonthChip);
      expect(resetCalled, isTrue);
    });

    testWidgets('does not render "This Month" chip when selected month is current month',
        (tester) async {
      await tester.pumpWidget(
        buildTestHeader(
          selectedYearMonth: currentMonth,
          onResetCurrent: () {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('This Month'), findsNothing);
    });

    testWidgets('does not render "This Month" chip when onResetCurrent is null',
        (tester) async {
      await tester.pumpWidget(
        buildTestHeader(
          selectedYearMonth: pastMonth,
          onResetCurrent: null,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('This Month'), findsNothing);
    });

    testWidgets(
        'tapping header with onMonthSelected opens MonthPickerDialog and delivers picked month',
        (tester) async {
      String? pickedMonth;

      await tester.pumpWidget(
        buildTestHeader(
          selectedYearMonth: '2026-10',
          onMonthSelected: (month) => pickedMonth = month,
        ),
      );
      await tester.pumpAndSettle();

      // Dropdown arrow should be present
      expect(find.byIcon(Icons.arrow_drop_down_rounded), findsOneWidget);

      // Tap header to open dialog
      await tester.tap(find.text(YearMonthUtils.formatDisplay('2026-10')));
      await tester.pumpAndSettle();

      expect(find.byType(MonthPickerDialog), findsOneWidget);

      // Pick 'Dec'
      await tester.tap(find.text('Dec'));
      await tester.pumpAndSettle();

      expect(find.byType(MonthPickerDialog), findsNothing);
      expect(pickedMonth, '2026-12');
    });

    testWidgets('does not show dropdown arrow when onMonthSelected is null',
        (tester) async {
      await tester.pumpWidget(
        buildTestHeader(
          selectedYearMonth: '2026-10',
          onMonthSelected: null,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_drop_down_rounded), findsNothing);
    });
  });
}
