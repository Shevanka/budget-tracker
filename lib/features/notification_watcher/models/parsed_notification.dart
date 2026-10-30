import 'package:drift/drift.dart';

import '../../../core/constants/default_categories.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../database/app_database.dart';
import '../../../database/converters/transaction_type.dart';

/// Represents a financial transaction parsed from an incoming system notification.
class ParsedNotification {
  /// The transaction amount in whole Indonesian Rupiah (strictly positive).
  final int amount;

  /// Merchant, recipient, or destination extracted from the notification.
  final String merchant;

  /// Type of transaction (defaults to [TransactionType.expense]).
  final TransactionType type;

  /// The source institution or app (e.g. 'BCA', 'Mandiri', 'ShopeePay').
  final String source;

  /// Suggested category identifier based on keyword heuristics.
  final String? suggestedCategoryId;

  /// Suggested category name for display.
  final String? suggestedCategoryName;

  /// Raw text of the notification that matched the rule.
  final String rawText;

  /// Android package name of the app that posted the notification.
  final String? appPackage;

  /// Timestamp when the notification was received or parsed.
  final DateTime timestamp;

  const ParsedNotification({
    required this.amount,
    required this.merchant,
    this.type = TransactionType.expense,
    required this.source,
    this.suggestedCategoryId,
    this.suggestedCategoryName,
    required this.rawText,
    this.appPackage,
    required this.timestamp,
  });

  /// Alias for [merchant] when used as the transaction's note.
  String get note => merchant;

  /// Formatted IDR string representation of [amount] (e.g. 'Rp 50.000').
  String get formattedAmount => CurrencyFormatter.format(amount);

  /// Converts this parsed notification into a Drift [TransactionsCompanion] draft.
  TransactionsCompanion toTransactionCompanion({
    required String id,
    DateTime? createdAt,
  }) {
    final now = createdAt ?? DateTime.now().toUtc();
    return TransactionsCompanion(
      id: Value(id),
      amount: Value(amount),
      type: Value(type),
      categoryId: Value(suggestedCategoryId ?? DefaultCategories.otherId),
      source: Value(source),
      date: Value(timestamp.toUtc()),
      note: Value(merchant),
      createdAt: Value(now),
      updatedAt: const Value(null),
    );
  }

  ParsedNotification copyWith({
    int? amount,
    String? merchant,
    TransactionType? type,
    String? source,
    String? suggestedCategoryId,
    String? suggestedCategoryName,
    String? rawText,
    String? appPackage,
    DateTime? timestamp,
  }) {
    return ParsedNotification(
      amount: amount ?? this.amount,
      merchant: merchant ?? this.merchant,
      type: type ?? this.type,
      source: source ?? this.source,
      suggestedCategoryId: suggestedCategoryId ?? this.suggestedCategoryId,
      suggestedCategoryName:
          suggestedCategoryName ?? this.suggestedCategoryName,
      rawText: rawText ?? this.rawText,
      appPackage: appPackage ?? this.appPackage,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParsedNotification &&
          runtimeType == other.runtimeType &&
          amount == other.amount &&
          merchant == other.merchant &&
          type == other.type &&
          source == other.source &&
          suggestedCategoryId == other.suggestedCategoryId &&
          suggestedCategoryName == other.suggestedCategoryName &&
          rawText == other.rawText &&
          appPackage == other.appPackage &&
          timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(
        amount,
        merchant,
        type,
        source,
        suggestedCategoryId,
        suggestedCategoryName,
        rawText,
        appPackage,
        timestamp,
      );

  @override
  String toString() =>
      'ParsedNotification(source: $source, amount: $formattedAmount, merchant: "$merchant", category: $suggestedCategoryName)';
}
