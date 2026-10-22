import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/year_month_utils.dart';
import '../../domain/models/date_range_filter.dart';
import '../../providers/reports_provider.dart';
import '../widgets/category_pie_chart.dart';

/// The reports and analytics screen displaying spending breakdown,
/// charts, and period filtering.
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentFilter = ref.watch(reportsFilterProvider);
    final filterNotifier = ref.read(reportsFilterProvider.notifier);
    final reportAsync = ref.watch(currentCategorySpendingReportProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(categorySpendingReportProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Period Filter Header (Month / Week toggle & Chevrons)
              _buildPeriodHeader(
                context,
                currentFilter,
                filterNotifier,
                colorScheme,
                theme,
              ),
              const SizedBox(height: 16),

              // Category Spending Pie Chart
              reportAsync.when(
                loading: () => const SizedBox(
                  height: 280,
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
                          'Failed to load spending report',
                          style: TextStyle(color: colorScheme.onErrorContainer),
                        ),
                        const SizedBox(height: 8),
                        FilledButton.tonal(
                          onPressed: () => ref.invalidate(
                            categorySpendingReportProvider(currentFilter),
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (report) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CategoryPieChart(report: report),
                    const SizedBox(height: 16),

                    // Quick Insights Summary Card
                    if (report.hasData)
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.insights_rounded,
                                  color: colorScheme.primary,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Top Spending Category',
                                      style: theme.textTheme.labelMedium?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${report.topCategory!.category.name} (${report.topCategory!.percentage.toStringAsFixed(1)}%)',
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      report.topCategory!.amount.toIdr(),
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodHeader(
    BuildContext context,
    DateRangeFilter filter,
    ReportsFilterNotifier notifier,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    final isMonthFilter = filter.type == DateRangeType.month;
    final isCurrent = filter.yearMonth == YearMonthUtils.currentYearMonth();

    return Column(
      children: [
        // Mode Selector: Month vs Week
        SegmentedButton<DateRangeType>(
          segments: const [
            ButtonSegment<DateRangeType>(
              value: DateRangeType.month,
              label: Text('Month'),
              icon: Icon(Icons.calendar_month_outlined, size: 16),
            ),
            ButtonSegment<DateRangeType>(
              value: DateRangeType.week,
              label: Text('Week'),
              icon: Icon(Icons.date_range_outlined, size: 16),
            ),
          ],
          selected: {filter.type},
          onSelectionChanged: (newSelection) {
            final selected = newSelection.first;
            if (selected == DateRangeType.month) {
              notifier.setMonth(YearMonthUtils.currentYearMonth());
            } else if (selected == DateRangeType.week) {
              notifier.setWeek();
            }
          },
        ),
        const SizedBox(height: 12),

        // Navigation Row (Chevrons & Period Label)
        if (isMonthFilter)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: notifier.previousMonth,
                icon: const Icon(Icons.chevron_left_rounded),
                tooltip: 'Previous month',
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    filter.label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!isCurrent) ...[
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: notifier.resetToCurrentMonth,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
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
              IconButton(
                onPressed: notifier.nextMonth,
                icon: const Icon(Icons.chevron_right_rounded),
                tooltip: 'Next month',
              ),
            ],
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              filter.label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}
