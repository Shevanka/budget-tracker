import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/default_categories.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../database/converters/transaction_type.dart';
import '../../../../database/daos/transaction_dao.dart';
import '../../../../routing/app_routes.dart';

/// Card-style list tile for displaying an individual transaction.
class TransactionListTile extends StatelessWidget {
  const TransactionListTile({
    super.key,
    required this.item,
    this.onTap,
  });

  final TransactionWithCategory item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tx = item.transaction;
    final cat = item.category;

    final isExpense = tx.type == TransactionType.expense;
    final categoryColor =
        cat != null ? Color(cat.color) : theme.colorScheme.primary;
    final iconData = cat != null
        ? DefaultCategories.getIconData(cat.icon)
        : Icons.receipt_long;

    final hasNote = tx.note != null && tx.note!.trim().isNotEmpty;
    final titleText = hasNote ? tx.note!.trim() : (cat?.name ?? 'Uncategorized');

    final timeStr = DateFormat('HH:mm').format(tx.date.toLocal());
    final subtitleParts = <String>[];
    if (hasNote && cat != null) {
      subtitleParts.add(cat.name);
    }
    subtitleParts.add(tx.source);
    subtitleParts.add(timeStr);
    final subtitleText = subtitleParts.join(' · ');

    final amountColor = isExpense ? AppColors.expense : AppColors.income;
    final amountPrefix = isExpense ? '-' : '+';
    final amountText = '$amountPrefix${CurrencyFormatter.format(tx.amount)}';

    return InkWell(
      onTap: onTap ??
          () {
            context.push(
              AppRoute.editTransaction.path.replaceAll(':id', tx.id),
            );
          },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Category Icon Badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                iconData,
                color: categoryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),

            // Note / Category & Source Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titleText,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitleText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Amount Display
            Text(
              amountText,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: amountColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
