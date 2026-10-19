import 'package:intl/intl.dart';

/// Utilities for working with 'YYYY-MM' formatted year-month strings
/// and month date ranges.
abstract final class YearMonthUtils {
  /// Parses a 'YYYY-MM' string into (year, month).
  static (int year, int month) parse(String yearMonth) {
    final parts = yearMonth.trim().split('-');
    if (parts.length != 2) {
      throw FormatException('Invalid yearMonth format: $yearMonth (expected YYYY-MM)');
    }
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    if (month < 1 || month > 12) {
      throw FormatException('Invalid month: $month (must be 1-12)');
    }
    return (year, month);
  }

  /// Converts a [DateTime] into a 'YYYY-MM' string.
  static String toYearMonth(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  /// Returns the current year-month string for today (e.g. '2026-10').
  static String currentYearMonth() {
    return toYearMonth(DateTime.now());
  }

  /// Returns the UTC start of the month: `YYYY-MM-01 00:00:00.000Z`.
  static DateTime getStartOfMonth(String yearMonth) {
    final (year, month) = parse(yearMonth);
    return DateTime.utc(year, month, 1, 0, 0, 0);
  }

  /// Returns the UTC end of the month: `YYYY-MM-lastDay 23:59:59.999Z`.
  static DateTime getEndOfMonth(String yearMonth) {
    final (year, month) = parse(yearMonth);
    return DateTime.utc(year, month + 1, 0, 23, 59, 59, 999);
  }

  /// Returns the previous month in 'YYYY-MM' format.
  static String previousYearMonth(String yearMonth) {
    final (year, month) = parse(yearMonth);
    var prevYear = year;
    var prevMonth = month - 1;
    if (prevMonth < 1) {
      prevMonth = 12;
      prevYear--;
    }
    return '$prevYear-${prevMonth.toString().padLeft(2, '0')}';
  }

  /// Returns the next month in 'YYYY-MM' format.
  static String nextYearMonth(String yearMonth) {
    final (year, month) = parse(yearMonth);
    var nextYear = year;
    var nextMonth = month + 1;
    if (nextMonth > 12) {
      nextMonth = 1;
      nextYear++;
    }
    return '$nextYear-${nextMonth.toString().padLeft(2, '0')}';
  }

  /// Formats the year-month string for UI display (e.g. 'October 2026').
  static String formatDisplay(String yearMonth, {String pattern = 'MMMM yyyy'}) {
    try {
      final (year, month) = parse(yearMonth);
      return DateFormat(pattern).format(DateTime(year, month));
    } catch (_) {
      return yearMonth;
    }
  }
}
