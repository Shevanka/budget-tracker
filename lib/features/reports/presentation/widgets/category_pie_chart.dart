import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/default_categories.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/models/category_spending.dart';

/// A Material 3 interactive donut pie chart displaying category spending breakdown.
class CategoryPieChart extends StatefulWidget {
  final CategorySpendingReport report;
  final CategorySpending? selectedCategory;
  final ValueChanged<CategorySpending?>? onCategorySelected;

  const CategoryPieChart({
    super.key,
    required this.report,
    this.selectedCategory,
    this.onCategorySelected,
  });

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart> {
  int? _touchedIndex;

  @override
  void initState() {
    super.initState();
    _syncSelectedIndex();
  }

  void _syncSelectedIndex() {
    if (widget.selectedCategory != null) {
      final idx = widget.report.items.indexOf(widget.selectedCategory!);
      _touchedIndex = idx >= 0 ? idx : null;
    } else {
      _touchedIndex = null;
    }
  }

  @override
  void didUpdateWidget(covariant CategoryPieChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedCategory != oldWidget.selectedCategory) {
      _syncSelectedIndex();
    } else if (widget.report != oldWidget.report) {
      if (_touchedIndex != null &&
          _touchedIndex! >= widget.report.items.length) {
        _touchedIndex = null;
      }
    }
  }

  void _handleSectionTap(int index) {
    setState(() {
      if (_touchedIndex == index) {
        _touchedIndex = null;
      } else {
        _touchedIndex = index;
      }
    });

    final selected = _touchedIndex != null &&
            _touchedIndex! >= 0 &&
            _touchedIndex! < widget.report.items.length
        ? widget.report.items[_touchedIndex!]
        : null;
    widget.onCategorySelected?.call(selected);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final report = widget.report;

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
            // Card Header
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
                        Icons.pie_chart_rounded,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Spending by Category',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (report.hasData)
                  Text(
                    '${report.items.length} ${report.items.length == 1 ? 'category' : 'categories'}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Donut Pie Chart Container
            SizedBox(
              height: 240,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            return;
                          }
                          final index = pieTouchResponse
                              .touchedSection!.touchedSectionIndex;
                          if (event is FlTapUpEvent && index >= 0) {
                            _handleSectionTap(index);
                          }
                        },
                      ),
                      startDegreeOffset: -90,
                      borderData: FlBorderData(show: false),
                      sectionsSpace: report.hasData ? 2.5 : 0,
                      centerSpaceRadius: 65,
                      sections: _buildSections(colorScheme),
                    ),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),

                  // Center Donut Hole Content
                  _buildCenterContent(theme, colorScheme),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Category Legend
            if (report.hasData) _buildLegend(theme, colorScheme),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildSections(ColorScheme colorScheme) {
    final report = widget.report;

    if (report.isEmpty) {
      return [
        PieChartSectionData(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
          value: 1,
          radius: 44,
          showTitle: false,
        ),
      ];
    }

    return List.generate(report.items.length, (index) {
      final item = report.items[index];
      final isSelected = index == _touchedIndex;
      final radius = isSelected ? 58.0 : 46.0;

      return PieChartSectionData(
        color: Color(item.category.color),
        value: item.amount.toDouble(),
        title: '${item.percentage.toStringAsFixed(0)}%',
        radius: radius,
        showTitle: false,
      );
    });
  }

  Widget _buildCenterContent(ThemeData theme, ColorScheme colorScheme) {
    final report = widget.report;

    if (report.isEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.savings_outlined,
            size: 28,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 4),
          Text(
            'No expenses',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    if (_touchedIndex != null &&
        _touchedIndex! >= 0 &&
        _touchedIndex! < report.items.length) {
      final selected = report.items[_touchedIndex!];
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            DefaultCategories.getIconData(selected.category.icon),
            size: 20,
            color: Color(selected.category.color),
          ),
          const SizedBox(height: 4),
          Text(
            selected.category.name,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            selected.amount.toIdr(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            '${selected.percentage.toStringAsFixed(1)}%',
            style: theme.textTheme.labelSmall?.copyWith(
              color: Color(selected.category.color),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }

    // Default center content: Total Spent
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Total Spent',
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          report.totalExpense.toCompactIdr(),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          report.totalExpense.toIdr(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(ThemeData theme, ColorScheme colorScheme) {
    final report = widget.report;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: List.generate(report.items.length, (index) {
        final item = report.items[index];
        final isSelected = index == _touchedIndex;

        return InkWell(
          onTap: () => _handleSectionTap(index),
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? Color(item.category.color).withValues(alpha: 0.15)
                  : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? Color(item.category.color)
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Color(item.category.color),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  item.category.name,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${item.percentage.toStringAsFixed(0)}%',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
