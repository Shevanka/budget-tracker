import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Formatter and parser utilities for Indonesian Rupiah (IDR).
/// Follows the rule: Money is strictly an integer representing whole rupiah.
abstract final class CurrencyFormatter {
  static final NumberFormat _numberFormat = NumberFormat('#,##0', 'id_ID');

  /// Formats an integer [amount] to Indonesian Rupiah.
  /// Example: `50000` -> `Rp 50.000` (or `50.000` if [includeSymbol] is false).
  static String format(int amount, {bool includeSymbol = true}) {
    final formatted = _numberFormat.format(amount.abs());
    final isNegative = amount < 0;

    if (includeSymbol) {
      return isNegative ? '-Rp $formatted' : 'Rp $formatted';
    }
    return isNegative ? '-$formatted' : formatted;
  }

  /// Formats an integer [amount] compactly for charts and compact UI badges.
  /// Examples:
  /// - `500` -> `Rp 500`
  /// - `50000` -> `Rp 50 rb`
  /// - `1500000` -> `Rp 1,5 jt`
  /// - `2000000000` -> `Rp 2 M`
  static String formatCompact(int amount, {bool includeSymbol = true}) {
    final absAmount = amount.abs();
    final isNegative = amount < 0;
    final prefix = isNegative ? '-Rp ' : 'Rp ';
    final plainPrefix = isNegative ? '-' : '';

    String valueStr;
    if (absAmount >= 1000000000) {
      valueStr = '${_formatCompactNumber(absAmount / 1000000000)} M';
    } else if (absAmount >= 1000000) {
      valueStr = '${_formatCompactNumber(absAmount / 1000000)} jt';
    } else if (absAmount >= 1000) {
      valueStr = '${_formatCompactNumber(absAmount / 1000)} rb';
    } else {
      valueStr = absAmount.toString();
    }

    return includeSymbol ? '$prefix$valueStr' : '$plainPrefix$valueStr';
  }

  static String _formatCompactNumber(double value) {
    if (value % 1 == 0) {
      return value.toInt().toString();
    }
    // Round to 1 decimal place with comma separator
    final fixed = value.toStringAsFixed(1);
    return fixed.replaceAll('.', ',');
  }

  /// Parses a string representation of IDR into an integer.
  /// Strips currency symbols, dots, commas, and whitespace.
  /// Returns `null` if the input contains no valid digits.
  static int? tryParse(String? input) {
    if (input == null || input.trim().isEmpty) {
      return null;
    }

    final trimmed = input.trim();
    final isNegative = trimmed.startsWith('-');
    final digits = trimmed.replaceAll(RegExp(r'[^\d]'), '');

    if (digits.isEmpty) {
      return null;
    }

    final value = int.tryParse(digits);
    if (value == null) {
      return null;
    }

    return isNegative ? -value : value;
  }

  /// Parses a string representation into an integer, falling back to [defaultValue].
  static int parse(String input, {int defaultValue = 0}) {
    return tryParse(input) ?? defaultValue;
  }

  /// Validates whether [input] represents a valid positive amount (> 0).
  static bool isValidAmount(String? input) {
    final parsed = tryParse(input);
    return parsed != null && parsed > 0;
  }
}

/// A [TextInputFormatter] that formats numeric inputs with Indonesian thousand separators as the user types.
class CurrencyInputFormatter extends TextInputFormatter {
  const CurrencyInputFormatter({this.maxDigits = 12});

  final int maxDigits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final cleanDigits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanDigits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final truncated = cleanDigits.length > maxDigits
        ? cleanDigits.substring(0, maxDigits)
        : cleanDigits;

    final parsed = int.tryParse(truncated);
    if (parsed == null) {
      return oldValue;
    }

    final formatted = CurrencyFormatter.format(parsed, includeSymbol: false);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Convenience extension on [int] for IDR formatting.
extension CurrencyIntX on int {
  /// Formats the integer as IDR with standard "Rp " prefix.
  String toIdr({bool includeSymbol = true}) {
    return CurrencyFormatter.format(this, includeSymbol: includeSymbol);
  }

  /// Formats the integer compactly (e.g. "Rp 1,5 jt", "Rp 50 rb").
  String toCompactIdr({bool includeSymbol = true}) {
    return CurrencyFormatter.formatCompact(this, includeSymbol: includeSymbol);
  }
}
