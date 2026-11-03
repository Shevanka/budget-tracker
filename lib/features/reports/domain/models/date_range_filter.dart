import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/year_month_utils.dart';

enum DateRangeType {
  month,
  week,
  custom,
}

/// Represents a selected date range filter for reports and analytics.
@immutable
class DateRangeFilter {
  final DateRangeType type;
  final DateTime startDate;
  final DateTime endDate;
  final String label;
  final String? yearMonth;

  const DateRangeFilter({
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.label,
    this.yearMonth,
  });

  /// Creates a filter for a specific yearMonth string (e.g. '2026-10').
  factory DateRangeFilter.forMonth(String ym) {
    final start = YearMonthUtils.getStartOfMonth(ym);
    final end = YearMonthUtils.getEndOfMonth(ym);
    final label = YearMonthUtils.formatDisplay(ym);
    return DateRangeFilter(
      type: DateRangeType.month,
      startDate: start,
      endDate: end,
      label: label,
      yearMonth: ym,
    );
  }

  /// Creates a filter for the current month.
  factory DateRangeFilter.currentMonth() {
    return DateRangeFilter.forMonth(YearMonthUtils.currentYearMonth());
  }

  /// Creates a filter for a week containing [date] (defaults to today).
  factory DateRangeFilter.forWeek([DateTime? date]) {
    final target = date ?? DateTime.now();
    final targetUtc = DateTime.utc(target.year, target.month, target.day);
    // Monday is weekday 1 in Dart
    final monday = targetUtc.subtract(Duration(days: targetUtc.weekday - 1));
    final sunday = DateTime.utc(monday.year, monday.month, monday.day + 6, 23, 59, 59, 999);

    final now = DateTime.now();
    final nowUtc = DateTime.utc(now.year, now.month, now.day);
    final nowMonday = nowUtc.subtract(Duration(days: nowUtc.weekday - 1));
    final isCurrent = monday.year == nowMonday.year &&
        monday.month == nowMonday.month &&
        monday.day == nowMonday.day;

    final label = isCurrent
        ? 'This Week'
        : (monday.year == sunday.year
            ? '${DateFormat('d MMM').format(monday)} – ${DateFormat('d MMM yyyy').format(sunday)}'
            : '${DateFormat('d MMM yyyy').format(monday)} – ${DateFormat('d MMM yyyy').format(sunday)}');

    return DateRangeFilter(
      type: DateRangeType.week,
      startDate: monday,
      endDate: sunday,
      label: label,
    );
  }

  /// Creates a filter for the current calendar week (Monday to Sunday).
  factory DateRangeFilter.currentWeek() => DateRangeFilter.forWeek();

  /// Creates a custom date range filter.
  factory DateRangeFilter.custom({
    required DateTime start,
    required DateTime end,
    String? label,
  }) {
    final s = start.isBefore(end) ? start : end;
    final e = start.isBefore(end) ? end : start;
    final startUtc = DateTime.utc(s.year, s.month, s.day);
    final endUtc = DateTime.utc(e.year, e.month, e.day, 23, 59, 59, 999);
    final computedLabel = label ?? _formatCustomRange(startUtc, endUtc);

    return DateRangeFilter(
      type: DateRangeType.custom,
      startDate: startUtc,
      endDate: endUtc,
      label: computedLabel,
    );
  }

  static String _formatCustomRange(DateTime start, DateTime end) {
    if (start.year == end.year) {
      if (start.month == end.month && start.day == end.day) {
        return DateFormat('d MMM yyyy').format(start);
      }
      return '${DateFormat('d MMM').format(start)} – ${DateFormat('d MMM yyyy').format(end)}';
    }
    return '${DateFormat('d MMM yyyy').format(start)} – ${DateFormat('d MMM yyyy').format(end)}';
  }

  /// Returns whether this filter represents the current period (month or week).
  bool get isCurrent {
    if (type == DateRangeType.month) {
      return yearMonth == YearMonthUtils.currentYearMonth();
    }
    if (type == DateRangeType.week) {
      final now = DateTime.now();
      final nowUtc = DateTime.utc(now.year, now.month, now.day);
      final nowMonday = nowUtc.subtract(Duration(days: nowUtc.weekday - 1));
      return startDate.year == nowMonday.year &&
          startDate.month == nowMonday.month &&
          startDate.day == nowMonday.day;
    }
    return false;
  }

  DateRangeFilter copyWith({
    DateRangeType? type,
    DateTime? startDate,
    DateTime? endDate,
    String? label,
    String? yearMonth,
  }) {
    return DateRangeFilter(
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      label: label ?? this.label,
      yearMonth: yearMonth ?? this.yearMonth,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateRangeFilter &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          label == other.label &&
          yearMonth == other.yearMonth;

  @override
  int get hashCode => Object.hash(type, startDate, endDate, label, yearMonth);

  @override
  String toString() => 'DateRangeFilter($label: $startDate to $endDate)';
}
