import 'package:flutter/material.dart';

import '../../../../core/utils/year_month_utils.dart';

/// A header widget displaying the currently active month with left/right navigation controls.
class MonthSelectorHeader extends StatelessWidget {
  final String selectedYearMonth;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback? onResetCurrent;

  const MonthSelectorHeader({
    super.key,
    required this.selectedYearMonth,
    required this.onPrevious,
    required this.onNext,
    this.onResetCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final displayMonth = YearMonthUtils.formatDisplay(selectedYearMonth);
    final isCurrentMonth =
        selectedYearMonth == YearMonthUtils.currentYearMonth();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Previous Month Button
        IconButton(
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left_rounded),
          tooltip: 'Previous month',
        ),

        // Month Title & Current Month Chip
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              displayMonth,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (!isCurrentMonth && onResetCurrent != null) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: onResetCurrent,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'This Month',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),

        // Next Month Button
        IconButton(
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right_rounded),
          tooltip: 'Next month',
        ),
      ],
    );
  }
}
