import 'package:flutter/material.dart';

/// Custom theme extension for financial and budget status colors.
@immutable
class AppCustomColors extends ThemeExtension<AppCustomColors> {
  const AppCustomColors({
    required this.income,
    required this.expense,
    required this.budgetSafe,
    required this.budgetWarning,
    required this.budgetDanger,
  });

  final Color income;
  final Color expense;
  final Color budgetSafe;
  final Color budgetWarning;
  final Color budgetDanger;

  @override
  AppCustomColors copyWith({
    Color? income,
    Color? expense,
    Color? budgetSafe,
    Color? budgetWarning,
    Color? budgetDanger,
  }) {
    return AppCustomColors(
      income: income ?? this.income,
      expense: expense ?? this.expense,
      budgetSafe: budgetSafe ?? this.budgetSafe,
      budgetWarning: budgetWarning ?? this.budgetWarning,
      budgetDanger: budgetDanger ?? this.budgetDanger,
    );
  }

  @override
  AppCustomColors lerp(ThemeExtension<AppCustomColors>? other, double t) {
    if (other is! AppCustomColors) {
      return this;
    }
    return AppCustomColors(
      income: Color.lerp(income, other.income, t) ?? income,
      expense: Color.lerp(expense, other.expense, t) ?? expense,
      budgetSafe: Color.lerp(budgetSafe, other.budgetSafe, t) ?? budgetSafe,
      budgetWarning:
          Color.lerp(budgetWarning, other.budgetWarning, t) ?? budgetWarning,
      budgetDanger:
          Color.lerp(budgetDanger, other.budgetDanger, t) ?? budgetDanger,
    );
  }
}

/// Convenience extension on [BuildContext] to access custom financial colors.
extension AppCustomColorsX on BuildContext {
  AppCustomColors get customColors {
    final colors = Theme.of(this).extension<AppCustomColors>();
    assert(colors != null, 'AppCustomColors not found in ThemeData.extensions');
    return colors!;
  }
}
