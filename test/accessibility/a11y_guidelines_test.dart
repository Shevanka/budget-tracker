import 'package:budget_tracker/core/theme/app_colors.dart';
import 'package:budget_tracker/core/theme/app_theme.dart';
import 'package:budget_tracker/core/widgets/app_empty_state.dart';
import 'package:budget_tracker/core/widgets/app_loading_state.dart';
import 'package:budget_tracker/database/app_database.dart';
import 'package:budget_tracker/database/converters/transaction_type.dart';
import 'package:budget_tracker/database/daos/transaction_dao.dart';
import 'package:budget_tracker/features/dashboard/domain/models/financial_summary.dart';
import 'package:budget_tracker/features/dashboard/presentation/widgets/balance_card.dart';
import 'package:budget_tracker/features/dashboard/presentation/widgets/income_expense_summary_card.dart';
import 'package:budget_tracker/features/dashboard/presentation/widgets/month_selector_header.dart';
import 'package:budget_tracker/features/transactions/domain/models/daily_transaction_group.dart';
import 'package:budget_tracker/features/transactions/presentation/widgets/daily_group_header.dart';
import 'package:budget_tracker/features/transactions/presentation/widgets/transaction_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Accessibility & WCAG AA Contrast Guidelines', () {
    test('budgetWarning color meets WCAG AA 4.5:1 contrast ratio against white background', () {
      final textLum = AppColors.budgetWarning.computeLuminance();
      final bgLum = Colors.white.computeLuminance();

      final l1 = bgLum > textLum ? bgLum : textLum;
      final l2 = bgLum > textLum ? textLum : bgLum;
      final contrastRatio = (l1 + 0.05) / (l2 + 0.05);

      // Must meet WCAG AA normal text requirement (>= 4.5:1)
      expect(contrastRatio, greaterThanOrEqualTo(4.5));
    });

    testWidgets('AppLoadingState provides semanticsLabel for screen readers', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppLoadingState(message: 'Memuat data transaksi...'),
          ),
        ),
      );

      final progressFinder = find.byType(CircularProgressIndicator);
      expect(progressFinder, findsOneWidget);
      final progressWidget = tester.widget<CircularProgressIndicator>(progressFinder);
      expect(progressWidget.semanticsLabel, 'Memuat data transaksi...');
    });

    testWidgets('BalanceCard exposes descriptive semantics label', (tester) async {
      const summary = MonthlyFinancialSummary(
        yearMonth: '2026-11',
        totalIncome: 10000000,
        totalExpense: 4000000,
        netBalance: 6000000,
        transactionCount: 8,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: BalanceCard(summary: summary),
          ),
        ),
      );

      expect(
        find.bySemanticsLabel(RegExp(r'Net Balance.*Rp\s*6\.000\.000.*Surplus')),
        findsOneWidget,
      );
    });

    testWidgets('IncomeExpenseSummaryCard exposes separate income and expense semantics', (tester) async {
      const summary = MonthlyFinancialSummary(
        yearMonth: '2026-11',
        totalIncome: 10000000,
        totalExpense: 4000000,
        netBalance: 6000000,
        transactionCount: 8,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: IncomeExpenseSummaryCard(summary: summary),
          ),
        ),
      );

      expect(
        find.bySemanticsLabel(RegExp(r'Total Pemasukan: Rp\s*10\.000\.000')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp(r'Total Pengeluaran: Rp\s*4\.000\.000')),
        findsOneWidget,
      );
    });

    testWidgets('DailyGroupHeader is marked as a semantic header', (tester) async {
      final group = DailyTransactionGroup(
        date: DateTime(2026, 11, 3),
        items: const [],
        totalExpense: 75000,
        totalIncome: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: DailyGroupHeader(group: group),
          ),
        ),
      );

      // Verify header semantics
      final headerFinder = find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.header == true,
      );
      expect(headerFinder, findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp(r'pengeluaran Rp\s*75\.000')),
        findsOneWidget,
      );
    });

    testWidgets('TransactionListTile provides full transaction context and button semantics', (tester) async {
      final category = Category(
        id: 'cat-food',
        name: 'Makanan',
        icon: 'restaurant',
        color: 0xFF4CAF50,
        type: TransactionType.expense,
        isDefault: false,
        isActive: true,
        sortOrder: 0,
        createdAt: DateTime.utc(2026, 1, 1),
      );

      final transaction = Transaction(
        id: 'tx-1',
        amount: 35000,
        type: TransactionType.expense,
        categoryId: 'cat-food',
        date: DateTime.utc(2026, 11, 3, 12, 30),
        note: 'Makan Siang Nasi Padang',
        source: 'GoPay',
        createdAt: DateTime.utc(2026, 11, 3, 12, 30),
        updatedAt: DateTime.utc(2026, 11, 3, 12, 30),
      );

      final item = TransactionWithCategory(
        transaction: transaction,
        category: category,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: TransactionListTile(item: item),
          ),
        ),
      );

      // Semantics should mention title, source, type, and amount
      expect(
        find.bySemanticsLabel(RegExp(r'Makan Siang Nasi Padang.*Makanan.*GoPay.*Pengeluaran.*35\.000')),
        findsOneWidget,
      );
    });

    testWidgets('MonthSelectorHeader buttons meet minimum tap target guidelines', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: MonthSelectorHeader(
                selectedYearMonth: '2024-01',
                onPrevious: () {},
                onNext: () {},
                onResetCurrent: () {},
                onMonthSelected: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check chevron tap target size (must be at least 48x48)
      final prevChevron = tester.getSize(find.byTooltip('Previous month'));
      expect(prevChevron.width, greaterThanOrEqualTo(48.0));
      expect(prevChevron.height, greaterThanOrEqualTo(48.0));

      final nextChevron = tester.getSize(find.byTooltip('Next month'));
      expect(nextChevron.width, greaterThanOrEqualTo(48.0));
      expect(nextChevron.height, greaterThanOrEqualTo(48.0));

      // Check "This Month" jump chip tap target height (must be at least 48)
      final jumpChip = tester.getSize(
        find.ancestor(
          of: find.text('This Month'),
          matching: find.byType(InkWell),
        ),
      );
      expect(jumpChip.height, greaterThanOrEqualTo(48.0));

      handle.dispose();
    });

    testWidgets('AppEmptyState button meets Android & iOS tap target guidelines', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppEmptyState(
              icon: Icons.inbox,
              title: 'Kosong',
              message: 'Tidak ada data.',
              actionLabel: 'Tambah Data',
              onAction: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final buttonSize = tester.getSize(find.byType(FilledButton));
      expect(buttonSize.width, greaterThanOrEqualTo(48.0));
      expect(buttonSize.height, greaterThanOrEqualTo(48.0));

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));

      handle.dispose();
    });
  });
}
