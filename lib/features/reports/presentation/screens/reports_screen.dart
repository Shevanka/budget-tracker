import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/year_month_utils.dart';
import '../../domain/models/category_spending.dart';
import '../../domain/models/date_range_filter.dart';
import '../../providers/reports_provider.dart';
import '../widgets/category_breakdown_list.dart';
import '../widgets/category_pie_chart.dart';
import '../widgets/spending_bar_chart.dart';

/// The reports and analytics screen displaying spending breakdown,
/// charts, and period filtering.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  CategorySpending? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentFilter = ref.watch(reportsFilterProvider);
    final filterNotifier = ref.read(reportsFilterProvider.notifier);
    final reportAsync = ref.watch(currentCategorySpendingReportProvider);
    final overTimeAsync = ref.watch(currentSpendingOverTimeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(categorySpendingReportProvider);
          ref.invalidate(spendingOverTimeProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Period Filter Header (Month / Week / Custom toggle & controls)
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
                    CategoryPieChart(
                      report: report,
                      selectedCategory: _selectedCategory,
                      onCategorySelected: (cat) {
                        setState(() => _selectedCategory = cat);
                      },
                    ),
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
              const SizedBox(height: 16),

              // Spending Over Time Bar Chart
              overTimeAsync.when(
                loading: () => const SizedBox(
                  height: 200,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, _) => const SizedBox.shrink(),
                data: (overTimeReport) => SpendingBarChart(report: overTimeReport),
              ),
              const SizedBox(height: 16),

              // Category Breakdown List
              reportAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
                data: (report) => CategoryBreakdownList(
                  report: report,
                  selectedCategory: _selectedCategory,
                  onCategorySelected: (cat) {
                    setState(() => _selectedCategory = cat);
                  },
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
    return Column(
      children: [
        // Mode Selector: Month vs Week vs Custom
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
            ButtonSegment<DateRangeType>(
              value: DateRangeType.custom,
              label: Text('Custom'),
              icon: Icon(Icons.tune_rounded, size: 16),
            ),
          ],
          selected: {filter.type},
          onSelectionChanged: (newSelection) {
            final selected = newSelection.first;
            if (selected == DateRangeType.month) {
              notifier.setMonth(YearMonthUtils.currentYearMonth());
            } else if (selected == DateRangeType.week) {
              notifier.setWeek();
            } else if (selected == DateRangeType.custom) {
              final now = DateTime.now();
              notifier.setCustom(
                now.subtract(const Duration(days: 29)),
                now,
                'Last 30 Days',
              );
            }
          },
        ),
        const SizedBox(height: 12),

        // Navigation Row according to active filter type
        if (filter.type == DateRangeType.month)
          _buildMonthNavigation(context, filter, notifier, colorScheme, theme)
        else if (filter.type == DateRangeType.week)
          _buildWeekNavigation(context, filter, notifier, colorScheme, theme)
        else
          _buildCustomNavigation(context, filter, notifier, colorScheme, theme),
      ],
    );
  }

  Widget _buildMonthNavigation(
    BuildContext context,
    DateRangeFilter filter,
    ReportsFilterNotifier notifier,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Row(
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
            if (!filter.isCurrent) ...[
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
    );
  }

  Widget _buildWeekNavigation(
    BuildContext context,
    DateRangeFilter filter,
    ReportsFilterNotifier notifier,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: notifier.previousWeek,
          icon: const Icon(Icons.chevron_left_rounded),
          tooltip: 'Previous week',
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
            if (!filter.isCurrent) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: notifier.resetToCurrentWeek,
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
                    'This Week',
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
          onPressed: notifier.nextWeek,
          icon: const Icon(Icons.chevron_right_rounded),
          tooltip: 'Next week',
        ),
      ],
    );
  }

  Widget _buildCustomNavigation(
    BuildContext context,
    DateRangeFilter filter,
    ReportsFilterNotifier notifier,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    final now = DateTime.now();
    return Column(
      children: [
        OutlinedButton.icon(
          onPressed: () => _pickCustomDateRange(context, filter, notifier),
          icon: const Icon(Icons.edit_calendar_rounded, size: 18),
          label: Text(
            filter.label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilterChip(
                label: const Text('Last 7 Days'),
                selected: filter.label == 'Last 7 Days',
                onSelected: (_) {
                  notifier.setCustom(
                    now.subtract(const Duration(days: 6)),
                    now,
                    'Last 7 Days',
                  );
                },
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Last 30 Days'),
                selected: filter.label == 'Last 30 Days',
                onSelected: (_) {
                  notifier.setCustom(
                    now.subtract(const Duration(days: 29)),
                    now,
                    'Last 30 Days',
                  );
                },
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: Text('This Year (${now.year})'),
                selected: filter.label == 'This Year (${now.year})',
                onSelected: (_) {
                  notifier.setCustom(
                    DateTime(now.year, 1, 1),
                    DateTime(now.year, 12, 31),
                    'This Year (${now.year})',
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickCustomDateRange(
    BuildContext context,
    DateRangeFilter filter,
    ReportsFilterNotifier notifier,
  ) async {
    final now = DateTime.now();
    final initialRange = filter.type == DateRangeType.custom
        ? DateTimeRange(
            start: filter.startDate.toLocal(),
            end: filter.endDate.toLocal(),
          )
        : DateTimeRange(
            start: now.subtract(const Duration(days: 29)),
            end: now,
          );

    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: initialRange,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035, 12, 31),
      helpText: 'Select Date Range',
      saveText: 'Apply',
    );

    if (picked != null) {
      notifier.setCustom(picked.start, picked.end);
    }
  }
}
