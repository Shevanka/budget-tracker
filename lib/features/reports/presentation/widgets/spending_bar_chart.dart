import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../domain/models/spending_over_time.dart';

/// An interactive Material 3 bar chart displaying daily or weekly spending over time.
class SpendingBarChart extends StatelessWidget {
  final SpendingOverTimeReport report;

  const SpendingBarChart({
    super.key,
    required this.report,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isWeekView = report.items.length <= 7;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.bar_chart_rounded,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Spending Over Time',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (report.hasData)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Avg ${report.averageDailyExpense.toCompactIdr()}/d',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Peak Day Subtitle if available
            if (report.hasData && report.highestSpendingDay != null) ...[
              Text(
                'Peak: ${report.highestSpendingDay!.formattedDate} (${report.highestSpendingDay!.amount.toIdr()})',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
            ] else
              const SizedBox(height: 12),

            // Bar Chart Area
            if (report.isEmpty)
              _buildEmptyState(theme, colorScheme)
            else
              SizedBox(
                height: 200,
                child: BarChart(
                  _buildChartData(theme, colorScheme, isWeekView),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      height: 160,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bar_chart_outlined,
            size: 36,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'No spending recorded',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Transactions will appear here as daily bars',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  BarChartData _buildChartData(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isWeekView,
  ) {
    final maxExpense = report.maxDailyExpense;
    final maxY = maxExpense > 0 ? maxExpense * 1.2 : 100000.0;
    final barWidth = isWeekView ? 20.0 : (report.items.length > 20 ? 6.0 : 10.0);

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: maxY,
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => colorScheme.inverseSurface,
          tooltipBorderRadius: BorderRadius.circular(10),
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final item = report.items[group.x];
            return BarTooltipItem(
              '${item.formattedDate}\n',
              TextStyle(
                color: colorScheme.onInverseSurface,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              children: [
                TextSpan(
                  text: item.amount.toIdr(),
                  style: TextStyle(
                    color: colorScheme.onInverseSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            );
          },
        ),
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= report.items.length) {
                return const SizedBox.shrink();
              }
              final item = report.items[index];

              // In week view, show day name ('Mon', 'Tue', ...)
              if (isWeekView) {
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    item.dayOfWeek,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                );
              }

              // In month view, show day of month for intervals
              final day = item.date.day;
              final isFirst = index == 0;
              final isLast = index == report.items.length - 1;
              final isInterval = day % 5 == 0;

              if (!isFirst && !isLast && !isInterval) {
                return const SizedBox.shrink();
              }

              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '$day',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) => FlLine(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          strokeWidth: 1,
          dashArray: [4, 4],
        ),
      ),
      borderData: FlBorderData(show: false),
      barGroups: List.generate(report.items.length, (index) {
        final item = report.items[index];
        final isHighest = item == report.highestSpendingDay && item.amount > 0;

        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: item.amount.toDouble(),
              color: isHighest
                  ? colorScheme.error
                  : (item.amount > 0
                      ? colorScheme.primary
                      : Colors.transparent),
              width: barWidth,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxY,
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              ),
            ),
          ],
        );
      }),
    );
  }
}
