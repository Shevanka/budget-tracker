import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/year_month_utils.dart';
import '../../../../routing/app_routes.dart';
import '../../../budget/presentation/widgets/category_budget_progress_tile.dart';
import '../../../budget/presentation/widgets/monthly_budget_card.dart';
import '../../../budget/providers/budget_provider.dart';

/// A section widget on the dashboard presenting the monthly budget progress,
/// overall consumption card, and top category budget tiles.
class DashboardBudgetSection extends ConsumerWidget {
  final String selectedYearMonth;

  const DashboardBudgetSection({
    super.key,
    required this.selectedYearMonth,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final budgetStatusAsync =
        ref.watch(monthlyBudgetStatusProvider(selectedYearMonth));
    final prevBudgetAsync =
        ref.watch(previousAvailableBudgetProvider(selectedYearMonth));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.pie_chart_outline_rounded,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Budget Progress',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: () => context.push(AppRoute.budgetSetup.path),
              icon: const Icon(Icons.tune, size: 16),
              label: const Text('Manage'),
            ),
          ],
        ),
        const SizedBox(height: 8),

        budgetStatusAsync.when(
          loading: () => const SizedBox(
            height: 160,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, _) => Card(
            color: colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.error_outline, color: colorScheme.error),
                  const SizedBox(height: 8),
                  Text(
                    'Failed to load budget status',
                    style: TextStyle(color: colorScheme.onErrorContainer),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.tonal(
                    onPressed: () => ref.invalidate(
                      monthlyBudgetStatusProvider(selectedYearMonth),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (status) {
            final prevBudget = prevBudgetAsync.asData?.value;
            final previousMonthDisplay = prevBudget != null
                ? YearMonthUtils.formatDisplay(prevBudget.yearMonth)
                : null;

            // Take top 3 categories that have a limit or have expenses
            final topCategories = status.categoryStatuses
                .where((c) => c.hasLimit || c.spent > 0)
                .take(3)
                .toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Overall Monthly Budget Card
                MonthlyBudgetCard(
                  status: status,
                  onSetupBudget: () => context.push(AppRoute.budgetSetup.path),
                  onManageBudget: () => context.push(AppRoute.budgetSetup.path),
                  onCopyPreviousBudget: prevBudget != null
                      ? () async {
                          final success = await ref
                              .read(budgetControllerProvider.notifier)
                              .copyBudget(
                                fromYearMonth: prevBudget.yearMonth,
                                toYearMonth: selectedYearMonth,
                              );
                          if (context.mounted && success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Copied budget from ${YearMonthUtils.formatDisplay(prevBudget.yearMonth)}',
                                ),
                              ),
                            );
                          }
                        }
                      : null,
                  previousMonthDisplay: previousMonthDisplay,
                ),

                // Top Category Progress Tiles (when budget exists and categories are present)
                if (status.hasBudget && topCategories.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Category Budgets',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (status.categoryStatuses.length > 3)
                        TextButton(
                          onPressed: () =>
                              context.push(AppRoute.budgetSetup.path),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            visualDensity: VisualDensity.compact,
                          ),
                          child: const Text('View All'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...topCategories.map(
                    (catStatus) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: CategoryBudgetProgressTile(
                        status: catStatus,
                        compact: true,
                        onTap: () => context.push(AppRoute.budgetSetup.path),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}
