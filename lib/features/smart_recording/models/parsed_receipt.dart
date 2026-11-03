import 'package:drift/drift.dart';

import '../../../core/constants/default_categories.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../database/app_database.dart';
import '../../../database/converters/transaction_type.dart';

/// Structured financial transaction data extracted from OCR text of a receipt.
class ParsedReceipt {
  /// The extracted merchant or store name (e.g. 'INDOMARET').
  final String? merchant;

  /// The extracted total amount in whole Rupiah (integer).
  final int? amount;

  /// The extracted transaction date (in UTC).
  final DateTime? date;

  /// The suggested category ID based on store/line items (e.g. foodId or shoppingId).
  final String? suggestedCategoryId;

  /// The human-readable suggested category name.
  final String? suggestedCategoryName;

  /// The raw OCR text scanned from the receipt.
  final String rawText;

  /// The local file path to the scanned receipt image.
  final String imagePath;

  /// The individual non-empty lines from the receipt.
  final List<String> lines;

  const ParsedReceipt({
    this.merchant,
    this.amount,
    this.date,
    this.suggestedCategoryId,
    this.suggestedCategoryName,
    required this.rawText,
    required this.imagePath,
    this.lines = const [],
  });

  /// Formatted amount string in Indonesian Rupiah (e.g. 'Rp 45.000') or '-' if not found.
  String get formattedAmount =>
      amount != null ? CurrencyFormatter.format(amount!) : '-';

  /// Whether the receipt parser successfully found both a valid positive amount and a merchant name.
  bool get isRecognized => (amount != null && amount! > 0) && (merchant != null && merchant!.trim().isNotEmpty);

  /// Converts this [ParsedReceipt] into a [TransactionsCompanion] ready for database insertion.
  TransactionsCompanion toTransactionCompanion({
    required String id,
    String? categoryIdOverride,
    String? noteOverride,
    DateTime? dateOverride,
    DateTime? createdAt,
  }) {
    final now = createdAt ?? DateTime.now().toUtc();
    return TransactionsCompanion(
      id: Value(id),
      amount: Value(amount ?? 0),
      type: const Value(TransactionType.expense),
      categoryId: Value(
        categoryIdOverride ?? suggestedCategoryId ?? DefaultCategories.otherId,
      ),
      date: Value((dateOverride ?? date ?? now).toUtc()),
      note: Value(noteOverride ?? merchant ?? 'Receipt Scan'),
      source: const Value('receipt'),
      createdAt: Value(now),
      updatedAt: const Value(null),
    );
  }

  /// Creates a copy of this [ParsedReceipt] with updated fields.
  ParsedReceipt copyWith({
    String? merchant,
    int? amount,
    DateTime? date,
    String? suggestedCategoryId,
    String? suggestedCategoryName,
    String? rawText,
    String? imagePath,
    List<String>? lines,
  }) {
    return ParsedReceipt(
      merchant: merchant ?? this.merchant,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      suggestedCategoryId: suggestedCategoryId ?? this.suggestedCategoryId,
      suggestedCategoryName:
          suggestedCategoryName ?? this.suggestedCategoryName,
      rawText: rawText ?? this.rawText,
      imagePath: imagePath ?? this.imagePath,
      lines: lines ?? this.lines,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParsedReceipt &&
          runtimeType == other.runtimeType &&
          merchant == other.merchant &&
          amount == other.amount &&
          date == other.date &&
          suggestedCategoryId == other.suggestedCategoryId &&
          rawText == other.rawText &&
          imagePath == other.imagePath;

  @override
  int get hashCode => Object.hash(
        merchant,
        amount,
        date,
        suggestedCategoryId,
        rawText,
        imagePath,
      );

  @override
  String toString() =>
      'ParsedReceipt(merchant: $merchant, amount: $amount, date: $date, category: $suggestedCategoryName)';
}
