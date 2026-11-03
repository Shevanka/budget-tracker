import 'package:budget_tracker/features/smart_recording/models/receipt_scan_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReceiptScanResult Model', () {
    final timestamp = DateTime.utc(2026, 11, 1, 10, 0);

    test('instantiates with valid properties', () {
      final result = ReceiptScanResult(
        imagePath: '/path/to/receipt.jpg',
        rawText: 'INDOMARET\nTOTAL Rp 45.000',
        lines: const ['INDOMARET', 'TOTAL Rp 45.000'],
        timestamp: timestamp,
      );

      expect(result.imagePath, equals('/path/to/receipt.jpg'));
      expect(result.rawText, equals('INDOMARET\nTOTAL Rp 45.000'));
      expect(result.lines.length, equals(2));
      expect(result.lineCount, equals(2));
      expect(result.hasText, isTrue);
      expect(result.timestamp, equals(timestamp));
    });

    test('hasText is false when rawText is empty or whitespace', () {
      final emptyResult = ReceiptScanResult(
        imagePath: '/path/to/empty.jpg',
        rawText: '   \n  \t ',
        lines: const [],
        timestamp: timestamp,
      );

      expect(emptyResult.hasText, isFalse);
      expect(emptyResult.lineCount, equals(0));
    });

    test('implements value equality and hashCode', () {
      final r1 = ReceiptScanResult(
        imagePath: '/path/to/receipt.jpg',
        rawText: 'Text',
        lines: const ['Text'],
        timestamp: timestamp,
      );
      final r2 = ReceiptScanResult(
        imagePath: '/path/to/receipt.jpg',
        rawText: 'Text',
        lines: const ['Text'],
        timestamp: timestamp,
      );
      final r3 = ReceiptScanResult(
        imagePath: '/path/to/other.jpg',
        rawText: 'Text',
        lines: const ['Text'],
        timestamp: timestamp,
      );

      expect(r1, equals(r2));
      expect(r1.hashCode, equals(r2.hashCode));
      expect(r1, isNot(equals(r3)));
    });
  });
}
