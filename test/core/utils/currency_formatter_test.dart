import 'package:budget_tracker/core/utils/utils.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CurrencyFormatter.format', () {
    test('formats zero and positive IDR values with symbol', () {
      expect(CurrencyFormatter.format(0), equals('Rp 0'));
      expect(CurrencyFormatter.format(500), equals('Rp 500'));
      expect(CurrencyFormatter.format(50000), equals('Rp 50.000'));
      expect(CurrencyFormatter.format(1500000), equals('Rp 1.500.000'));
      expect(CurrencyFormatter.format(1000000000), equals('Rp 1.000.000.000'));
    });

    test('formats without symbol when includeSymbol is false', () {
      expect(CurrencyFormatter.format(0, includeSymbol: false), equals('0'));
      expect(CurrencyFormatter.format(50000, includeSymbol: false), equals('50.000'));
      expect(CurrencyFormatter.format(1500000, includeSymbol: false), equals('1.500.000'));
    });

    test('formats negative amounts correctly', () {
      expect(CurrencyFormatter.format(-50000), equals('-Rp 50.000'));
      expect(CurrencyFormatter.format(-50000, includeSymbol: false), equals('-50.000'));
    });
  });

  group('CurrencyFormatter.formatCompact', () {
    test('formats thousands, millions, and billions compactly', () {
      expect(CurrencyFormatter.formatCompact(500), equals('Rp 500'));
      expect(CurrencyFormatter.formatCompact(50000), equals('Rp 50 rb'));
      expect(CurrencyFormatter.formatCompact(1500000), equals('Rp 1,5 jt'));
      expect(CurrencyFormatter.formatCompact(2000000), equals('Rp 2 jt'));
      expect(CurrencyFormatter.formatCompact(2500000000), equals('Rp 2,5 M'));
    });

    test('formats compact without symbol', () {
      expect(CurrencyFormatter.formatCompact(50000, includeSymbol: false), equals('50 rb'));
      expect(CurrencyFormatter.formatCompact(1500000, includeSymbol: false), equals('1,5 jt'));
      expect(CurrencyFormatter.formatCompact(2500000000, includeSymbol: false), equals('2,5 M'));
    });

    test('formats negative compact amounts', () {
      expect(CurrencyFormatter.formatCompact(-1500000), equals('-Rp 1,5 jt'));
      expect(CurrencyFormatter.formatCompact(-1500000, includeSymbol: false), equals('-1,5 jt'));
    });
  });

  group('CurrencyFormatter.parse and tryParse', () {
    test('parses various formatted and unformatted strings to integer', () {
      expect(CurrencyFormatter.tryParse('Rp 50.000'), equals(50000));
      expect(CurrencyFormatter.tryParse('50.000'), equals(50000));
      expect(CurrencyFormatter.tryParse('50,000'), equals(50000));
      expect(CurrencyFormatter.tryParse('1.500.000'), equals(1500000));
      expect(CurrencyFormatter.tryParse('Rp 1.500.000'), equals(1500000));
      expect(CurrencyFormatter.tryParse('-Rp 50.000'), equals(-50000));
      expect(CurrencyFormatter.tryParse('Pembelian di RESTO SEDAP Rp 45.000'), equals(45000));
    });

    test('returns null / default for non-numeric inputs', () {
      expect(CurrencyFormatter.tryParse(null), isNull);
      expect(CurrencyFormatter.tryParse(''), isNull);
      expect(CurrencyFormatter.tryParse('   '), isNull);
      expect(CurrencyFormatter.tryParse('non-numeric string'), isNull);
      expect(CurrencyFormatter.parse('invalid', defaultValue: 100), equals(100));
    });

    test('isValidAmount validates positive integers only', () {
      expect(CurrencyFormatter.isValidAmount('50.000'), isTrue);
      expect(CurrencyFormatter.isValidAmount('Rp 100'), isTrue);
      expect(CurrencyFormatter.isValidAmount('0'), isFalse);
      expect(CurrencyFormatter.isValidAmount('-50.000'), isFalse);
      expect(CurrencyFormatter.isValidAmount(null), isFalse);
      expect(CurrencyFormatter.isValidAmount(''), isFalse);
    });
  });

  group('CurrencyInputFormatter', () {
    const formatter = CurrencyInputFormatter();

    test('formats text with dots while typing', () {
      final update1 = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: '5',
          selection: TextSelection.collapsed(offset: 1),
        ),
      );
      expect(update1.text, equals('5'));

      final update2 = formatter.formatEditUpdate(
        update1,
        const TextEditingValue(
          text: '5000',
          selection: TextSelection.collapsed(offset: 4),
        ),
      );
      expect(update2.text, equals('5.000'));
      expect(update2.selection.baseOffset, equals(5));

      final update3 = formatter.formatEditUpdate(
        update2,
        const TextEditingValue(
          text: '5.00000',
          selection: TextSelection.collapsed(offset: 7),
        ),
      );
      expect(update3.text, equals('500.000'));
    });

    test('handles empty and non-numeric input gracefully', () {
      final emptyUpdate = formatter.formatEditUpdate(
        const TextEditingValue(text: '5.000'),
        TextEditingValue.empty,
      );
      expect(emptyUpdate.text, isEmpty);

      final nonNumeric = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: 'abc',
          selection: TextSelection.collapsed(offset: 3),
        ),
      );
      expect(nonNumeric.text, isEmpty);
    });
  });

  group('CurrencyIntX extension', () {
    test('toIdr formats correctly', () {
      expect(50000.toIdr(), equals('Rp 50.000'));
      expect(50000.toIdr(includeSymbol: false), equals('50.000'));
    });

    test('toCompactIdr formats correctly', () {
      expect(1500000.toCompactIdr(), equals('Rp 1,5 jt'));
      expect(2000000000.toCompactIdr(), equals('Rp 2 M'));
    });
  });
}
