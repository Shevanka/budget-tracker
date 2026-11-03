import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// Represents aggregated spending on a single calendar date.
@immutable
class DailySpending {
  final DateTime date;
  final int amount;
  final int transactionCount;

  const DailySpending({
    required this.date,
    required this.amount,
    this.transactionCount = 0,
  });

  /// Short day-of-week string (e.g. 'Mon', 'Tue').
  String get dayOfWeek => DateFormat('E').format(date);

  /// Day of the month string (e.g. '1', '15').
  String get dayOfMonth => '${date.day}';

  /// Formatted date string (e.g. '15 Oct').
  String get formattedDate => DateFormat('d MMM').format(date);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailySpending &&
          runtimeType == other.runtimeType &&
          date.year == other.date.year &&
          date.month == other.date.month &&
          date.day == other.date.day &&
          amount == other.amount &&
          transactionCount == other.transactionCount;

  @override
  int get hashCode => Object.hash(date.year, date.month, date.day, amount, transactionCount);

  @override
  String toString() => 'DailySpending($formattedDate: Rp $amount ($transactionCount tx))';
}

/// Aggregated time-series report containing daily spending across a period.
@immutable
class SpendingOverTimeReport {
  final List<DailySpending> items;
  final int totalExpense;
  final DateTime startDate;
  final DateTime endDate;

  const SpendingOverTimeReport({
    required this.items,
    required this.totalExpense,
    required this.startDate,
    required this.endDate,
  });

  bool get isEmpty => totalExpense == 0 || items.every((item) => item.amount == 0);
  bool get hasData => !isEmpty;

  /// The highest spending day in the period, or null if empty.
  DailySpending? get highestSpendingDay {
    if (items.isEmpty) return null;
    DailySpending? highest;
    for (final item in items) {
      if (highest == null || item.amount > highest.amount) {
        highest = item;
      }
    }
    return (highest != null && highest.amount > 0) ? highest : null;
  }

  /// Maximum daily expense in this report period (minimum 0).
  int get maxDailyExpense {
    var max = 0;
    for (final item in items) {
      if (item.amount > max) {
        max = item.amount;
      }
    }
    return max;
  }

  /// Average daily expense over all days in the period.
  int get averageDailyExpense {
    if (items.isEmpty) return 0;
    return (totalExpense / items.length).round();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpendingOverTimeReport &&
          runtimeType == other.runtimeType &&
          listEquals(items, other.items) &&
          totalExpense == other.totalExpense &&
          startDate == other.startDate &&
          endDate == other.endDate;

  @override
  int get hashCode => Object.hash(
        Object.hashAll(items),
        totalExpense,
        startDate,
        endDate,
      );
}
