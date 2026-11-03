import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_custom_colors.dart';
import '../../domain/models/budget_status.dart';

/// A reusable progress bar widget for budget consumption.
///
/// Automatically color-codes based on budget consumption threshold:
/// - **Safe** (<80%): [AppColors.budgetSafe] (Green)
/// - **Warning** (80%–99%): [AppColors.budgetWarning] (Amber/Orange)
/// - **Danger** (>=100%): [AppColors.budgetDanger] (Red)
class BudgetProgressBar extends StatelessWidget {
  /// The percentage of budget consumed (0 to 100+).
  final int percentage;

  /// Optional semantic status level. If omitted, will be inferred from [percentage].
  final BudgetStatusLevel? statusLevel;

  /// Height of the progress bar. Defaults to 8.0.
  final double height;

  /// Custom bar color. If omitted, the semantic color for [statusLevel] is used.
  final Color? color;

  /// Custom track background color. If omitted, defaults to surfaceContainerHighest.
  final Color? backgroundColor;

  /// Border radius of the bar. Defaults to 4.0 circular.
  final BorderRadiusGeometry borderRadius;

  /// Whether to animate value changes. Defaults to true.
  final bool animate;

  /// Animation duration when [animate] is true. Defaults to 400ms.
  final Duration animationDuration;

  /// Custom accessibility semantics label.
  final String? semanticsLabel;

  const BudgetProgressBar({
    super.key,
    required this.percentage,
    this.statusLevel,
    this.height = 8.0,
    this.color,
    this.backgroundColor,
    this.borderRadius = const BorderRadius.all(Radius.circular(4.0)),
    this.animate = true,
    this.animationDuration = const Duration(milliseconds: 400),
    this.semanticsLabel,
  });

  /// Factory constructor to build directly from [CategoryBudgetStatus].
  factory BudgetProgressBar.fromCategoryStatus({
    Key? key,
    required CategoryBudgetStatus status,
    double height = 8.0,
    bool animate = true,
    String? semanticsLabel,
  }) {
    return BudgetProgressBar(
      key: key,
      percentage: status.percentage,
      statusLevel: status.statusLevel,
      height: height,
      animate: animate,
      semanticsLabel: semanticsLabel ??
          '${status.category.name} budget progress: ${status.percentage}%, ${status.statusLevel.name}',
    );
  }

  /// Factory constructor to build directly from [MonthlyBudgetStatus].
  factory BudgetProgressBar.fromMonthlyStatus({
    Key? key,
    required MonthlyBudgetStatus status,
    double height = 12.0,
    bool animate = true,
    String? semanticsLabel,
  }) {
    return BudgetProgressBar(
      key: key,
      percentage: status.percentage,
      statusLevel: status.statusLevel,
      height: height,
      animate: animate,
      semanticsLabel: semanticsLabel ??
          'Monthly budget progress: ${status.percentage}%, ${status.statusLevel.name}',
    );
  }

  /// Infers the [BudgetStatusLevel] from [percentage] if not explicitly provided.
  BudgetStatusLevel get effectiveStatusLevel {
    if (statusLevel != null) return statusLevel!;
    if (percentage >= 100) return BudgetStatusLevel.danger;
    if (percentage >= 80) return BudgetStatusLevel.warning;
    return BudgetStatusLevel.safe;
  }

  /// Resolves the progress fill color based on status level and theme.
  Color resolveColor(BuildContext context) {
    if (color != null) return color!;
    final customColors = Theme.of(context).extension<AppCustomColors>();

    switch (effectiveStatusLevel) {
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
    final effectiveTrackColor = backgroundColor ??
        theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6);
    final effectiveProgressColor = resolveColor(context);

    // Clamp ratio between 0.0 and 1.0 for the progress bar visual width
    final targetRatio = (percentage / 100.0).clamp(0.0, 1.0);

    final String label = semanticsLabel ??
        'Budget progress: $percentage%, ${effectiveStatusLevel.name}';

    return Semantics(
      label: label,
      value: '$percentage%',
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: effectiveTrackColor,
            borderRadius: borderRadius,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;

              if (!animate) {
                return _buildFill(
                  width: totalWidth * targetRatio,
                  color: effectiveProgressColor,
                );
              }

              return TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: targetRatio),
                duration: animationDuration,
                curve: Curves.easeOutCubic,
                builder: (context, animatedRatio, _) {
                  return _buildFill(
                    width: totalWidth * animatedRatio,
                    color: effectiveProgressColor,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFill({required double width, required Color color}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}
