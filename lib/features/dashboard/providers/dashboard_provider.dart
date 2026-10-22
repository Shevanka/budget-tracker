import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/year_month_utils.dart';
import '../../../database/converters/transaction_type.dart';
import '../../../database/daos/transaction_dao.dart';
import '../../../database/database_provider.dart';
import '../domain/models/financial_summary.dart';

/// Notifier managing the currently selected dashboard month in 'YYYY-MM' format.
class SelectedDashboardMonthNotifier extends AutoDisposeNotifier<String> {
  @override
  String build() {
    return YearMonthUtils.currentYearMonth();
  }

  /// Sets the selected month explicitly (e.g. '2026-10').
  void setMonth(String yearMonth) {
    state = yearMonth;
  }

  /// Advances to the next month.
  void nextMonth() {
    state = YearMonthUtils.nextYearMonth(state);
  }

  /// Goes back to the previous month.
  void previousMonth() {
    state = YearMonthUtils.previousYearMonth(state);
  }

  /// Resets to the current real-world month.
  void resetToCurrentMonth() {
    state = YearMonthUtils.currentYearMonth();
  }
}

/// Provider for the active dashboard month.
final selectedDashboardMonthProvider =
    AutoDisposeNotifierProvider<SelectedDashboardMonthNotifier, String>(
  SelectedDashboardMonthNotifier.new,
);

/// Helper function streaming [MonthlyFinancialSummary] reactively for a given [yearMonth].
Stream<MonthlyFinancialSummary> _watchFinancialSummary(
  TransactionDao dao,
  String yearMonth,
) {
  final start = YearMonthUtils.getStartOfMonth(yearMonth);
  final end = YearMonthUtils.getEndOfMonth(yearMonth);

  return dao.watchTransactionsByDateRange(start, end).map((transactions) {
    var totalIncome = 0;
    var totalExpense = 0;

    for (final txn in transactions) {
      if (txn.type == TransactionType.income) {
        totalIncome += txn.amount;
      } else if (txn.type == TransactionType.expense) {
        totalExpense += txn.amount;
      }
    }

    return MonthlyFinancialSummary.calculate(
      yearMonth: yearMonth,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      transactionCount: transactions.length,
    );
  }).distinct();
}

/// Reactive stream of [MonthlyFinancialSummary] for any given [yearMonth].
final monthlyFinancialSummaryProvider =
    StreamProvider.autoDispose.family<MonthlyFinancialSummary, String>(
        (ref, yearMonth) {
  final dao = ref.watch(transactionDaoProvider);
  return _watchFinancialSummary(dao, yearMonth);
});

/// Reactive stream of [MonthlyFinancialSummary] for the currently selected dashboard month.
final currentDashboardSummaryProvider =
    StreamProvider.autoDispose<MonthlyFinancialSummary>((ref) {
  final selectedMonth = ref.watch(selectedDashboardMonthProvider);
  final dao = ref.watch(transactionDaoProvider);
  return _watchFinancialSummary(dao, selectedMonth);
});

/// Streams up to 5 most recent transactions joined with their categories for a given [yearMonth].
final recentTransactionsForMonthProvider =
    StreamProvider.autoDispose.family<List<TransactionWithCategory>, String>(
        (ref, yearMonth) {
  final dao = ref.watch(transactionDaoProvider);
  final start = YearMonthUtils.getStartOfMonth(yearMonth);
  final end = YearMonthUtils.getEndOfMonth(yearMonth);
  return dao.watchRecentTransactionsWithCategoryByDateRange(
    start,
    end,
    limit: 5,
  );
});

/// Streams up to 5 most recent transactions for the currently selected dashboard month.
final currentDashboardRecentTransactionsProvider =
    StreamProvider.autoDispose<List<TransactionWithCategory>>((ref) {
  final selectedMonth = ref.watch(selectedDashboardMonthProvider);
  final dao = ref.watch(transactionDaoProvider);
  final start = YearMonthUtils.getStartOfMonth(selectedMonth);
  final end = YearMonthUtils.getEndOfMonth(selectedMonth);
  return dao.watchRecentTransactionsWithCategoryByDateRange(
    start,
    end,
    limit: 5,
  );
});
