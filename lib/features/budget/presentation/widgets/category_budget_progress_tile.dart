import 'package:flutter/material.dart';

import '../../../../core/constants/default_categories.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_custom_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/models/budget_status.dart';
import 'budget_progress_bar.dart';

/// A card/tile widget presenting the budget progress for an individual category.
///
/// Features:
/// - Category icon and color avatar
/// - Spent vs Limit IDR formatting
/// - Color-coded percentage badge (green / amber / red)
/// - Remaining balance or excess alert
/// - Integrated [BudgetProgressBar]
class CategoryBudgetProgressTile extends StatelessWidget {
  final CategoryBudgetStatus status;
  final VoidCallback? onTap;
  final bool showRemaining;
  final bool compact;

  const CategoryBudgetProgressTile({
    super.key,
    required this.status,
    this.onTap,
    this.showRemaining = true,
    this.compact = false,
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
    final catColor = Color(status.category.color);
    final iconData = DefaultCategories.getIconData(status.category.icon);
    final statusColor = _resolveStatusColor(context, status.statusLevel);

    final cardContent = Padding(
      padding: EdgeInsets.all(compact ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Category Avatar, Name, and Status Badge
          Row(
            children: [
              Container(
                width: compact ? 36 : 40,
                height: compact ? 36 : 40,
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  iconData,
                  color: catColor,
                  size: compact ? 20 : 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status.category.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: compact ? 14 : 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (status.hasLimit) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${status.spent.toIdr()} / ${status.limit.toIdr()}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 2),
                      Text(
                        status.spent.toIdr(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Percentage Badge / No Limit Chip
              if (status.hasLimit) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${status.percentage}%',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'No Limit',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),

          if (status.hasLimit) ...[
            const SizedBox(height: 12),
            // Progress Bar
            BudgetProgressBar.fromCategoryStatus(
              status: status,
              height: compact ? 6 : 8,
            ),
            if (showRemaining) ...[
              const SizedBox(height: 6),
              // Remaining / Exceeded Note
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    status.isExceeded
                        ? 'Exceeded by ${(-status.remaining).toIdr()}'
                        : 'Remaining: ${status.remaining.toIdr()}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: status.isExceeded
                          ? statusColor
                          : colorScheme.onSurfaceVariant,
                      fontWeight:
                          status.isExceeded ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  if (status.isNearLimit)
                    Text(
                      'Near limit',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ],
      ),
    );

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: cardContent,
            )
          : cardContent,
    );
  }
}
