import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/year_month_utils.dart';
import '../../../database/app_database.dart';
import '../../../database/converters/transaction_type.dart';
import '../../../database/database_provider.dart';
import '../domain/models/category_spending.dart';
import '../domain/models/date_range_filter.dart';
import '../domain/models/spending_over_time.dart';

/// Manages the active [DateRangeFilter] for reports and analytics.
class ReportsFilterNotifier extends Notifier<DateRangeFilter> {
  @override
  DateRangeFilter build() {
    return DateRangeFilter.currentMonth();
  }

  void setFilter(DateRangeFilter filter) {
    state = filter;
  }

  void setMonth(String yearMonth) {
    state = DateRangeFilter.forMonth(yearMonth);
  }

  void previousMonth() {
    final currentYm = state.yearMonth ?? YearMonthUtils.currentYearMonth();
    final prevYm = YearMonthUtils.previousYearMonth(currentYm);
    state = DateRangeFilter.forMonth(prevYm);
  }

  void nextMonth() {
    final currentYm = state.yearMonth ?? YearMonthUtils.currentYearMonth();
    final nextYm = YearMonthUtils.nextYearMonth(currentYm);
    state = DateRangeFilter.forMonth(nextYm);
  }

  void resetToCurrentMonth() {
    state = DateRangeFilter.currentMonth();
  }

  void setWeek() {
    state = DateRangeFilter.currentWeek();
  }

  void setCustom(DateTime start, DateTime end, [String? label]) {
    state = DateRangeFilter.custom(start: start, end: end, label: label);
  }
}

/// Active date range filter provider for reports.
final reportsFilterProvider =
    NotifierProvider<ReportsFilterNotifier, DateRangeFilter>(
  ReportsFilterNotifier.new,
);

/// Streams [CategorySpendingReport] for a given [DateRangeFilter].
final categorySpendingReportProvider =
    StreamProvider.autoDispose.family<CategorySpendingReport, DateRangeFilter>((ref, filter) {
  final dao = ref.watch(transactionDaoProvider);
  return dao
      .watchTransactionsWithCategoryByDateRange(
        filter.startDate,
        filter.endDate,
        type: TransactionType.expense,
      )
      .map((txList) {
        if (txList.isEmpty) {
          return CategorySpendingReport(
            items: const [],
            totalExpense: 0,
            startDate: filter.startDate,
            endDate: filter.endDate,
          );
        }

        // Group expenses by category
        final Map<String, (Category, int, int)> categoryMap = {};
        var totalExpense = 0;

        for (final item in txList) {
          final amount = item.transaction.amount;
          totalExpense += amount;

          final cat = item.category ??
              Category(
                id: 'uncategorized',
                name: 'Uncategorized',
                icon: 'receipt_long',
                color: 0xFF78909C,
                type: TransactionType.expense,
                isDefault: false,
                isActive: true,
                sortOrder: 999,
                createdAt: DateTime.utc(2026, 1, 1),
              );

          if (categoryMap.containsKey(cat.id)) {
            final current = categoryMap[cat.id]!;
            categoryMap[cat.id] = (
              current.$1,
              current.$2 + amount,
              current.$3 + 1,
            );
          } else {
            categoryMap[cat.id] = (cat, amount, 1);
          }
        }

        final items = categoryMap.values.map((entry) {
          final cat = entry.$1;
          final amount = entry.$2;
          final count = entry.$3;
          final percentage =
              totalExpense > 0 ? (amount / totalExpense) * 100.0 : 0.0;
          return CategorySpending(
            category: cat,
            amount: amount,
            percentage: percentage,
            transactionCount: count,
          );
        }).toList();

        // Sort descending by amount (highest expense first)
        items.sort((a, b) => b.amount.compareTo(a.amount));

        return CategorySpendingReport(
          items: items,
          totalExpense: totalExpense,
          startDate: filter.startDate,
          endDate: filter.endDate,
        );
      });
});

/// Streams the category spending report for the currently active [reportsFilterProvider].
final currentCategorySpendingReportProvider =
    Provider.autoDispose<AsyncValue<CategorySpendingReport>>((ref) {
  final filter = ref.watch(reportsFilterProvider);
  return ref.watch(categorySpendingReportProvider(filter));
});

/// Streams [SpendingOverTimeReport] for a given [DateRangeFilter].
final spendingOverTimeProvider =
    StreamProvider.autoDispose.family<SpendingOverTimeReport, DateRangeFilter>((ref, filter) {
  final dao = ref.watch(transactionDaoProvider);
  return dao
      .watchTransactionsWithCategoryByDateRange(
        filter.startDate,
        filter.endDate,
        type: TransactionType.expense,
      )
      .map((txList) {
        final startUtc = DateTime.utc(
          filter.startDate.year,
          filter.startDate.month,
          filter.startDate.day,
        );
        final endUtc = DateTime.utc(
          filter.endDate.year,
          filter.endDate.month,
          filter.endDate.day,
        );
        final dayCount = endUtc.difference(startUtc).inDays + 1;

        // Initialize daily map with zeroes for all calendar days
        final dailyMap = <DateTime, (int amount, int count)>{};
        for (var i = 0; i < dayCount; i++) {
          final date = DateTime.utc(startUtc.year, startUtc.month, startUtc.day + i);
          dailyMap[date] = (0, 0);
        }

        var totalExpense = 0;

        for (final item in txList) {
          final amount = item.transaction.amount;
          totalExpense += amount;

          final txDate = item.transaction.date;
          final dayKey = DateTime.utc(txDate.year, txDate.month, txDate.day);

          if (dailyMap.containsKey(dayKey)) {
            final current = dailyMap[dayKey]!;
            dailyMap[dayKey] = (current.$1 + amount, current.$2 + 1);
          } else {
            dailyMap[dayKey] = (amount, 1);
          }
        }

        final sortedKeys = dailyMap.keys.toList()..sort();
        final items = sortedKeys.map((k) {
          final entry = dailyMap[k]!;
          return DailySpending(
            date: k,
            amount: entry.$1,
            transactionCount: entry.$2,
          );
        }).toList();

        return SpendingOverTimeReport(
          items: items,
          totalExpense: totalExpense,
          startDate: filter.startDate,
          endDate: filter.endDate,
        );
      });
});

/// Streams the spending over time report for the currently active [reportsFilterProvider].
final currentSpendingOverTimeProvider =
    Provider.autoDispose<AsyncValue<SpendingOverTimeReport>>((ref) {
  final filter = ref.watch(reportsFilterProvider);
  return ref.watch(spendingOverTimeProvider(filter));
});
