import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_custom_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/year_month_utils.dart';
import '../../domain/models/budget_status.dart';
import 'budget_progress_bar.dart';

/// A card widget displaying the overall monthly budget consumption,
/// progress bar, remaining balance, and quick action to manage the budget.
class MonthlyBudgetCard extends StatelessWidget {
  final MonthlyBudgetStatus status;
  final VoidCallback? onSetupBudget;
  final VoidCallback? onManageBudget;
  final VoidCallback? onCopyPreviousBudget;
  final String? previousMonthDisplay;

  const MonthlyBudgetCard({
    super.key,
    required this.status,
    this.onSetupBudget,
    this.onManageBudget,
    this.onCopyPreviousBudget,
    this.previousMonthDisplay,
  });

  Color _resolveStatusColor(BuildContext context, BudgetStatusLevel level) {
    final customColors = Theme.of(context).extension<AppCustomColors>();
    switch (level) {
      case BudgetStatusLevel.safe:
        return customColors?.budgetSafe ?? AppColors.budgetSafe;
      case BudgetStatusLevel.warning:
        return customColors?.budgetWarning ?? AppColors.budgetWarning;
      case BudgetStatusLevel.danger:
        return customColors?.budgetDanger ?? AppColors.budgetDanger;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final displayMonth = YearMonthUtils.formatDisplay(status.yearMonth);

    // Empty state: no budget set for this month
    if (!status.hasBudget) {
      return Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 44,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                'No Budget Set for $displayMonth',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Set monthly and category limits to keep your expenses on track.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              if (status.totalSpent > 0) ...[
                const SizedBox(height: 12),
                Text(
                  'Current spent: ${status.totalSpent.toIdr()}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (onCopyPreviousBudget != null)
                    FilledButton.tonalIcon(
                      onPressed: onCopyPreviousBudget,
                      icon: const Icon(Icons.history),
                      label: Text(
                        previousMonthDisplay != null
                            ? 'Copy $previousMonthDisplay'
                            : 'Copy Last Month',
                      ),
                    ),
                  FilledButton.icon(
                    onPressed: onSetupBudget ?? onManageBudget,
                    icon: const Icon(Icons.add),
                    label: const Text('Set Up Budget'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Configured monthly budget state
    final statusColor = _resolveStatusColor(context, status.statusLevel);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Month Title & Optional Manage Action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Budget $displayMonth',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Total monthly budget',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                if (onManageBudget != null)
                  IconButton(
                    onPressed: onManageBudget,
                    icon: const Icon(Icons.tune),
                    tooltip: 'Edit Budget',
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Main Figure Row: Spent / Limit & Percentage Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status.totalSpent.toIdr(),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'of ${status.totalLimit.toIdr()}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status Percentage Pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        status.isExceeded
                            ? Icons.error_outline
                            : status.isNearLimit
                                ? Icons.warning_amber_rounded
                                : Icons.check_circle_outline,
                        size: 16,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${status.percentage}%',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Progress Bar
            BudgetProgressBar.fromMonthlyStatus(
              status: status,
              height: 10,
            ),
            const SizedBox(height: 12),

            // Footer Row: Remaining and optional unbudgeted note
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    status.isExceeded
                        ? 'Exceeded by ${(-status.totalRemaining).toIdr()}'
                        : 'Remaining: ${status.totalRemaining.toIdr()}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: status.isExceeded
                          ? statusColor
                          : colorScheme.onSurfaceVariant,
                      fontWeight: status.isExceeded
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
                if (status.unbudgetedSpent > 0)
                  Text(
                    '+${status.unbudgetedSpent.toIdr()} unbudgeted',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
