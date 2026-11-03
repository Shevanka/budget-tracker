import 'package:budget_tracker/core/constants/default_categories.dart';
import 'package:budget_tracker/database/converters/transaction_type.dart';
import 'package:budget_tracker/features/notification_watcher/models/parsed_notification.dart';
import 'package:budget_tracker/features/notification_watcher/providers/notification_watcher_provider.dart';
import 'package:budget_tracker/features/notification_watcher/services/notification_parser.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = NotificationParser();
  final testDate = DateTime.utc(2026, 10, 30, 10, 0);

  group('NotificationParser - Indonesian Banks & E-Wallets (Phase 8.2)', () {
    group('1. BCA (Bank Central Asia)', () {
      test('parses BCA debit purchase with comma cents and account suffix', () {
        const body = 'Pembelian di INDOMARET Rp 45.000,00 di rek *1234';
        final result = parser.parse(
          body: body,
          appPackage: 'com.bca',
          timestamp: testDate,
        );

        expect(result, isNotNull);
        expect(result!.source, equals('BCA'));
        expect(result.amount, equals(45000));
        expect(result.merchant, equals('INDOMARET'));
        expect(result.type, equals(TransactionType.expense));
        expect(result.suggestedCategoryId, equals(DefaultCategories.shoppingId));
        expect(result.suggestedCategoryName, equals(DefaultCategories.shoppingName));
        expect(result.formattedAmount, equals('Rp 45.000'));
      });

      test('parses BCA QRIS payment', () {
        const body = 'Pembayaran QRIS di KOPI KENANGAN Rp 28.000 berhasil';
        final result = parser.parse(
          body: body,
          appPackage: 'com.bca.mybca',
          timestamp: testDate,
        );

        expect(result, isNotNull);
        expect(result!.source, equals('BCA'));
        expect(result.amount, equals(28000));
        expect(result.merchant, equals('KOPI KENANGAN'));
        expect(result.suggestedCategoryId, equals(DefaultCategories.foodId));
      });
    });

    group('2. Bank Mandiri (Livin\')', () {
      test('parses Mandiri QRIS payment', () {
        const body = 'Pembayaran QRIS sebesar Rp 35.000 di WARUNG KOPI berhasil.';
        final result = parser.parse(
          body: body,
          appPackage: 'id.co.bankmandiri.livin',
          timestamp: testDate,
        );

        expect(result, isNotNull);
        expect(result!.source, equals('Mandiri'));
        expect(result.amount, equals(35000));
        expect(result.merchant, equals('WARUNG KOPI'));
        expect(result.suggestedCategoryId, equals(DefaultCategories.foodId));
      });

      test('parses Mandiri debit transaction', () {
        const body = 'Transaksi debit sebesar Rp 120.000 di ALFAMART telah berhasil.';
        final result = parser.parse(
          body: body,
          appPackage: 'id.co.bankmandiri.livin',
          timestamp: testDate,
        );

        expect(result, isNotNull);
        expect(result!.source, equals('Mandiri'));
        expect(result.amount, equals(120000));
        expect(result.merchant, equals('ALFAMART'));
        expect(result.suggestedCategoryId, equals(DefaultCategories.shoppingId));
      });
    });

    group('3. BNI (Bank Negara Indonesia / wondr)', () {
      test('parses BNI QRIS transaction without "sebesar"', () {
        const body = 'Transaksi QRIS Rp 45.000 di KOPI JANJI JIWA berhasil';
        final result = parser.parse(
          body: body,
          appPackage: 'id.co.bni.mobilebanking',
          timestamp: testDate,
        );

        expect(result, isNotNull);
        expect(result!.source, equals('BNI'));
        expect(result.amount, equals(45000));
        expect(result.merchant, equals('KOPI JANJI JIWA'));
        expect(result.suggestedCategoryId, equals(DefaultCategories.foodId));
      });

      test('parses BNI purchase with trailing date timestamp', () {
        const body = 'Pembelian sebesar Rp 150.000 di INDOMARET pada 03/10/2026 berhasil';
        final result = parser.parse(
          body: body,
          appPackage: 'id.co.bni.wondr',
          timestamp: testDate,
        );

        expect(result, isNotNull);
        expect(result!.source, equals('BNI'));
        expect(result.amount, equals(150000));
        expect(result.merchant, equals('INDOMARET'));
        expect(result.suggestedCategoryId, equals(DefaultCategories.shoppingId));
      });
    });

    group('4. BTN (Bank Tabungan Negara)', () {
      test('parses BTN QRIS payment', () {
        const body = 'Transaksi QRIS sebesar Rp 32.500 di BAKSO RUSUK berhasil';
        final result = parser.parse(
          body: body,
          appPackage: 'id.co.btn.mobilebanking',
          timestamp: testDate,
        );

        expect(result, isNotNull);
        expect(result!.source, equals('BTN'));
        expect(result.amount, equals(32500));
        expect(result.merchant, equals('BAKSO RUSUK'));
        expect(result.suggestedCategoryId, equals(DefaultCategories.foodId));
      });

      test('parses BTN debit with account number prefix', () {
        const body = 'Debit rek 12345 sebesar Rp 85.000 di INDOMARET berhasil';
        final result = parser.parse(
          body: body,
          appPackage: 'id.co.btn.mobilebanking',
          timestamp: testDate,
        );

        expect(result, isNotNull);
        expect(result!.source, equals('BTN'));
        expect(result.amount, equals(85000));
        expect(result.merchant, equals('INDOMARET'));
        expect(result.suggestedCategoryId, equals(DefaultCategories.shoppingId));
      });
    });

    group('5. SeaBank', () {
      test('parses SeaBank QRIS payment with trailing dot', () {
        const body = 'Pembayaran QRIS sebesar Rp 25.000 ke POINT COFFEE berhasil.';
        final result = parser.parse(
          body: body,
          appPackage: 'com.seabank.id',
          timestamp: testDate,
        );

        expect(result, isNotNull);
        expect(result!.source, equals('SeaBank'));
        expect(result.amount, equals(25000));
        expect(result.merchant, equals('POINT COFFEE'));
        expect(result.suggestedCategoryId, equals(DefaultCategories.foodId));
      });

      test('parses SeaBank outgoing transfer to individual', () {
        const body = 'Transfer keluar sebesar Rp 100.000 ke ANGGIE WAHYU berhasil.';
        final result = parser.parse(
          body: body,
          appPackage: 'com.seabank.id',
          timestamp: testDate,
        );

        expect(result, isNotNull);
        expect(result!.source, equals('SeaBank'));
        expect(result.amount, equals(100000));
        expect(result.merchant, equals('ANGGIE WAHYU'));
        expect(result.suggestedCategoryId, isNull);
        expect(result.suggestedCategoryName, isNull);
      });
    });

    group('6. ShopeePay', () {
      test('parses ShopeePay QRIS payment with exclamation mark', () {
        const body = 'Pembayaran QRIS sebesar Rp 30.000 di JANJI JIWA berhasil!';
        final result = parser.parse(
          body: body,
          appPackage: 'com.shopee.id',
          timestamp: testDate,
        );

        expect(result, isNotNull);
        expect(result!.source, equals('ShopeePay'));
        expect(result.amount, equals(30000));
        expect(result.merchant, equals('JANJI JIWA'));
        expect(result.suggestedCategoryId, equals(DefaultCategories.foodId));
      });

      test('parses ShopeePay "Kamu berhasil membayar" pattern', () {
        const body = 'Kamu berhasil membayar Rp 75.000 ke Kopi Tuku.';
        final result = parser.parse(
          body: body,
          appPackage: 'com.shopeepay.id',
          timestamp: testDate,
        );

        expect(result, isNotNull);
        expect(result!.source, equals('ShopeePay'));
        expect(result.amount, equals(75000));
        expect(result.merchant, equals('Kopi Tuku'));
        expect(result.suggestedCategoryId, equals(DefaultCategories.foodId));
      });
    });

    group('7. GoPay', () {
      test('parses GoPay Gofood payment with hyphen merchant', () {
        const body = 'Kamu berhasil bayar Rp 38.000 ke Gofood - Ayam Geprek Bensu.';
        final result = parser.parse(
          body: body,
          appPackage: 'com.gojek.app',
          timestamp: testDate,
        );

        expect(result, isNotNull);
        expect(result!.source, equals('GoPay'));
        expect(result.amount, equals(38000));
        expect(result.merchant, equals('Gofood - Ayam Geprek Bensu'));
        expect(result.suggestedCategoryId, equals(DefaultCategories.foodId));
      });

      test('parses GoPay retail payment with "pakai GoPay" suffix', () {
        const body = 'Kamu telah membayar Rp 15.000 di ALFAMART pakai GoPay.';
        final result = parser.parse(
          body: body,
          appPackage: 'id.co.gopay',
          timestamp: testDate,
        );

        expect(result, isNotNull);
        expect(result!.source, equals('GoPay'));
        expect(result.amount, equals(15000));
        expect(result.merchant, equals('ALFAMART'));
        expect(result.suggestedCategoryId, equals(DefaultCategories.shoppingId));
      });
    });

    group('8. OVO', () {
      test('parses OVO payment with "Transaksi berhasil!" prefix', () {
        const body = 'Transaksi berhasil! Pembayaran sebesar Rp 45.000 di Chatime berhasil.';
        final result = parser.parse(
          body: body,
          appPackage: 'ovo.id',
          timestamp: testDate,
        );

        expect(result, isNotNull);
        expect(result!.source, equals('OVO'));
        expect(result.amount, equals(45000));
        expect(result.merchant, equals('Chatime'));
        expect(result.suggestedCategoryId, equals(DefaultCategories.foodId));
      });

      test('parses OVO short "Berhasil bayar" pattern', () {
        const body = 'Berhasil bayar Rp 20.000 di Kopi Kenangan.';
        final result = parser.parse(
          body: body,
          appPackage: 'ovo.id',
          timestamp: testDate,
        );

        expect(result, isNotNull);
        expect(result!.source, equals('OVO'));
        expect(result.amount, equals(20000));
        expect(result.merchant, equals('Kopi Kenangan'));
        expect(result.suggestedCategoryId, equals(DefaultCategories.foodId));
      });
    });

    group('9. DANA', () {
      test('parses DANA payment with "Kamu telah bayar" pattern', () {
        const body = 'Pembayaran berhasil! Kamu telah bayar Rp 35.000 ke Kopi Kenangan.';
        final result = parser.parse(
          body: body,
          appPackage: 'id.dana',
          timestamp: testDate,
        );

        expect(result, isNotNull);
        expect(result!.source, equals('DANA'));
        expect(result.amount, equals(35000));
        expect(result.merchant, equals('Kopi Kenangan'));
        expect(result.suggestedCategoryId, equals(DefaultCategories.foodId));
      });

      test('parses DANA bill payment to PLN', () {
        const body = 'Bayar Rp 50.000 ke PLN Prabayar berhasil.';
        final result = parser.parse(
          body: body,
          appPackage: 'id.dana',
          timestamp: testDate,
        );

        expect(result, isNotNull);
        expect(result!.source, equals('DANA'));
        expect(result.amount, equals(50000));
        expect(result.merchant, equals('PLN Prabayar'));
        expect(result.suggestedCategoryId, equals(DefaultCategories.billsId));
      });
    });

    group('Specification plan convenience method', () {
      test('parseNotification(body, appPackage) matches exact plan signature', () {
        const body = 'Pembelian di INDOMARET Rp 45.000,00 di rek *1234';
        final result = parser.parseNotification(body, 'com.bca');

        expect(result, isNotNull);
        expect(result!.amount, equals(45000));
        expect(result.source, equals('BCA'));
        expect(result.merchant, equals('INDOMARET'));
        expect(result.suggestedCategoryId, equals(DefaultCategories.shoppingId));
      });
    });

    group('Generic & Fallback Rules', () {
      test('parses generic transaction when package is not specified', () {
        const text = 'Transaksi sebesar Rp 75.000 di SOLARIA sukses';
        final result = parser.parse(body: text);

        expect(result, isNotNull);
        expect(result!.amount, equals(75000));
        expect(result.merchant, equals('SOLARIA'));
        expect(result.suggestedCategoryId, equals(DefaultCategories.foodId));
      });

      test('parses generic transaction when package is unknown app', () {
        const text = 'Pembayaran QRIS Rp 50.000 ke TOKO MAJU berhasil';
        final result = parser.parse(
          body: text,
          appPackage: 'com.unknown.bank',
        );

        expect(result, isNotNull);
        expect(result!.amount, equals(50000));
        expect(result.merchant, equals('TOKO MAJU'));
      });

      test('parses when details are split across title and body', () {
        final result = parser.parse(
          title: 'Pembayaran QRIS',
          body: 'sebesar Rp 25.000 ke POINT COFFEE berhasil.',
          appPackage: 'com.seabank.id',
        );

        expect(result, isNotNull);
        expect(result!.amount, equals(25000));
        expect(result.merchant, equals('POINT COFFEE'));
        expect(result.source, equals('SeaBank'));
      });
    });

    group('Negative and Non-Transaction Notifications', () {
      test('returns null for marketing / promotional notifications', () {
        final promos = [
          'Dapatkan cashback hingga 50% untuk transaksi hari ini!',
          'Promo Shopee 11.11 diskon besar-besaran untuk semua produk!',
          'Gunakan GoPay untuk hemat hingga Rp 20.000 minggu ini.',
          'Yuk top up saldo e-wallet kamu sekarang!',
          'Transfer antar bank gratis biaya admin hanya hari ini.',
        ];

        for (final promo in promos) {
          final result = parser.parse(body: promo, appPackage: 'com.gojek.app');
          expect(result, isNull, reason: 'Promotional text should not parse: "$promo"');
        }
      });

      test('returns null for empty or whitespace strings', () {
        expect(parser.parse(body: ''), isNull);
        expect(parser.parse(body: '   '), isNull);
        expect(parser.parse(body: '\n\t  '), isNull);
      });

      test('returns null for invalid amount values (e.g. Rp 0)', () {
        final result = parser.parse(
          body: 'Pembelian di WARUNG Rp 0 berhasil',
          appPackage: 'com.bca',
        );
        expect(result, isNull);
      });
    });

    group('ParsedNotification Model & Conversion', () {
      test('converts ParsedNotification to TransactionsCompanion accurately', () {
        final parsed = ParsedNotification(
          amount: 50000,
          merchant: 'Kopi Kenangan',
          source: 'BCA',
          type: TransactionType.expense,
          suggestedCategoryId: DefaultCategories.foodId,
          suggestedCategoryName: DefaultCategories.foodName,
          rawText: 'Pembayaran QRIS di Kopi Kenangan Rp 50.000 berhasil',
          appPackage: 'com.bca',
          timestamp: testDate,
        );

        final companion = parsed.toTransactionCompanion(id: 'tx-12345');
        expect(companion.id.value, equals('tx-12345'));
        expect(companion.amount.value, equals(50000));
        expect(companion.type.value, equals(TransactionType.expense));
        expect(companion.categoryId.value, equals(DefaultCategories.foodId));
        expect(companion.source.value, equals('BCA'));
        expect(companion.note.value, equals('Kopi Kenangan'));
        expect(companion.date.value, equals(testDate));
      });

      test('copyWith and value equality work as expected', () {
        final p1 = ParsedNotification(
          amount: 50000,
          merchant: 'Kopi Kenangan',
          source: 'BCA',
          rawText: 'text',
          timestamp: testDate,
        );
        final p2 = p1.copyWith();
        final p3 = p1.copyWith(amount: 60000);

        expect(p1, equals(p2));
        expect(p1.hashCode, equals(p2.hashCode));
        expect(p1, isNot(equals(p3)));
        expect(p1.note, equals('Kopi Kenangan'));
        expect(p1.formattedAmount, equals('Rp 50.000'));
      });
    });

    group('Riverpod Provider', () {
      test('notificationParserProvider resolves valid NotificationParser instance', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final parserInstance = container.read(notificationParserProvider);
        expect(parserInstance, isA<NotificationParser>());
      });
    });
  });
}
