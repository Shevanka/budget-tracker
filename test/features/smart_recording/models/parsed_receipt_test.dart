import 'package:budget_tracker/core/constants/default_categories.dart';
import 'package:budget_tracker/database/converters/transaction_type.dart';
import 'package:budget_tracker/features/smart_recording/models/parsed_receipt.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ParsedReceipt Model', () {
    final testDate = DateTime.utc(2026, 11, 1, 12, 0);

    test('initializes with expected fields and calculates isRecognized', () {
      final receipt = ParsedReceipt(
        merchant: 'INDOMARET',
        amount: 45000,
        date: testDate,
        suggestedCategoryId: DefaultCategories.shoppingId,
        suggestedCategoryName: DefaultCategories.shoppingName,
        rawText: 'INDOMARET\nTOTAL Rp 45.000',
        imagePath: '/path/to/img.jpg',
        lines: const ['INDOMARET', 'TOTAL Rp 45.000'],
      );

      expect(receipt.merchant, equals('INDOMARET'));
      expect(receipt.amount, equals(45000));
      expect(receipt.date, equals(testDate));
      expect(receipt.suggestedCategoryId, equals(DefaultCategories.shoppingId));
      expect(receipt.suggestedCategoryName, equals(DefaultCategories.shoppingName));
      expect(receipt.formattedAmount, equals('Rp 45.000'));
      expect(receipt.isRecognized, isTrue);
    });

    test('isRecognized is false when amount is null or zero', () {
      const receiptNoAmount = ParsedReceipt(
        merchant: 'ALFAMART',
        amount: null,
        rawText: 'ALFAMART',
        imagePath: '/img.jpg',
      );
      expect(receiptNoAmount.isRecognized, isFalse);
      expect(receiptNoAmount.formattedAmount, equals('-'));

      const receiptZeroAmount = ParsedReceipt(
        merchant: 'ALFAMART',
        amount: 0,
        rawText: 'ALFAMART',
        imagePath: '/img.jpg',
      );
      expect(receiptZeroAmount.isRecognized, isFalse);
    });

    test('isRecognized is false when merchant is null or whitespace', () {
      const receiptNoMerchant = ParsedReceipt(
        merchant: '   ',
        amount: 50000,
        rawText: 'TOTAL 50000',
        imagePath: '/img.jpg',
      );
      expect(receiptNoMerchant.isRecognized, isFalse);
    });

    test('toTransactionCompanion converts properly into Drift companion', () {
      final receipt = ParsedReceipt(
        merchant: 'KOPI KENANGAN',
        amount: 28000,
        date: testDate,
        suggestedCategoryId: DefaultCategories.foodId,
        rawText: 'KOPI KENANGAN',
        imagePath: '/img.jpg',
      );

      final companion = receipt.toTransactionCompanion(id: 'tx-rcpt-1');
      expect(companion.id.value, equals('tx-rcpt-1'));
      expect(companion.amount.value, equals(28000));
      expect(companion.type.value, equals(TransactionType.expense));
      expect(companion.categoryId.value, equals(DefaultCategories.foodId));
      expect(companion.source.value, equals('receipt'));
      expect(companion.note.value, equals('KOPI KENANGAN'));
      expect(companion.date.value, equals(testDate));
    });

    test('copyWith updates specified fields and equality works', () {
      const r1 = ParsedReceipt(
        merchant: 'MCDONALD',
        amount: 60000,
        rawText: 'raw',
        imagePath: '/img.jpg',
      );
      final r2 = r1.copyWith();
      final r3 = r1.copyWith(amount: 75000);

      expect(r1, equals(r2));
      expect(r1.hashCode, equals(r2.hashCode));
      expect(r1, isNot(equals(r3)));
      expect(r3.amount, equals(75000));
    });
  });
}
