import 'package:flutter_test/flutter_test.dart';
import 'package:budget_tracker/features/smart_recording/constants/receipt_dataset.dart';
import 'package:budget_tracker/features/smart_recording/services/receipt_parser.dart';

void main() {
  group('ReceiptDataset & Taxonomy Tests', () {
    test('resolves corporate legal entities to consumer brands', () {
      expect(
        ReceiptDataset.resolveMerchant('PT INDOMARCO PRISMATAMA'),
        equals('Indomaret'),
      );
      expect(
        ReceiptDataset.resolveMerchant('PT SUMBER ALFARIA TRIJAYA TBK'),
        equals('Alfamart'),
      );
      expect(
        ReceiptDataset.resolveMerchant('PT FAST FOOD INDONESIA'),
        equals('KFC'),
      );
      expect(
        ReceiptDataset.resolveMerchant('PT BUMI BERKAH BOGA'),
        equals('Kopi Kenangan'),
      );
      expect(
        ReceiptDataset.resolveMerchant('PT LION SUPER INDO'),
        equals('Super Indo'),
      );
    });

    test('resolves known consumer brand names directly', () {
      expect(
        ReceiptDataset.resolveMerchant('ALFAMART KELAPA GADING 2'),
        equals('Alfamart'),
      );
      expect(
        ReceiptDataset.resolveMerchant('INDOMARET RAYA DARMO'),
        equals('Indomaret'),
      );
      expect(
        ReceiptDataset.resolveMerchant('STARBUCKS GRAND INDONESIA'),
        equals('Starbucks'),
      );
      expect(
        ReceiptDataset.resolveMerchant('KOPI KENANGAN SENAYAN CITY'),
        equals('Kopi Kenangan'),
      );
      expect(
        ReceiptDataset.resolveMerchant('SPBU PERTAMINA 31.12345'),
        equals('Pertamina'),
      );
    });

    test('classifies summary and grand total keywords', () {
      for (final kw in ReceiptDataset.grandTotalKeywords) {
        expect(const ReceiptParser().isSummaryLine(kw), isTrue);
      }
      for (final kw in ReceiptDataset.discountKeywords) {
        expect(const ReceiptParser().isSummaryLine(kw), isTrue);
      }
      for (final kw in ReceiptDataset.taxAndFeeKeywords) {
        expect(const ReceiptParser().isSummaryLine(kw), isTrue);
      }
    });

    test('parses two-line item format (name on line i, price on line i+1)', () {
      const parser = ReceiptParser();
      final lines = [
        'INDOMARET',
        'CHITATO BBQ 68GR',
        '11.200',
        'ULTRA MILK COKLAT 1L',
        '21.900',
        'TOTAL 33.100',
        'TUNAI 50.000',
        'KEMBALI 16.900',
      ];

      final items = parser.extractItems(lines);
      expect(items.length, equals(2));
      expect(items[0].name, equals('CHITATO BBQ 68GR'));
      expect(items[0].totalPrice, equals(11200));
      expect(items[1].name, equals('ULTRA MILK COKLAT 1L'));
      expect(items[1].totalPrice, equals(21900));

      final total = parser.extractTotalAmount(lines);
      expect(total, equals(33100));
    });

    test('extracts items using two-column layout fallback heuristic', () {
      const parser = ReceiptParser();
      final lines = [
        'ALFAMART',
        'AQUA 600ML',
        'INDOMILK UHT 950ML',
        'ROTI TAWAR',
        '3.500',
        '19.500',
        '15.000',
        'TOTAL 38.000',
      ];

      final items = parser.extractItems(lines);
      expect(items.length, equals(3));
      expect(items[0].name, equals('AQUA 600ML'));
      expect(items[0].totalPrice, equals(3500));
      expect(items[1].name, equals('INDOMILK UHT 950ML'));
      expect(items[1].totalPrice, equals(19500));
      expect(items[2].name, equals('ROTI TAWAR'));
      expect(items[2].totalPrice, equals(15000));
    });
  });
}
