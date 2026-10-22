import 'package:flutter/foundation.dart';

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

  /// Creates a filter for the current calendar week (Monday to Sunday).
  factory DateRangeFilter.currentWeek() {
    final now = DateTime.now();
    // Monday is weekday 1 in Dart
    final monday = DateTime.utc(now.year, now.month, now.day - (now.weekday - 1));
    final sunday = DateTime.utc(monday.year, monday.month, monday.day + 6, 23, 59, 59, 999);
    return DateRangeFilter(
      type: DateRangeType.week,
      startDate: monday,
      endDate: sunday,
      label: 'This Week',
    );
  }

  /// Creates a custom date range filter.
  factory DateRangeFilter.custom({
    required DateTime start,
    required DateTime end,
    String? label,
  }) {
    final startUtc = DateTime.utc(start.year, start.month, start.day);
    final endUtc = DateTime.utc(end.year, end.month, end.day, 23, 59, 59, 999);
    return DateRangeFilter(
      type: DateRangeType.custom,
      startDate: startUtc,
      endDate: endUtc,
      label: label ?? 'Custom Period',
    );
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
