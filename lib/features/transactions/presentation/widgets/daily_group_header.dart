import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/models/daily_transaction_group.dart';

/// Header widget displaying the date and summary totals (expense / income) for a single day.
class DailyGroupHeader extends StatelessWidget {
  const DailyGroupHeader({
    super.key,
    required this.group,
  });

  final DailyTransactionGroup group;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateLabel = group.getDateHeaderLabel();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            dateLabel,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Row(
            children: [
              if (group.totalExpense > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    '-${CurrencyFormatter.format(group.totalExpense)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.expense,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (group.totalIncome > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    '+${CurrencyFormatter.format(group.totalIncome)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.income,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
