/// Represents the high-level monthly financial summary:
/// total income, total expense, and resulting net balance.
class MonthlyFinancialSummary {
  final String yearMonth;
  final int totalIncome;
  final int totalExpense;
  final int netBalance;
  final int transactionCount;

  const MonthlyFinancialSummary({
    required this.yearMonth,
    required this.totalIncome,
    required this.totalExpense,
    required this.netBalance,
    this.transactionCount = 0,
  });

  /// Pure factory constructor calculating net balance from income and expense.
  factory MonthlyFinancialSummary.calculate({
    required String yearMonth,
    required int totalIncome,
    required int totalExpense,
    int transactionCount = 0,
  }) {
    return MonthlyFinancialSummary(
      yearMonth: yearMonth,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      netBalance: totalIncome - totalExpense,
      transactionCount: transactionCount,
    );
  }

  /// Whether net balance is non-negative (income >= expense).
  bool get isPositiveOrZero => netBalance >= 0;

  /// Whether there has been any financial activity this month.
  bool get hasActivity => totalIncome > 0 || totalExpense > 0 || transactionCount > 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonthlyFinancialSummary &&
          runtimeType == other.runtimeType &&
          yearMonth == other.yearMonth &&
          totalIncome == other.totalIncome &&
          totalExpense == other.totalExpense &&
          netBalance == other.netBalance &&
          transactionCount == other.transactionCount;

  @override
  int get hashCode => Object.hash(
        yearMonth,
        totalIncome,
        totalExpense,
        netBalance,
        transactionCount,
      );

  @override
  String toString() =>
      'MonthlyFinancialSummary(yearMonth: $yearMonth, income: $totalIncome, expense: $totalExpense, balance: $netBalance, count: $transactionCount)';
}
