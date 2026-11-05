import '../../../core/utils/currency_formatter.dart';

/// Represents an individual item or line-entry detected on a scanned receipt.
class ReceiptItem {
  /// Name or description of the purchased item (e.g. 'Ultra Milk Coklat 250ml').
  final String name;

  /// Quantity purchased, if recognized (e.g. 2).
  final int? quantity;

  /// Unit price in whole Rupiah, if recognized.
  final int? unitPrice;

  /// Total price for this line item in whole Rupiah.
  final int totalPrice;

  const ReceiptItem({
    required this.name,
    this.quantity,
    this.unitPrice,
    required this.totalPrice,
  });

  /// Formatted total price string (e.g. 'Rp 15.000').
  String get formattedTotalPrice => CurrencyFormatter.format(totalPrice);

  /// Converts this [ReceiptItem] to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'totalPrice': totalPrice,
      };

  /// Creates a [ReceiptItem] from a JSON map.
  factory ReceiptItem.fromJson(Map<String, dynamic> json) => ReceiptItem(
        name: json['name'] as String,
        quantity: json['quantity'] as int?,
        unitPrice: json['unitPrice'] as int?,
        totalPrice: json['totalPrice'] as int,
      );

  @override
  String toString() => '$name: ${CurrencyFormatter.format(totalPrice)}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReceiptItem &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          quantity == other.quantity &&
          unitPrice == other.unitPrice &&
          totalPrice == other.totalPrice;

  @override
  int get hashCode => Object.hash(name, quantity, unitPrice, totalPrice);
}
