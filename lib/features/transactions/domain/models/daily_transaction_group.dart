import 'package:intl/intl.dart';

import '../../../../database/converters/transaction_type.dart';
import '../../../../database/daos/transaction_dao.dart';

/// Represents transactions grouped by a single local calendar day, including daily totals.
class DailyTransactionGroup {
  final DateTime date;
  final List<TransactionWithCategory> items;
  final int totalExpense;
  final int totalIncome;

  const DailyTransactionGroup({
    required this.date,
    required this.items,
    required this.totalExpense,
    required this.totalIncome,
  });

  /// Net balance for this day (income - expense).
  int get netAmount => totalIncome - totalExpense;

  /// Returns a user-friendly header label, e.g. "Today", "Yesterday", or "Mon, 15 Oct 2026".
  String getDateHeaderLabel({DateTime? referenceNow}) {
    final now = referenceNow ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    if (today.year == target.year &&
        today.month == target.month &&
        today.day == target.day) {
      return 'Today';
    }

    final yesterday = today.subtract(const Duration(days: 1));
    if (yesterday.year == target.year &&
        yesterday.month == target.month &&
        yesterday.day == target.day) {
      return 'Yesterday';
    }

    return DateFormat('EEE, d MMM yyyy').format(date);
  }

  /// Groups a flat list of [TransactionWithCategory] items by local calendar day (descending).
  static List<DailyTransactionGroup> fromTransactions(
    List<TransactionWithCategory> transactions,
  ) {
    if (transactions.isEmpty) return const [];

    final map = <DateTime, List<TransactionWithCategory>>{};

    for (final item in transactions) {
      final localDate = item.transaction.date.toLocal();
      final dayKey = DateTime(localDate.year, localDate.month, localDate.day);
      map.putIfAbsent(dayKey, () => []).add(item);
    }

    final sortedKeys = map.keys.toList()..sort((a, b) => b.compareTo(a));

    return sortedKeys.map((dayKey) {
      final dayItems = map[dayKey]!;
      var expense = 0;
      var income = 0;

      for (final it in dayItems) {
        if (it.transaction.type == TransactionType.expense) {
          expense += it.transaction.amount;
        } else if (it.transaction.type == TransactionType.income) {
          income += it.transaction.amount;
        }
      }

      return DailyTransactionGroup(
        date: dayKey,
        items: dayItems,
        totalExpense: expense,
        totalIncome: income,
      );
    }).toList();
  }
}
