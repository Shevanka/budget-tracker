import '../../../database/converters/transaction_type.dart';

/// Rule defining pattern matching and group capture indices for an institution's notifications.
class NotificationParserRule {
  /// Name of the bank or e-wallet source (e.g., 'BCA', 'Mandiri', 'ShopeePay').
  final String source;

  /// Application package names that typically send this notification.
  final List<String> packageNames;

  /// Regular expression to match transaction details in the notification text.
  final RegExp regex;

  /// 1-based index of the regex capture group containing the amount string.
  final int amountGroupIndex;

  /// 1-based index of the regex capture group containing the merchant/destination name.
  final int merchantGroupIndex;

  /// Default transaction type detected by this rule (typically [TransactionType.expense]).
  final TransactionType defaultType;

  const NotificationParserRule({
    required this.source,
    required this.packageNames,
    required this.regex,
    required this.amountGroupIndex,
    required this.merchantGroupIndex,
    this.defaultType = TransactionType.expense,
  });

  /// Checks whether [packageName] belongs to this rule.
  bool matchesPackage(String? packageName) {
    if (packageName == null || packageName.isEmpty) return false;
    final clean = packageName.trim().toLowerCase();
    return packageNames.any((p) => p.toLowerCase() == clean);
  }
}
