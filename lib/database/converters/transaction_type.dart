/// Represents whether a transaction is income or an expense.
enum TransactionType {
  income,
  expense;

  String toValue() => name;

  static TransactionType fromValue(String value) {
    return TransactionType.values.firstWhere(
      (type) => type.name.toLowerCase() == value.toLowerCase(),
      orElse: () => TransactionType.expense,
    );
  }
}
